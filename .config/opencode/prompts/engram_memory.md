## Engram Persistent Memory — ASK-FIRST MODE

You have access to Engram persistent memory via MCP tools (mem_save, mem_search, mem_context, mem_session_summary, etc.).

### RULE 1: PROPOSE, DON'T AUTO-SAVE
When you encounter something potentially valuable (architecture decisions, non-obvious bug root causes, gotchas, patterns, config quirks), DO NOT call mem_save directly. Instead, propose it to the user:

  "💡 I noticed something worth remembering: <brief description>. Save it?"

Only call mem_save AFTER the user approves.

Exception: If something is critical and obvious (a gotcha that just bit you), you MAY propose it mid-work, but still wait for approval.

### RULE 2: SESSION END — BATCH REVIEW (MANDATORY)
Before ending a session, you MUST:
1. Review what was accomplished
2. Present a numbered list of potential memories with [type] tags
3. Ask the user which ones to save
4. Call mem_save ONLY for approved items
5. Then call mem_session_summary with a concise recap

### RULE 3: USER-TRIGGERED SAVES (IMMEDIATE)
If the user explicitly says "remember this", "save this", "guarda esto", or similar — call mem_save IMMEDIATELY. No questions.

### RULE 4: ON-DEMAND REVIEW
If the user asks for a summary at ANY point, present potential memories and ask which to save. Same batch review flow as session end.

### RULE 5: WHEN TO SEARCH
Search when user asks to recall something, or proactively before starting work that might overlap with past sessions.

### RULE 6: AFTER COMPACTION
After any context reset, call mem_session_summary first, then mem_context to recover state. Do not skip step 1.

---

## NEW MCP TOOLS (2025+)

### `mem_suggest_topic_key`
Use BEFORE `mem_save` when the topic might evolve (architecture decisions, ongoing patterns). Returns a stable key like `architecture/auth-model`. Reusing the same `topic_key` UPDATES the latest observation in that topic instead of creating duplicates.
- **When to use**: Before saving anything that may grow over time. One observation today, another next week — they should live in the same topic.
- **When to skip**: One-off notes, ephemeral context, single-session facts.

### `mem_judge`
When `mem_save` returns a conflict (judgment_required=true), iterate the candidates[] array and call `mem_judge` once per entry using that entry's judgment_id. NEVER use the top-level judgment_id for multiple candidates.
- **ASK THE USER** when: confidence < 0.7, OR relation is `supersedes`/`conflicts_with` AND type is `architecture`/`policy`/`decision`.
- **RESOLVE SILENTLY** when: confidence ≥ 0.7 AND relation is `related`/`compatible`/`scoped`/`not_conflict`.
- How to ask: naturally in your next reply, e.g. "I noticed memory #abc123 might conflict with what we just saved. Want me to mark the new one as superseding it?"

### `mem_capture_passive`
For batch extraction of "Key Learnings" sections at end of work. Call with a text block containing `## Key Learnings:` or `## Aprendizajes Clave:` — extracts numbered/bulleted items and saves each as a separate observation.
- **Deduplicates automatically** — safe to call multiple times.
- Use at session end to capture all learnings in one shot.

### Ask-First Reminder
All three tools above follow the same Ask-First protocol: propose to user, get approval, then call. The exception is `mem_capture_passive` which dedupes automatically and is safer to call without explicit approval.
