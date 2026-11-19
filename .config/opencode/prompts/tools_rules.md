PREFERRED CLI TOOLS + MEASURED PLATFORM FACTS

Install missing tools first: `yay -S <pkg>` (Arch) / `brew install <pkg>` (macOS) / `pip|npm` where noted.
Modern tools replace their legacy equivalents — use them unless a row below says otherwise.

## MEASURED FACTS (normative — each row was measured, not assumed; treat them as constraints, not advice)

| Fact | Consequence |
|---|---|
| `rg` matches **contents, not filenames** | Never conclude a file is absent from a content search. Name search: `rg --files -g '<glob>'` or `fd`. A single-file grep proves nothing about a sibling file. |
| `eza` may be absent, and can print nothing on a populated directory | Existence listings use `ls -la <absdir>` or `find <absdir> -maxdepth N`. An empty `eza` output is NOT an empty directory. |
| `find -newermt` / mtimes are **not** tree-quietness primitives | `cp -p`, `rsync` and `tar` preserve mtimes and deletions leave no trace. Quiescence = two-anchor checksum sandwich (`md5sum $(find <dir> -type f \| sort)` before AND after) or `git status --porcelain`. |
| Shell output passes through `squeez`: wrap wall now **900 s**, caps `max_lines=120`, `read_max_lines=300`, `grep_max_results=100`, `find_max_results=50`, `agent_prompt_max_tokens=2000` | Long output is silently ELIDED and stored behind a retrieve key. Never narrate elided output as if seen: write it to `docs/evidence/<ticket>.log` and cite the log path. Sub-2000-token briefs only, else put the contract in a file. |
| `--no-squeez` raw escape exists in the plugin | **Dead until the service is restarted** (plugin/tool registration happens at service start; a rebuild or hot reload does not re-register hooks on live sessions). |
| `tool.use` floors deny read/edit/shell on paths containing `env`, `secret_envs`, `ssh`, `auth.json`, `opencode.db` | `source ~/.secret_envs` is unavailable inside any agent; secrets must already be in the daemon's process env. `.env.example` reads are blocked by design. |
| Compiling `AGENTS.md`/prompts is a per-step cost | Every byte added to a prefix is re-paid every step, on every project, on both machines. Offsets, not additions, are the budget (ADR 0009). |

## TOOL USAGE

1. `bat` (replaces `cat`) — `bat -p <file>` plain, `bat --style=plain,numbers`, `bat -l <lang> <file>`.
2. `rg` (replaces `grep`) — `-i`, `-t ts`, `-l` files-only, `-C 3` context, `--json` for parsing; `--files -g` for NAMES.
3. `fd` (replaces `find`) — `-e ts`, `-t f`, `-t d`, `-H` hidden, `-x cmd {}`.
4. `sd` (replaces `sed`) — `sd 'a' 'b' file`, `-s` literal, pipe form, groups `sd '(\w+)' '$1_x'`.
5. `eza` — `eza -la`, `--tree -L 2`, `--icons`, `-la --git`. See facts table: not an existence oracle.
6. `mgrep` — semantic search, **cost-sensitive: every call burns tokens**. Concept discovery and unknown-symbol
   mapping only; never for known variables, class names or exact strings (use `rg`).
7. `graphify` — knowledge graph, AST-only (no LLM cost): `graphify update .` re-extracts; `graphify opencode
   install` bootstraps a project; `graphify query "<q>"` for architectural context; read
   `graphify-out/GRAPH_REPORT.md` before answering architecture questions. **Ignores dot-folders:** scan them via
   `ln -s .config/foo src_foo && graphify update src_foo && rm src_foo`.
8. `sg` (ast-grep) — structural search/rewrite (`sg --pattern 'func foo($A) { $$$ }' --rewrite '...'`); use where
   regex would break syntax. `yay -S ast-grep`.
9. `grep-ast` — context-aware search printing the enclosing function/class: `grep-ast "pattern" <file>`. `pip install grep-ast`.
10. `repomix` — pack a directory for one-shot reading: `repomix src/components -o context.xml`. `npm i -g repomix`.
11. `uv` — `uv pip install`, `uv venv`, `uv add` (10-100× faster than pip).
12. `just` — `just` lists recipes, `just build`, `just test` (Make alternative).
13. `gh` — `gh pr create/list/view`, `gh issue create/list`, `gh run list/view <id>`. `yay -S github-cli`.
14. `lazygit` — TUI for rebases, conflicts, history, staging, push.
15. `fzf` — fuzzy history/pickers (`fd . | fzf`).
16. `zoxide` — `z <partial>` smarter cd.
17. `delta` — `git diff | delta` side-by-side highlighting.
18. `btop` — terminal system monitor.

TOOL CHECK ON SESSION START: if a needed tool is missing, verify with `which <tool>` and offer to install it
(`yay -S <tool>`; pip/npm where the row says so). Never substitute a legacy command when the modern tool exists —
EXCEPT where a fact row above explicitly makes the legacy tool the correct choice (`ls -la` for existence).
