---
description: Specialized Frontend Architect focused on UX/UI Design and modern web technologies (Next.js 15, React 19).
mode: subagent
model: {{MODEL:frontend_architect}}
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
  # --- Git write operations (sub-agents are read-only on git) ---
  - action: shell
    resource: "git add*"
    effect: deny
  - action: bash
    resource: "git add*"
    effect: deny
  - action: shell
    resource: "git commit*"
    effect: deny
  - action: bash
    resource: "git commit*"
    effect: deny
  - action: shell
    resource: "git push*"
    effect: deny
  - action: bash
    resource: "git push*"
    effect: deny
  - action: shell
    resource: "git pull*"
    effect: deny
  - action: bash
    resource: "git pull*"
    effect: deny
  - action: shell
    resource: "git merge*"
    effect: deny
  - action: bash
    resource: "git merge*"
    effect: deny
  - action: shell
    resource: "git rebase*"
    effect: deny
  - action: bash
    resource: "git rebase*"
    effect: deny
  - action: shell
    resource: "git reset*"
    effect: deny
  - action: bash
    resource: "git reset*"
    effect: deny
  - action: shell
    resource: "git checkout*"
    effect: deny
  - action: bash
    resource: "git checkout*"
    effect: deny
  - action: shell
    resource: "git stash*"
    effect: deny
  - action: bash
    resource: "git stash*"
    effect: deny
  - action: shell
    resource: "git cherry-pick*"
    effect: deny
  - action: bash
    resource: "git cherry-pick*"
    effect: deny
  # --- Network (no outbound from sub-agents) ---
  - action: shell
    resource: "curl*"
    effect: deny
  - action: bash
    resource: "curl*"
    effect: deny
  - action: shell
    resource: "wget*"
    effect: deny
  - action: bash
    resource: "wget*"
    effect: deny
  - action: shell
    resource: "nc*"
    effect: deny
  - action: bash
    resource: "nc*"
    effect: deny
  # --- macOS security ---
  - action: shell
    resource: "security*"
    effect: deny
  - action: bash
    resource: "security*"
    effect: deny
  - action: shell
    resource: "sysctl*"
    effect: deny
  - action: bash
    resource: "sysctl*"
    effect: deny
  # --- No outbound web fetch from sub-agents ---
  - action: webfetch
    resource: "*"
    effect: deny
---
{file:prompts/specialist_identity.md}

{file:prompts/frontend_behavior.md}


{file:prompts/engram_memory.md}
{file:prompts/tools_rules.md}
{file:prompts/caveman_behavior.md}
