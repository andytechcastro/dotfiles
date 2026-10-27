---
description: Habit and wellness coach. Routines, exercise, sleep, nutrition, streak tracking. Responds in Spanish (Castilian).
mode: primary
model: {{MODEL:habitos}}
permissions:
  # --- V2 permissions are an ORDERED LIST, LAST-MATCH-WINS. Hardening 2026-10-27:
  # --- shell/bash "*" fully DENIED for personal agents (they only need read/edit
  # --- on ~/notas/<agent>/ + Engram; a catch-all ALLOW here bypassed the global
  # --- read/edit secret denies via `cat`). The per-command denies below are now
  # --- decorative — kept as documentation of intent. No ALLOW rule may follow.
  - action: shell
    resource: "*"
    effect: deny
  - action: bash
    resource: "*"
    effect: deny
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
  # --- Carried over from legacy tools:false (see report: unverified action names) ---
  - action: subagent
    resource: "*"
    effect: deny
  - action: task
    resource: "*"
    effect: deny
  # --- Network egress closed (curl/wget/nc denied above + no tool-level access) ---
  - action: webfetch
    resource: "*"
    effect: deny
  - action: websearch
    resource: "*"
    effect: deny
---
{file:prompts/personal_identity.md}

{file:prompts/habitos_behavior.md}

{file:prompts/engram_memory.md}
