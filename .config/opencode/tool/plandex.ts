import { tool } from "@opencode-ai/plugin"

const SKILL = `
---
name: plandex
description: Execute Plandex CLI commands for large-scale AI coding tasks using MiniMax models (OpenAI compatible).
license: MIT
---

## When to use this tool
Use this tool for large refactorings, multi-file generation tasks, or complex migrations that require a sandbox and high context. 

## How to use this tool
Pass the command string you want to execute with Plandex. Plandex maintains state in the current directory.
Typical workflow:
1. "new" (start a new plan)
2. "load <file_or_dir>" (load context)
3. "tell '<instructions>'" (instruct the AI to do the work)
4. "diff" (review proposed changes)
5. "apply" (apply the changes to the real files)

### Examples
- \`plandex("tell 'refactor the database models'")\`
- \`plandex("diff")\`
`;

export default tool({
  description: SKILL,
  args: {
    command: tool.schema.string().describe("The plandex command and arguments to execute (e.g., 'load src/', 'tell \"fix bugs\"')"),
    cwd: tool.schema.string().optional().describe("Working directory for the command. Defaults to current directory."),
  },
  async execute(args) {
    const { command, cwd } = args;
    
    try {
      // Inyectar variables de entorno para MiniMax (OpenAI Compatible)
      const env = {
        ...process.env,
        OPENAI_API_BASE: "https://api.minimax.chat/v1",
        // Asume que la clave de MiniMax está en el entorno del sistema o en un .env que carga Bun
        OPENAI_API_KEY: process.env.MINIMAX || process.env.MINIMAX_API_KEY || "FALTA_CLAVE_MINIMAX"
      };

      // Ejecutar plandex a través de bash para respetar las comillas y argumentos en el string
      const script = `cd ${cwd || "."} && plandex ${command}`;
      
      const { stdout, stderr, exitCode } = await Bun.spawn(["bash", "-c", script], {
        env,
      });
      
      const out = await new Response(stdout).text();
      const err = await new Response(stderr).text();
      
      if (exitCode !== 0) {
        return `❌ Plandex Error (Exit ${exitCode}):\n${err || out}`;
      }
      
      return (out || err || "Command executed successfully with no output.").trim();
    } catch (error: any) {
      return `❌ Execution failed: ${error.message}`;
    }
  },
})
