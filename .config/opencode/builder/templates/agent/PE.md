---
description: The Lead Platform Engineer (PE). The "Swiss Army Knife" of the platform. Plans and builds infrastructure, CI/CD, and platform-level code.
mode: subagent
model: minimax/MiniMax-M2.7
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
      - "git add*"
      - "git commit*"
      - "git push*"
      - "git pull*"
      - "git merge*"
      - "git rebase*"
      - "git reset*"
      - "git checkout*"
      - "git stash*"
      - "git cherry-pick*"
      - "curl*"
      - "wget*"
      - "nc*"
      - "security*"
      - "sysctl*"
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
{file:prompts/pe_identity.md}

{file:prompts/pe_behavior.md}


{file:prompts/tools_rules.md}
{file:prompts/caveman_behavior.md}
