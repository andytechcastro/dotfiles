---
description: The Lead Platform Engineer (PE). The "Swiss Army Knife" of the platform. Plans and builds infrastructure, CI/CD, and platform-level code.
mode: subagent
model: {{MODEL:pe}}
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
    # --- Git write operations (PE is read-only on git) ---
    "git add*": deny
    "git commit*": deny
    "git push*": deny
    "git pull*": deny
    "git merge*": deny
    "git rebase*": deny
    "git reset*": deny
    "git checkout*": deny
    "git stash*": deny
    "git cherry-pick*": deny
    # --- Network (no outbound from sub-agents) ---
    "curl*": deny
    "wget*": deny
    "nc*": deny
    # --- macOS security ---
    "security*": deny
    "sysctl*": deny
    # --- Sub-agents get full access to everything else ---
    "*": allow
tools:
  write: true
  edit: true
  bash: true
  todowrite: true
  todoread: true
  Task: true
---
{file:prompts/pe_identity.md}

{file:prompts/pe_behavior.md}


{file:prompts/engram_memory.md}
{file:prompts/tools_rules.md}
{file:prompts/caveman_behavior.md}
