---
description: The Orchestrator (Commander). Analyzes, plans, and delegates to specialized agents.
mode: primary
permission:
  write: ask
  edit: ask
  bash:
    # --- Destructive operations (ALWAYS DENY — evaluated first) ---
    "rm -rf /": deny
    "rm -rf *": deny
    "rm -rf /*": deny
    "mkfs*": deny
    "dd *": deny
    "sudo rm*": deny
    "chmod -R 777 /": deny
    # --- Commander has FULL access. No asking. ---
    "*": allow
tools:
  write: true
  edit: true
  bash: true
  todowrite: true
  todoread: true
  Task: true
---
{file:prompts/commander_identity.md}

{file:prompts/commander_behavior.md}

{file:prompts/language.md}
{file:prompts/engram_memory.md}
{file:prompts/tools_rules.md}
{file:prompts/behavior.md}
