// graphify OpenCode plugin (V2 plugin API)
// Injects a knowledge graph reminder before bash tool calls when the graph exists.
//
// Restored from the official `graphify opencode install` generator output
// (which still emits the V1 string-keyed hook shape) and ported to the V2
// `Plugin.define` contract. Hook mapping: "tool.execute.before" →
// ctx.tool.hook("execute.before"); V1 `output.args` → V2 mutable
// `event.input`. V2 renamed the bash tool to "shell"; both names match.
//
// IMPORTANT: keep the reminder string free of backticks and $(...) constructs.
// The hook prepends `echo "<reminder>" ; <cmd>` to the user's bash command;
// backticks inside the double-quoted echo trigger bash command substitution,
// which both corrupts tool output and silently executes the very graphify
// command we are only suggesting. Plain words render fine in opencode's TUI.
import { existsSync } from "fs";
import { join } from "path";
import { Plugin } from "@opencode/plugin";

// Tool names that run shell commands: "bash" is the V1 name, "shell" is the
// V2 name for the same core tool.
const SHELL_TOOLS = ["bash", "shell"];

export default Plugin.define({
  id: "graphify",
  async setup(ctx) {
    let reminded = false;
    const directory = ctx.location.directory;

    await ctx.tool.hook("execute.before", async (event) => {
      if (reminded) return;
      if (!existsSync(join(directory, "graphify-out", "graph.json"))) return;

      if (SHELL_TOOLS.includes(event.tool)) {
        // ';' not '&&' — Windows PowerShell 5.1 rejects '&&' as a statement
        // separator, breaking the first bash command of the session (#1646).
        event.input.command =
          'echo "[graphify] knowledge graph at graphify-out/. For focused questions, run graphify query with your question (scoped subgraph, usually much smaller than GRAPH_REPORT.md) instead of grepping raw files. Read GRAPH_REPORT.md only for broad architecture context." ; ' +
          event.input.command;
        reminded = true;
      }
    });
  },
});
