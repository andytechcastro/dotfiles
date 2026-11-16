---
description: The Lead Platform Engineer (PE). The "Swiss Army Knife" of the platform. Plans and builds infrastructure, CI/CD, and platform-level code.
mode: subagent
model: {{MODEL:pe}}
# V2 permissions: enforcement lives HERE (frontmatter). Base policy allows all
# (no-match -> ALLOW proved on v2.3.0 runtime, 2026-11-16 probe); these denies carve out
# destructive ops / git writes / network egress / secrets-by-shell / leaf spawning.
# Rule catalog: prompts/_subagent_permissions.md. No bash/task twins (dead code).
permissions:
  - { action: shell, resource: "rm -rf /", effect: deny }
  - { action: shell, resource: "rm -rf *", effect: deny }
  - { action: shell, resource: "rm -rf /*", effect: deny }
  - { action: shell, resource: "mkfs*", effect: deny }
  - { action: shell, resource: "dd *", effect: deny }
  - { action: shell, resource: "sudo rm*", effect: deny }
  - { action: shell, resource: "chmod -R 777 /", effect: deny }
  - { action: shell, resource: "ln*~/.ssh*", effect: deny }
  - { action: shell, resource: "ln*~/.gnupg*", effect: deny }
  - { action: shell, resource: "git add*", effect: deny }
  - { action: shell, resource: "git commit*", effect: deny }
  - { action: shell, resource: "git push*", effect: deny }
  - { action: shell, resource: "git pull*", effect: deny }
  - { action: shell, resource: "git merge*", effect: deny }
  - { action: shell, resource: "git rebase*", effect: deny }
  - { action: shell, resource: "git reset*", effect: deny }
  - { action: shell, resource: "git checkout*", effect: deny }
  - { action: shell, resource: "git stash*", effect: deny }
  - { action: shell, resource: "git cherry-pick*", effect: deny }
  - { action: shell, resource: "curl*", effect: deny }
  - { action: shell, resource: "wget*", effect: deny }
  - { action: shell, resource: "nc*", effect: deny }
  - { action: shell, resource: "security*", effect: deny }
  - { action: shell, resource: "sysctl*", effect: deny }
  # Leaf hardening: no grandchild spawns, no web egress (deny also filters the model catalog).
  - { action: subagent, resource: "*", effect: deny }
  - { action: webfetch, resource: "*", effect: deny }
  - { action: websearch, resource: "*", effect: deny }
---
{file:prompts/pe_identity.md}

{file:prompts/pe_behavior.md}
{file:prompts/subagent_behavior.md}

{file:prompts/engram_memory.md}
{file:prompts/tools_rules.md}
{file:prompts/language_subagent.md}
{file:prompts/_installed_capabilities.md}
{file:prompts/caveman_behavior.md}
