PREFERRED CLI TOOLS - ALWAYS USE THESE INSTEAD OF LEGACY COMMANDS:
You MUST use these modern tools over their legacy equivalents. If any tool is missing, install it via yay (Arch) or brew (macOS) before proceeding.

1. bat (replaces cat):
   - bat <file> → syntax-highlighted file viewing
   - bat -p <file> → plain output without line numbers/decorations
   - bat -l <language> <file> → force specific syntax highlighting
   - bat --style=plain,numbers <file> → customize output style
   - INSTALL: yay -S bat

2. rg (ripgrep, replaces grep):
   - rg 'pattern' → recursive search in current directory
   - rg -i 'pattern' → case-insensitive search
   - rg -t ts 'pattern' → search only TypeScript files
   - rg -l 'pattern' → list only filenames with matches
   - rg -C 3 'pattern' → show 3 lines of context
   - rg --json 'pattern' → JSON output for parsing
   - INSTALL: yay -S ripgrep

3. fd (replaces find):
   - fd 'pattern' → find files matching pattern
   - fd -e ts → find all .ts files
   - fd -t f 'pattern' → find only files (not directories)
   - fd -t d 'pattern' → find only directories
   - fd -H 'pattern' → include hidden files
   - fd -x command {} → execute command on each result
   - INSTALL: yay -S fd 

4. sd (replaces sed):
   - sd 'find' 'replace' <file> → in-place replacement
   - sd -s 'literal' 'replace' <file> → literal string (no regex)
   - echo 'text' | sd 'find' 'replace' → piped replacement
   - sd 'pattern' 'replace' → supports regex groups: sd '(\w+)' '$1_suffix'
   - INSTALL: yay -S sd

5. eza (replaces ls):
   - eza → beautiful file listing
   - eza -la → all files with detailed info
   - eza --tree → directory tree view
   - eza --tree -L 2 → tree with depth limit
   - eza --icons → show icons (requires nerd font)
   - eza -la --git → show git status
   - INSTALL: yay -S eza

6. mgrep (Semantic Search - COST SENSITIVE):
   - mgrep "concept" → natural language search across code/docs
   - mgrep -a "question" → get an answer based on code context
   - mgrep --web "query" → search web + local
   - CRITICAL: Every call costs tokens. 
   - USE ONLY FOR: Conceptual discovery, feature mapping in unknown repos, or when exact symbols are unknown.
   - DO NOT USE FOR: Finding known variables, class names, or specific strings (USE rg INSTEAD).

7. graphify (Knowledge Graph - THE SOURCE OF TRUTH):
   - graphify update . → re-extract code files and update the graph (AST-only, no LLM cost).
   - graphify opencode install → bootstrap graphify in a new project (injects rules and plugin).
   - graphify query "question" → query the knowledge graph for architectural context.
   - CRITICAL - Dot-Folders: graphify ignores folders starting with "." (e.g. .config). To scan them, use a symlink: ln -s .config/foo src_foo && graphify update src_foo && rm src_foo.
   - USE ALWAYS: Before answering architecture or codebase questions, read graphify-out/GRAPH_REPORT.md.

8. sg (ast-grep, replaces sd for structural code):
   - sg --pattern 'func foo($A) { $$$ }' --rewrite 'func bar($A) { $$$ }' → Structural search and replace.
   - USE FOR: Complex refactoring where regex might break syntax (indentation, brackets).
   - INSTALL: yay -S ast-grep

9. grep-ast (Context-aware search):
   - grep-ast "pattern" <file> → Search and print the function/class tree around the match.
   - USE FOR: Finding variables/functions while instantly seeing what scope they belong to.
   - INSTALL: pip install grep-ast

10. repomix (Context Injector):
    - repomix src/components -o context.xml → Pack an entire directory for LLM consumption.
    - USE FOR: When you need to read multiple files simultaneously to understand a full module.
    - INSTALL: npm install -g repomix

TOOL CHECK ON SESSION START:
If you need to use any of these tools and they fail, immediately offer to install them:
- Check: which bat rg fd sd eza mgrep graphify sg grep-ast repomix
- Install missing: yay -S <tool-name> (or pip/npm for specific ones)

MODERN CLI ADDITIONS (2026):
11. uv (Ultra-fast Python package manager):
    - uv pip install package → 10-100x faster than pip
    - uv venv → create virtual environments instantly
    - uv add package → add to project dependencies
    - INSTALL: yay -S uv

12. just (Command runner, modern Make alternative):
    - just → show available recipes
    - just build → run build recipe from justfile
    - just test → run test commands
    - INSTALL: yay -S just

NEVER use cat, grep, find, sed, or ls when these modern alternatives exist!
