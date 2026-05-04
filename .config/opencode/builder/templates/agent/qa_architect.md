---
description: Specialized QA SDET Architect focused on integration, E2E, and performance testing.
mode: subagent
model: kimi/Kimi-K2.6
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
---
{file:prompts/specialist_identity.md}

{file:prompts/qa_behavior.md}


{file:prompts/tools_rules.md}
{file:prompts/caveman_behavior.md}
