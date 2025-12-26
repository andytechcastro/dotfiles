PREFERRED CLI TOOLS - ALWAYS USE THESE INSTEAD OF LEGACY COMMANDS:
You MUST use these modern tools over their legacy equivalents. If any tool is missing, install it via brew before proceeding.

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

TOOL CHECK ON SESSION START:
If you need to use any of these tools and they fail, immediately offer to install them:
- Check: which bat rg fd sd eza
- Install missing: yay -S <tool-name>

NEVER use cat, grep, find, sed, or ls when these modern alternatives exist!
