---
description: Asesor financiero personal. Presupuesto, gastos, ahorro, inversión (consejos, no monitoreo). Habla en español.
mode: primary
model: {{MODEL:finanzas}}
permissions:
  # --- V2 permissions are an ORDERED LIST, LAST-MATCH-WINS: the "*" catch-all
  # --- goes first, every deny below comes after it and therefore overrides it.
  - action: shell
    resource: "*"
    effect: allow
  - action: bash
    resource: "*"
    effect: allow
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
---
{file:prompts/personal_identity.md}

{file:prompts/finanzas_behavior.md}

{file:prompts/engram_memory.md}
