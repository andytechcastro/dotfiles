# includes/ — DRY fragments for plugin markdown

Fragments are shared markdown text inlined into both plugins at build time. A fragment is
`includes/<key>.md` with `key` matching `[A-Za-z0-9_.-]+` (e.g. `shared-behavior`).

## Convention {{INCLUDE:key}}

- In any source `*.md` under `suite/**` or `personal/**`, put the token alone on a line
  (leading/trailing spaces or tabs allowed):

      {{INCLUDE:shared-behavior}}

- `build.sh` replaces the whole line with the full contents of `includes/shared-behavior.md`.
- **Flatten is one pass, no nesting**: fragments must not contain `{{INCLUDE:...}}` tokens.
- Inline tokens (on a line with other text) are NOT replaced — the build FAILS on the stray token.
- Missing fragment → build FAIL. Empty fragment → line is dropped.
- Only `*.md` is flattened; `plugin.json`/`hooks.json`/`mcp_config.json` never carry tokens.

## Budgets (measured on flattened bytes in `dist/`, enforced by `build.sh`)

| Surface | Limit | Enforced |
|---|---|---|
| `agents/*.md` (per agent) | 24576 B (24 KB) | build FAIL above limit |
| `rules/*.md` (per file) | 6144 B (6 KB) | build FAIL above limit |
| Aggregate active prompt (rules + agent) | ~20k tokens | review at F2/F3 — not machine-checked (no tokenizer dependency in build) |

Split large shared behavior across several small fragments; only referenced fragments cost
budget (tokens are substituted, unreferenced `includes/*.md` files are never synced).
