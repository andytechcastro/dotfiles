// squeez OpenCode plugin — full-parity integration (V2 plugin API).
//
// Conforms to the @opencode/plugin V2 contract: a default export produced by
// `Plugin.define({ id, setup(ctx) })`. `setup` registers hooks directly on
// the domain objects (ctx.tool.hook, ctx.event.subscribe) instead of
// returning a string-keyed hook map like V1's `server()` did. When the squeez
// binary is absent, setup registers nothing and returns early — OpenCode runs
// as if the plugin were not installed.
//
// Hooks:
//   - ctx.event.subscribe (session.created) → finalize previous session and
//     refresh AGENTS.md via `squeez init --host=opencode`.
//   - ctx.tool.hook("execute.before") (bash) → rewrite command to
//     `squeez wrap <cmd>`. V2 renamed the bash tool to "shell"; both names
//     are matched so behaviour is preserved either way.
//   - ctx.tool.hook("execute.before") (read/grep) → inject budget limits so
//     Read and Grep respect the squeez config.
//   - ctx.tool.hook("execute.after") (any known tool) → fire-and-forget
//     `squeez track-result` for post-execution context tracking.
//
// Caveat (upstream sst/opencode#2319): MCP tool calls may not trigger these
// hooks. That's a host limitation, not something this plugin can work around.

import { execSync, spawn } from "child_process";
import { existsSync } from "fs";
import { Plugin } from "@opencode/plugin";

const HOME = process.env.HOME || process.env.USERPROFILE || "";
// Ported from dotfilesMac 2026-11-16 (fork parity — never git-apply between
// the two repos). Install location varies per machine: Arch dotfiles keep
// squeez at ~/.local/bin/squeez; the Claude Code bundle lives at
// ~/.claude/squeez/bin/squeez. Probe both (plus SQUEEZ_BIN override) —
// probing the wrong one made squeezExists() false and setup() silently
// registered zero hooks (the plugin loaded but never wrapped anything).
const SQUEEZ_CANDIDATES = [
  process.env.SQUEEZ_BIN,
  `${HOME}/.local/bin/squeez`,
  `${HOME}/.claude/squeez/bin/squeez`,
].filter(Boolean);
function findSqueezBin() {
  for (const p of SQUEEZ_CANDIDATES) {
    try {
      execSync(`test -x "${p}"`, { timeout: 500 });
      return p;
    } catch {
      // try next
    }
  }
  return SQUEEZ_CANDIDATES[0];
}
const SQUEEZ_BIN = findSqueezBin();

// Data home: prefer XDG ~/.local/share/squeez; fall back to the legacy
// ~/.claude/squeez — which on THIS box is the live data dir (blobs, memory,
// sessions; measured 2026-11-16). Keeps GUI-launched TUI consistent even
// when shell env vars were never inherited.
process.env.SQUEEZ_DIR = process.env.SQUEEZ_DIR
  || (existsSync(`${HOME}/.local/share/squeez`) ? `${HOME}/.local/share/squeez` : `${HOME}/.claude/squeez`);

// Tool names that run shell commands: "bash" is the V1 name, "shell" is the
// V2 name for the same core tool.
const SHELL_TOOLS = ["bash", "shell"];

// Map OpenCode's lowercase tool names to the capitalized slugs the squeez
// budget-params subcommand expects (Read / Grep).
const BUDGET_TOOL_SLUG = {
  read: "Read",
  grep: "Grep",
};

function squeezExists() {
  try {
    execSync(`test -x "${SQUEEZ_BIN}"`, { timeout: 500 });
    return true;
  } catch {
    return false;
  }
}

function runInit() {
  try {
    execSync(`"${SQUEEZ_BIN}" init --host=opencode`, { timeout: 5000 });
  } catch {
    // best-effort — don't break the session if squeez init fails
  }
}

function budgetPatch(tool) {
  const slug = BUDGET_TOOL_SLUG[tool];
  if (!slug) return null;
  try {
    const out = execSync(`"${SQUEEZ_BIN}" budget-params ${slug}`, {
      timeout: 2000,
      encoding: "utf8",
    }).trim();
    if (!out) return null;
    return JSON.parse(out);
  } catch {
    return null;
  }
}

function trackResult(tool) {
  // Fire-and-forget — don't block the tool pipeline.
  try {
    spawn(SQUEEZ_BIN, ["track-result", tool], {
      stdio: "ignore",
      detached: true,
    }).unref();
  } catch {
    // best-effort
  }
}

export default Plugin.define({
  id: "squeez",
  async setup(ctx) {
    // Registering nothing (vs. throwing) keeps the plugin loader happy when
    // squeez isn't on the machine.
    if (!squeezExists()) return;

    // V1 `event` hook → V2 subscription on the public event stream.
    const controller = new AbortController();
    void (async () => {
      for await (const event of ctx.event.subscribe({ signal: controller.signal })) {
        if (event && event.type === "session.created") {
          runInit();
        }
      }
    })().catch(() => {
      // subscription died — squeez stays best-effort, never crash the host
    });

    await ctx.tool.hook("execute.before", async (event) => {
      // V1 mutated `output.args`; V2 hands us the mutable call arguments on
      // `event.input`.
      const args = event.input;
      if (!event || !args) return;

      if (SHELL_TOOLS.includes(event.tool)) {
        const command = args.command;
        if (!command || typeof command !== "string") return;
        if (command.startsWith(SQUEEZ_BIN)) return;
        if (command.includes("squeez wrap")) return;
        // PL-1 evidence-escape fix: `--no-squeez <cmd>` must run <cmd> RAW.
        // The python claude-code hook strips the prefix; this JS plugin used to
        // only `return` (no unwrap), so the shell received the literal
        // `--no-squeez …` token -> command-not-found, and the raw-proof escape
        // (needed by the ledger evidence contract, rules 2/3/9) was dead. Strip
        // the leading token here so the command runs un-squeezed.
        if (command.startsWith("--no-squeez")) {
          args.command = command.replace(/^--no-squeez\s+/, "");
          return;
        }
        // Shell-quote the command before prepending `squeez wrap`. Without
        // this, multi-line `python3 -c "..."`, `bash -c '...'`, and quoted
        // `git commit -m "msg with spaces"` are split into separate argv
        // tokens by the host shell and end up with `-c` getting no argument,
        // pathspec errors on commit messages, etc. Matches what the
        // claude-code Python hook does with `shlex.quote(cmd)`.
        const quoted = "'" + command.replace(/'/g, "'\\''") + "'";
        args.command = `${SQUEEZ_BIN} wrap ${quoted}`;
        return;
      }

      const patch = budgetPatch(event.tool);
      if (!patch) return;
      for (const [k, v] of Object.entries(patch)) {
        // Do not override fields the user (or agent) already set explicitly.
        if (args[k] === undefined) {
          args[k] = v;
        }
      }
    });

    await ctx.tool.hook("execute.after", async (event) => {
      if (!event || !event.tool) return;
      // Only track tools we know about — keeps the noise down.
      if (["bash", "shell", "read", "grep", "glob"].includes(event.tool)) {
        trackResult(event.tool);
      }
    });

    return () => controller.abort();
  },
});
