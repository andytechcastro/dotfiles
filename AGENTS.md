# AGENTS.md - Instructions for Agentic AI

This repository contains system dotfiles and a modular AI agent builder. You are an agentic coding assistant operating in this environment.

---

## 🛠 Build & Development Commands

### 1. OpenCode Builder (Go)
Located in `.config/opencode/builder/`.
- **Run Builder**: `go run main.go`
- **Lint**: `go vet ./...`
- **Format**: `go fmt ./...`
- **Test (All)**: `go test ./...`
- **Test (Single)**: `go test -v -run TestName ./path/to/package`
- **Build Binary**: `go build -o builder main.go`

### 2. OpenCode SDK (Node/Bun)
Located in `.config/opencode/`.
- **Install**: `bun install` or `npm install`
- **Update Dependencies**: `bun update`
- **Lint**: `bun run lint` (if configured)
- **Test**: `bun test`
- **Test (Single File)**: `bun test path/to/file.test.ts`

### 3. System Tools
- **Install All Tools**: `./install-tools.sh`
- **Check Dotfiles Status**: 
  ```bash
  alias dotfiles='/usr/bin/git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME"'
  dotfiles status
  ```
- **Reload Shell**: `source ~/.zshrc`

---

## 📜 Code Style & Guidelines

### 1. General Principles
- **Clean Architecture**: Follow modular patterns. Keep logic separated from configuration. Logic belongs in `.config/opencode/builder/` or prompt templates, while specific values belong in environment variables or `config.json` (which is gitignored).
- **Platform Engineer Mindset**: Prefer CLI tools over GUIs. Always use modern alternatives (`rg`, `fd`, `sd`, `eza`, `bat`).
- **Minimalism**: Don't add unnecessary dependencies. If a task can be done with standard tools or built-in Go libraries, avoid external packages.
- **Security**: Never commit API keys, tokens, or personal information. Use the `_requires_env` feature in OpenCode templates to handle secrets safely.

### 2. Go (Golang)
- **Error Handling**: ALWAYS handle errors explicitly. Never use `_` to ignore errors from functions that return them.
  ```go
  if err := doSomething(); err != nil {
      return fmt.Errorf("failed to do something: %w", err)
  }
  ```
- **Imports**: Group standard library imports separately from external ones. Use `goimports` if available.
- **Naming**: 
  - Constants: `PascalCase` (e.g., `TemplatesDir`)
  - Variables/Functions: `camelCase` (e.g., `processAgents`)
  - Exported Functions: `PascalCase`
- **Dependencies**: Prefer standard library (`os`, `fmt`, `encoding/json`, `path/filepath`). Avoid `ioutil` as it is deprecated in newer Go versions; use `os` or `io` instead.

### 3. Lua (Neovim)
- **Modularity**: Keep the configuration modular. Use `require("config.xxx")` for logical blocks (remaps, sets, plugins).
- **Plugin Management**: Use `lazy.nvim` patterns. Add new plugins in `.config/nvim/lua/plugins/` as separate files when possible.
- **Global Variables**: Minimize the use of global variables (`_G`). Use local variables within modules.

### 4. Shell (Bash/Zsh)
- **Modern Tools**: Use `eza` instead of `ls`, `rg` instead of `grep`, `bat` instead of `cat`, `fd` instead of `find`, `sd` instead of `sed`.
- **Aliases**: Prefer descriptive aliases in `.zshrc`. If a new tool is added, add a corresponding alias.
- **Scripting**: Use `set -e` in bash scripts to ensure they exit on error. Use local variables inside functions.

### 5. Documentation
- **Markdown**: Use clear headers, tables, and code blocks.
- **AGENT.md**: Keep the user-facing agent documentation updated when adding new agents or changing their roles.
- **Comments**: Write "why" comments, not "what" comments. The code should be clear enough to explain "what".

---

## 🤖 Agent Interaction Rules

1. **Plan First**: Always use `todowrite` to create a plan before executing complex tasks. Break down the task into small, atomic, and verifiable steps.
2. **Verify**: After modifying files, verify the change. 
   - For Go: `go run main.go` or `go test`.
   - For Shell: Run the script or check with `ls -la`.
   - For Config: `cat` or `bat` the file to ensure the structure is correct.
3. **Git Protocol**:
   - Only commit when requested by the user.
   - Use descriptive commit messages with conventional prefixes (`feat:`, `fix:`, `docs:`, `chore:`, `refactor:`).
   - Never commit secrets. Check `.gitignore` before adding new files.
4. **Tool Selection**: Use modern CLI tools for all operations. 
   - Search: `rg`
   - Find: `fd`
   - Replace: `sd`
   - View: `bat`
   - List: `eza`
5. **No Cowboy Coding**: Do not perform destructive operations without a backup or a clear plan.

---

## 📁 Repository Structure
- `.config/nvim/`: Neovim configuration (Lua).
- `.config/wezterm/`: Terminal emulator config (Lua).
- `.config/opencode/`: AI Agent framework.
  - `builder/`: Go engine for building agents and config.
  - `prompts/`: Modular prompt components.
  - `agent/`: Generated agents (Gitignored).
- `install-tools.sh`: Arch Linux package installation script.
- `starship.toml`: Cross-shell prompt configuration.
- `README.md`: System overview and main documentation.
- `AGENT.md`: User-facing agent roles and workflow descriptions.
- `AGENTS.md`: Technical instructions for AI agents (this file).

---

## 🔍 Search and Exploration
- When searching for code, use `rg` (ripgrep) for content and `fd` for filenames.
- To understand the structure of a directory, use `eza --tree`.
- To read files with syntax highlighting, use `bat`.
