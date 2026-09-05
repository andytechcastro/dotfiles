---
description: Entrenador personal especializado en calistenia, trail running y nutrición deportiva. Habla en español.
mode: primary
model: {{MODEL:coach}}
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

{file:prompts/coach_behavior.md}

{file:prompts/engram_memory.md}
