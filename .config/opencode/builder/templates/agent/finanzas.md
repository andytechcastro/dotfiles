---
description: Asesor financiero personal. Presupuesto, gastos, ahorro, inversión (consejos, no monitoreo). Habla en español.
mode: primary
model: {{MODEL:finanzas}}
permission:
  write: ask
  edit: ask
  bash:
    "rm -rf /": deny
    "rm -rf *": deny
    "rm -rf /*": deny
    "mkfs*": deny
    "dd *": deny
    "sudo rm*": deny
    "chmod -R 777 /": deny
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
    "curl*": deny
    "wget*": deny
    "nc*": deny
    "*": allow
tools:
  write: true
  edit: true
  bash: true
  todowrite: false
  todoread: false
  Task: false
---
{file:prompts/personal_identity.md}

{file:prompts/finanzas_behavior.md}

{file:prompts/engram_memory.md}
