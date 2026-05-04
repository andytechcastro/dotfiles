---
description: Specialized Frontend Architect focused on UX/UI Design and modern web technologies (Next.js 15, React 19).
mode: subagent
model: qwen/Qwen3.6-Plus
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

{file:prompts/frontend_behavior.md}


{file:prompts/tools_rules.md}
{file:prompts/caveman_behavior.md}
