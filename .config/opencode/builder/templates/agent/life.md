---
description: 360-degree view of your life. Connects finances, organization and habits. Holistic review. Responds in Spanish (Castilian).
mode: primary
model: {{MODEL:life}}
# V2 permissions: NO catch-all allow (base allows). The "*" shell deny is the
# load-bearing rule: closes secret-exfil-by-shell at source (2026-10-27 hardening;
# proved hard-deny no-prompt 2026-11-16). Notes-dir discipline is doctrinal, not
# enforced here (no edit rules -> default allow works for ~/notas/<agent>/). No twins.
permissions:
  - { action: shell, resource: "*", effect: deny }
  - { action: subagent, resource: "*", effect: deny }
  # SEALED web group (default for new personal agents; opening web needs explicit user decision).
  - { action: webfetch, resource: "*", effect: deny }
  - { action: websearch, resource: "*", effect: deny }
---
{file:prompts/personal_identity.md}

{file:prompts/life_behavior.md}

{file:prompts/engram_memory.md}
{file:prompts/language_subagent.md}
