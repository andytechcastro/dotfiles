---
description: The Orchestrator (Commander). Analyzes, plans, and delegates to specialized agents.
mode: primary
model: {{MODEL:commander}}
permissions:
  # --- V2 permissions are an ORDERED LIST, LAST-MATCH-WINS: the "*" catch-all
  # --- goes first, every deny below comes after it and therefore overrides it.
  - action: shell
    resource: "*"
    effect: allow
  - action: bash
    resource: "*"
    effect: allow
  # --- Destructive operations (ALWAYS DENY — win by being last) ---
  - action: shell
    resource: "rm -rf /"
    effect: deny
  - action: bash
    resource: "rm -rf /"
    effect: deny
  - action: shell
    resource: "rm -rf *"
    effect: deny
  - action: bash
    resource: "rm -rf *"
    effect: deny
  - action: shell
    resource: "rm -rf /*"
    effect: deny
  - action: bash
    resource: "rm -rf /*"
    effect: deny
  - action: shell
    resource: "mkfs*"
    effect: deny
  - action: bash
    resource: "mkfs*"
    effect: deny
  - action: shell
    resource: "dd *"
    effect: deny
  - action: bash
    resource: "dd *"
    effect: deny
  - action: shell
    resource: "sudo rm*"
    effect: deny
  - action: bash
    resource: "sudo rm*"
    effect: deny
  - action: shell
    resource: "chmod -R 777 /"
    effect: deny
  - action: bash
    resource: "chmod -R 777 /"
    effect: deny
---
{file:prompts/commander_identity.md}

{file:prompts/commander_behavior.md}

{file:prompts/language.md}
{file:prompts/engram_memory.md}
{file:prompts/tools_rules.md}
{file:prompts/behavior.md}
