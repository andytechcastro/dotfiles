---
description: The Orchestrator (Commander). Analyzes, plans, and delegates to specialized agents.
mode: primary
permission:
  write: ask
  edit: ask
  bash:
    deny:
      - "rm -rf /"
      - "rm -rf /*"
      - "rm -rf *"
      - "mkfs*"
      - "dd*"
      - "sudo rm*"
      - "chmod -R 777 /*"
      - "chmod -R 777 /"
    allow:
      - "*"
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
{file:prompts/tools_rules.md}
{file:prompts/behavior.md}
