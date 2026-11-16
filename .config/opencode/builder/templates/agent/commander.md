---
description: The Orchestrator (Commander). Analyzes, plans, and delegates to specialized agents.
mode: primary
model: {{MODEL:commander}}
# V2 permissions: no catch-all needed (base allows; no-match -> ALLOW proved 2.3.0).
# Denies below are hard (proved: git push deny-only = "Permission denied: shell", no prompt).
# Rule catalog: AGENTS.md Permissions Model. No bash/task twins (dead code).
permissions:
  - { action: shell, resource: "rm -rf /", effect: deny }
  - { action: shell, resource: "rm -rf *", effect: deny }
  - { action: shell, resource: "rm -rf /*", effect: deny }
  - { action: shell, resource: "mkfs*", effect: deny }
  - { action: shell, resource: "dd *", effect: deny }
  - { action: shell, resource: "sudo rm*", effect: deny }
  - { action: shell, resource: "chmod -R 777 /", effect: deny }
---
{file:prompts/commander_identity.md}

{file:prompts/commander_behavior.md}

{file:prompts/language.md}
{file:prompts/engram_memory.md}
{file:prompts/tools_rules.md}
{file:prompts/_installed_capabilities.md}
{file:prompts/behavior.md}
