---
description: Specialized Security Architect focused on auditing IaC, secrets, and security vulnerabilities.
mode: subagent
model: minimax/MiniMax-M2.7
tools:
  write: true
  edit: true
  bash: true
permission:
  write: ask
  edit: ask
---
{file:prompts/specialist_identity.md}

{file:prompts/security_behavior.md}


{file:prompts/tools_rules.md}
{file:prompts/caveman_behavior.md}
