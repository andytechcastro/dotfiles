# Subagent Permission Rules (DRY — included by all technical sub-agents)

## Engine law (v2.3.0 — measured dynamically 2026-11-16 on isolated Basic-auth probes; supersedes all older "dual vocabulary" / "catch-all-first" doctrine)

1. **No matching rule → ALLOW.** There is NO default ask; a headless agent never deadlocks waiting for approval. Old claim "global array replaces base → ask" is FALSE and retired.
2. `permissions:` is an ORDERED LIST, **last-match-wins**, inline-flow entries: `- { action: shell, resource: "curl*", effect: deny }`. No catch-all allow is needed — the base already allows everything the denies don't carve out.
3. **Docs action names only**: `shell`, `subagent`, `webfetch`, `websearch`, `read`, `edit`. The `bash:`/`task:` twins are **dead code** (proved at runtime) and have been removed from every template.
4. A deny is HARD and silent: `shell`-deny produces `Permission denied: shell`, zero prompts, exit without execution.
5. Denying `subagent`/`webfetch`/`websearch` also **filters the model tool catalog** — the model literally does not see the tool. Stronger than runtime blocking.
6. **Glob semantics**: `*` crosses `/`; patterns match anchored at the path END; leading dots are NOT special (`dir/.env` matches `*.env*`). `*.ssh/*` matches `/home/u/.ssh/id_rsa`.
7. **Floors**: `experimental.policies` entries `tool.use "<action>:<glob>"` evaluate BEFORE any agent rule and emit `Blocked by configuration policy`. Floors cannot express allow-lifts — `read:*.env*` therefore also blocks `.env.example` (accepted cost, defense-in-depth).

## Technical sub-agents (PE + 6 architects) — deny-only inline frontmatter

- Destructive: `rm -rf /`, `rm -rf *`, `rm -rf /*`, `mkfs*`, `dd *`, `sudo rm*`, `chmod -R 777 /`
- Git write-only denies (`git status|diff|log` READ is allowed): add, commit, push, pull, merge, rebase, reset, checkout, stash, cherry-pick (all `*` suffix)
- Network shell: `curl*`, `wget*`, `nc*`; macOS relics `security*`, `sysctl*` kept as zero-cost documentation
- Leaf hardening: `subagent * deny` (no grandchild spawns), `webfetch * deny`, `websearch * deny`
- Commander keeps ONLY the 7 destructive denies (orchestrator needs git push, curl, subagent spawning).

## Personal agents (7) — remote models, shell sealed at source

- `- { action: shell, resource: "*", effect: deny }` FIRST = the load-bearing rule (2026-10-27 hardening): closes secret-exfil-by-shell against a remote provider. Proved hard-deny, no prompt.
- `subagent * deny`. No edit/read rules at all: base allow covers `~/notas/<agent>/` (writes work — measured). Notes-dir discipline is DOCTRINAL, not enforced by frontmatter.
- SEALED group (`finanzas`, `organiza`, `habitos`, `life`): + `webfetch * deny`, `websearch * deny`. WEB-OPEN group (`barista`, `coach`, `chef`): deliberately no web denies (explicit user decision 2026-10-27). **Any NEW personal agent defaults SEALED**; opening web requires a recorded user decision.

## Secret floors (config template `experimental.policies`, apply to EVERY agent including Commander)

`read|edit|shell` × `*.ssh*`, `*.env*`, `*.secret_envs*`, `*.netrc*`, `*.config/gh/hosts.yml*`, `*auth.json*`, `*opencode.db*`, `*cli-proxy-api*`, `*.config/opencode/opencode.json*` — 27 entries. Closes the measured HIGH bypass `cat ~/.ssh/id_rsa` (shell raw-text matched against floors). Pattern `*.secret_envs*` is the corrected form — Mac's legacy typo `*.secrets_env*` covers nothing here.

## Audit fingerprints

- `Permission denied: <action>` → frontmatter/policies-array layer.
- `Blocked by configuration policy` → `tool.use` floors layer.
- `session.permission` stays NULL even under active denies — audit from tool-parts `permission.rejected` events, never that column.
