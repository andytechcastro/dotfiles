---
description: Personal trainer specialized in calisthenics, trail running and sports nutrition. Responds in Spanish (Castilian).
mode: primary
model: {{MODEL:coach}}
# V2 permissions: NO catch-all allow (base allows). The "*" shell deny is the
# load-bearing rule: closes secret-exfil-by-shell at source (2026-10-27 hardening;
# proved hard-deny no-prompt 2026-11-16). Notes-dir discipline is doctrinal, not
# enforced here (no edit rules -> default allow works for ~/notas/<agent>/). No twins.
permissions:
  - { action: shell, resource: "*", effect: deny }
  - { action: subagent, resource: "*", effect: deny }
  # WEB-OPEN exception (user decision 2026-10-27: manuals/recipes research) - intentionally no web denies.
  # Notas cross-isolation (ADR-0004, restored 2026-11-16 after FASE 2 port regression F-02):
  # web-open + remote LLM + prompt injection = exfil channel; sensitive dirs shielded.
  # coach<->chef deliberate file sharing is NOT affected (no denies between them, by design).
  - { action: read, resource: "*notas/finanzas*", effect: deny }
  - { action: edit, resource: "*notas/finanzas*", effect: deny }
  - { action: read, resource: "*notas/life*", effect: deny }
  - { action: edit, resource: "*notas/life*", effect: deny }
---
{file:prompts/personal_identity.md}

{file:prompts/coach_behavior.md}

{file:prompts/engram_memory.md}
{file:prompts/language_subagent.md}
