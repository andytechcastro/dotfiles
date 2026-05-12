/**
 * Engram — OpenCode plugin adapter
 *
 * Thin layer that connects OpenCode's event system to the Engram Go binary.
 * The Go binary runs as a local HTTP server and handles all persistence.
 *
 * Flow:
 *   OpenCode events → this plugin → HTTP calls → engram serve → SQLite
 *
 * Session resilience:
 *   Uses `ensureSession()` before any DB write. This means sessions are
 *   created on-demand — even if the plugin was loaded after the session
 *   started (restart, reconnect, etc.). The session ID comes from OpenCode's
 *   hooks (input.sessionID) rather than relying on a session.created event.
 */

import type { Plugin } from "@opencode-ai/plugin"

// ─── Configuration ───────────────────────────────────────────────────────────

const ENGRAM_PORT = parseInt(process.env.ENGRAM_PORT ?? "7437")
const ENGRAM_URL = `http://127.0.0.1:${ENGRAM_PORT}`
const ENGRAM_BIN = process.env.ENGRAM_BIN ?? Bun.which("engram") ?? "/usr/bin/engram"

// Engram's own MCP tools — don't count these as "tool calls" for session stats
const ENGRAM_TOOLS = new Set([
  "mem_search",
  "mem_save",
  "mem_update",
  "mem_delete",
  "mem_suggest_topic_key",
  "mem_save_prompt",
  "mem_session_summary",
  "mem_context",
  "mem_stats",
  "mem_timeline",
  "mem_get_observation",
  "mem_session_start",
  "mem_session_end",
])

// ─── Memory Instructions ─────────────────────────────────────────────────────
// These get injected into the agent's context so it knows to call mem_save.

const MEMORY_INSTRUCTIONS = `## Engram Persistent Memory — ASK-FIRST MODE

You have access to Engram, a persistent memory system that survives across sessions and compactions.

### RULE 1: PROPOSE, DON'T AUTO-SAVE
When you encounter something potentially valuable (architecture decisions,
non-obvious bug root causes, gotchas, patterns, config quirks), DO NOT call
mem_save directly. Instead, propose it to the user:

  "💡 I noticed something worth remembering: <brief description>. Save it?"

Only call mem_save AFTER the user approves.

Exception: If something is critical and obvious (a gotcha that just bit you),
you MAY propose it mid-work, but still wait for approval.

### RULE 2: SESSION END — BATCH REVIEW (MANDATORY)
Before ending a session or saying "done" / "listo" / "that's it", you MUST:
1. Review what was accomplished in the session
2. Present a numbered list of potential memories with [type] tags
3. Ask the user which ones to save (e.g., "1, 2, 3 / all / none / only 2")
4. Call mem_save ONLY for the approved items
5. Then call mem_session_summary with a concise recap

Format for mem_save:
- **title**: Verb + what — short, searchable
- **type**: decision | bugfix | gotcha | pattern | config | discovery
- **scope**: \`project\` (default) | \`personal\`
- **topic_key** (optional): stable key like \`architecture/auth-model\`
- **content**: What / Why / Where / Learned structure

Topic rules:
- Different topics must not overwrite each other
- Reuse the same \`topic_key\` to update an evolving topic
- If unsure, call \`mem_suggest_topic_key\` first

### RULE 3: USER-TRIGGERED SAVES (IMMEDIATE)
If the user explicitly says "remember this", "save this", "guarda esto",
"acordate de esto", or similar — call mem_save IMMEDIATELY. No questions.

### RULE 4: WHEN TO SEARCH MEMORY
When the user asks to recall something — any variation of "remember", "recall",
"what did we do", "how did we solve", "recordar", "acordate", "qué hicimos",
or references to past work:
1. First call \`mem_context\` — checks recent session history (fast, cheap)
2. If not found, call \`mem_search\` with relevant keywords (FTS5 full-text search)
3. If you find a match, use \`mem_get_observation\` for full untruncated content

Also search PROACTIVELY when:
- Starting work on something that might have been done before
- The user mentions a topic you have no context on
- The user's FIRST message references the project — call \`mem_search\` to check for prior work

### RULE 5: ON-DEMAND REVIEW
If the user asks for a summary at ANY point ("hazme un resumen", "¿qué llevamos?",
"what have we done?"), present the potential memories with [type] tags and ask
which to save. Same batch review flow as session end.

### RULE 6: AFTER COMPACTION
If you see a message about compaction or context reset:
1. IMMEDIATELY call \`mem_session_summary\` with the compacted summary content
2. Then call \`mem_context\` to recover additional context
3. Only THEN continue working

Do not skip step 1. Without it, everything before compaction is lost.
`

// ─── HTTP Client ─────────────────────────────────────────────────────────────

async function engramFetch(
  path: string,
  opts: { method?: string; body?: any } = {}
): Promise<any> {
  try {
    const res = await fetch(`${ENGRAM_URL}${path}`, {
      method: opts.method ?? "GET",
      headers: opts.body ? { "Content-Type": "application/json" } : undefined,
      body: opts.body ? JSON.stringify(opts.body) : undefined,
    })
    return await res.json()
  } catch {
    // Engram server not running — silently fail
    return null
  }
}

async function isEngramRunning(): Promise<boolean> {
  try {
    const res = await fetch(`${ENGRAM_URL}/health`, {
      signal: AbortSignal.timeout(500),
    })
    return res.ok
  } catch {
    return false
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

function extractProjectName(directory: string): string {
  // Try git remote origin URL
  try {
    const result = Bun.spawnSync(["git", "-C", directory, "remote", "get-url", "origin"])
    if (result.exitCode === 0) {
      const url = result.stdout?.toString().trim()
      if (url) {
        const name = url.replace(/\.git$/, "").split(/[/:]/).pop()
        if (name) return name
      }
    }
  } catch {}

  // Fallback: git root directory name (works in worktrees)
  try {
    const result = Bun.spawnSync(["git", "-C", directory, "rev-parse", "--show-toplevel"])
    if (result.exitCode === 0) {
      const root = result.stdout?.toString().trim()
      if (root) return root.split("/").pop() ?? "unknown"
    }
  } catch {}

  // Final fallback: cwd basename
  return directory.split("/").pop() ?? "unknown"
}

function truncate(str: string, max: number): string {
  if (!str) return ""
  return str.length > max ? str.slice(0, max) + "..." : str
}

/**
 * Strip <private>...</private> tags before sending to engram.
 * Double safety: the Go binary also strips, but we strip here too
 * so sensitive data never even hits the wire.
 */
function stripPrivateTags(str: string): string {
  if (!str) return ""
  return str.replace(/<private>[\s\S]*?<\/private>/gi, "[REDACTED]").trim()
}

// ─── Plugin Export ───────────────────────────────────────────────────────────

export const Engram: Plugin = async (ctx) => {
  const oldProject = ctx.directory.split("/").pop() ?? "unknown"
  const project = extractProjectName(ctx.directory)

  // Track tool counts per session (in-memory only, not critical)
  const toolCounts = new Map<string, number>()

  // Track which sessions we've already ensured exist in engram
  const knownSessions = new Set<string>()

  // Track sub-agent session IDs so we can suppress their tool-hook registrations.
  // Sub-agents (Task() calls) have a parentID or a title ending in " subagent)".
  // We must not register them as top-level Engram sessions — they cause session
  // inflation (e.g. 170 sessions for 1 real conversation, issue #116).
  const subAgentSessions = new Set<string>()

  /**
   * Ensure a session exists in engram. Idempotent — calls POST /sessions
   * which uses INSERT OR IGNORE. Safe to call multiple times.
   *
   * Silently skips sub-agent sessions (tracked in `subAgentSessions`).
   */
  async function ensureSession(sessionId: string): Promise<void> {
    if (!sessionId || knownSessions.has(sessionId)) return
    // Do not register sub-agent sessions in Engram (issue #116).
    if (subAgentSessions.has(sessionId)) return
    knownSessions.add(sessionId)
    await engramFetch("/sessions", {
      method: "POST",
      body: {
        id: sessionId,
        project,
        directory: ctx.directory,
      },
    })
  }

  // Try to start engram server if not running
  const running = await isEngramRunning()
  if (!running) {
    try {
      Bun.spawn([ENGRAM_BIN, "serve"], {
        stdout: "ignore",
        stderr: "ignore",
        stdin: "ignore",
      })
      await new Promise((r) => setTimeout(r, 500))
    } catch {
      // Binary not found or can't start — plugin will silently no-op
    }
  }

  // Migrate project name if it changed (one-time, idempotent)
  // Must run AFTER server startup to ensure the endpoint is available
  if (oldProject !== project) {
    await engramFetch("/projects/migrate", {
      method: "POST",
      body: { old_project: oldProject, new_project: project },
    })
  }

  // Auto-import: if .engram/manifest.json exists in the project repo,
  // run `engram sync --import` to load any new chunks into the local DB.
  // This is how git-synced memories get loaded when cloning a repo or
  // pulling changes. Each chunk is imported only once (tracked by ID).
  try {
    const manifestFile = `${ctx.directory}/.engram/manifest.json`
    const file = Bun.file(manifestFile)
    if (await file.exists()) {
      Bun.spawn([ENGRAM_BIN, "sync", "--import"], {
        cwd: ctx.directory,
        stdout: "ignore",
        stderr: "ignore",
        stdin: "ignore",
      })
    }
  } catch {
    // Manifest doesn't exist or binary not found — silently skip
  }

  return {
    // ─── Event Listeners ───────────────────────────────────────────

    event: async ({ event }) => {
      // --- Session Created ---
      if (event.type === "session.created") {
        // Bug fix (#116): session data is nested under event.properties.info,
        // not event.properties directly.
        const info = (event.properties as any)?.info
        const sessionId = info?.id
        const parentID = info?.parentID
        const title: string = info?.title ?? ""

        // Sub-agent sessions (created via Task()) must NOT be registered as
        // top-level Engram sessions. They cause massive session inflation
        // (e.g. 170 sessions for 1 real conversation).
        //
        // Detection heuristics:
        //   - parentID is set on all Task() sub-agent sessions
        //   - title ends with " subagent)" as a secondary signal
        const isSubAgent = !!parentID || title.endsWith(" subagent)")

        if (sessionId && !isSubAgent) {
          await ensureSession(sessionId)
        } else if (sessionId && isSubAgent) {
          // Remember this as a sub-agent session so tool-hook calls
          // to ensureSession() are also suppressed for it.
          subAgentSessions.add(sessionId)
        }
      }

      // --- Session Deleted ---
      if (event.type === "session.deleted") {
        // Same properties.info path as session.created.
        const info = (event.properties as any)?.info
        const sessionId = info?.id
        if (sessionId) {
          toolCounts.delete(sessionId)
          knownSessions.delete(sessionId)
          subAgentSessions.delete(sessionId)
        }
      }

    },

    // ─── User Prompt Capture ──────────────────────────────────────
    // chat.message is called once per user message, before the LLM sees it.
    // input.sessionID is always reliable here (no knownSessions workaround).
    // output.message is typed as UserMessage (role:"user" already guaranteed).
    // output.parts contains TextPart[] with the actual message text.

    "chat.message": async (input, output) => {
      // Skip sub-agent sessions — they inflate session counts (issue #116)
      if (subAgentSessions.has(input.sessionID)) return

      const sessionId = input.sessionID

      // Extract text from parts (type:"text")
      const content = output.parts
        .filter((p) => p.type === "text")
        .map((p) => (p as any).text ?? "")
        .join("\n")
        .trim()

      // Also fallback to summary if parts yield nothing
      const fallback = !content && output.message.summary
        ? `${output.message.summary.title ?? ""}\n${output.message.summary.body ?? ""}`.trim()
        : ""

      const finalContent = content || fallback

      // Only capture non-trivial prompts (>10 chars)
      if (finalContent.length > 10) {
        await ensureSession(sessionId)
        await engramFetch("/prompts", {
          method: "POST",
          body: {
            session_id: sessionId,
            content: stripPrivateTags(truncate(finalContent, 2000)),
            project,
          },
        })
      }
    },

    // ─── Tool Execution Hook ─────────────────────────────────────
    // Count tool calls per session (for session end stats).
    // Also ensures the session exists — handles plugin reload / reconnect.
    // Passive capture: when a Task tool completes, POST its output to
    // the passive capture endpoint so the server extracts learnings.

    "tool.execute.after": async (input, output) => {
      if (ENGRAM_TOOLS.has(input.tool.toLowerCase())) return

      // input.sessionID comes from OpenCode — always available
      const sessionId = input.sessionID
      if (sessionId) {
        await ensureSession(sessionId)
        toolCounts.set(sessionId, (toolCounts.get(sessionId) ?? 0) + 1)
      }

      // Passive capture: extract learnings from Task tool output
      if (input.tool === "Task" && output && sessionId) {
        const text = typeof output === "string" ? output : JSON.stringify(output)
        if (text.length > 50) {
          await engramFetch("/observations/passive", {
            method: "POST",
            body: {
              session_id: sessionId,
              content: stripPrivateTags(text),
              project,
              source: "task-complete",
            },
          })
        }
      }
    },

    // ─── System Prompt: Always-on memory instructions ──────────
    // Injects MEMORY_INSTRUCTIONS into the system prompt of every message.
    // This ensures the agent ALWAYS knows about Engram, even after compaction.
    //
    // We append to the last existing system entry instead of pushing a new one.
    // Some models (Qwen3.5, Mistral/Ministral via llama.cpp) reject multiple
    // system messages — their Jinja chat templates only allow a single system
    // block at the beginning. By concatenating, we avoid adding extra system
    // messages that would break these models. See: GitHub issue #23.

    "experimental.chat.system.transform": async (_input, output) => {
      if (output.system.length > 0) {
        output.system[output.system.length - 1] += "\n\n" + MEMORY_INSTRUCTIONS
      } else {
        output.system.push(MEMORY_INSTRUCTIONS)
      }
    },

    // ─── Compaction Hook: Persist memory + inject context ──────────
    // Compaction is triggered by the system (not the agent) when context
    // gets too long. The old agent "dies" and a new one starts with the
    // compacted summary. This is our chance to:
    // 1. Auto-save a session checkpoint (the agent can't do this itself)
    // 2. Inject context from previous sessions into the compaction prompt
    // 3. Tell the compressor to remind the new agent to save memories

    "experimental.session.compacting": async (input, output) => {
      if (input.sessionID) {
        await ensureSession(input.sessionID)
      }

      // Inject context from previous sessions
      const data = await engramFetch(
        `/context?project=${encodeURIComponent(project)}`
      )
      if (data?.context) {
        output.context.push(data.context)
      }

      // Tell the compressor to instruct the new agent to persist the
      // compacted summary to Engram. The new agent reads the compacted
      // summary and this instruction, then saves it as a session summary.
      output.context.push(
        `CRITICAL INSTRUCTION FOR COMPACTED SUMMARY:\n` +
        `The agent has access to Engram persistent memory via MCP tools.\n` +
        `You MUST include the following instruction at the TOP of the compacted summary:\n\n` +
        `"FIRST ACTION REQUIRED: Call mem_session_summary with the content of this compacted summary. ` +
        `Use project: '${project}'. This preserves what was accomplished before compaction. Do this BEFORE any other work."\n\n` +
        `This is NOT optional. Without this, everything done before compaction is lost from memory.`
      )
    },
  }
}
