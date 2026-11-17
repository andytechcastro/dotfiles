# 🔧 Dotfiles de Andrés

Configuración de un entorno de desarrollo **Linux (Arch-based)** optimizado para un Platform Engineer/Golang Developer. Enfocado en productividad, velocidad y minimalismo con integración visual consistente (Catppuccin Mocha).

> **Nota**: Estas configs están pensadas para usar un **bare git repo** para gestionar los symlinks.

---

## 📦 Instalación Rápida

```bash
# Clonar como bare repo
git clone --bare https://github.com/andytechcastro/dotfiles.git $HOME/.dotfiles

# Definir alias para gestión
alias dotfiles='/usr/bin/git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME"'

# Checkout del contenido
dotfiles checkout

# Instalar herramientas esenciales (Arch/Manjaro)
./install-tools.sh
```

---

## 🖥️ Componentes del Sistema

### 1. **Shell: Zsh + Oh My Zsh**

| Componente | Descripción |
|------------|-------------|
| **Oh My Zsh** | Framework base |
| **zsh-autosuggestions** | Autocompletado predictivo |
| **zsh-syntax-highlighting** | Resaltado de sintaxis |
| **zsh-completions** | Completados avanzados |
| **k** | Alternativa rápida a `ls` (usa `eza` internamente) |

**Archivo**: `.zshrc`

### 2. **Terminal: WezTerm + Ghostty**

| Terminal | Uso |
|----------|-----|
| **WezTerm** | Terminal principal (Wayland native, configurable) |
| **Ghostty** | Alternativa rápida (GTK4, muy performante) |

#### WezTerm Highlights:
- **Scheme**: Catppuccin Mocha
- **Font**: FiraCode Nerd Font + JetBrains Mono
- **Leader Key**: `Ctrl+b` (estilo tmux)
- **Keybindings principales**:
  - `Leader + Ctrl + h/j/k/l`: Split panes
  - `Leader + c/n/p`: Gestion de tabs
  - `Leader + s/w`: Workspaces (fuzzy finder)
- **Tabs estilo burbujas** con iconos dinámicos (vim, git, etc.)

**Archivo**: `.config/wezterm/wezterm.lua`

#### Ghostty Highlights:
- Tema Catppuccin Mocha
- Window decorations desactivadas
- Shell integration con Zsh

**Archivo**: `.config/ghostty/config`

### 3. **Multiplexor: Tmux**

| Plugin | Función |
|--------|---------|
| **tpm** | Plugin manager |
| **tmux-sensible** | Configuración sensata |
| **vim-tmux-navigator** | Navegación seamless vim/tmux |
| **catppuccin/tmux** | Tema |
| **tmux-yank** | Copiar al clipboard del sistema |
| **tmux-cpu** | Monitor CPU en status bar |
| **tmux-battery** | Monitor batería en status bar |

**Keybindings**:
- `Prefix + r`: Recargar config
- `Prefix + h/j/k/l`: Navegar panes
- `Ctrl + h/j/k/l`: Splits direccionales (estilo vim)

**Archivo**: `.tmux.conf`

### 4. **Editor: Neovim**

Setup modular con **lazy.nvim** como plugin manager.

#### LSPs Configurados:
| Lenguaje | LSP |
|----------|-----|
| **Go** | gopls (con go.nvim/crates.nvim) |
| **Rust** | rust-analyzer (rustaceanvim) |
| **TypeScript/JS** | ts_ls |
| **Lua** | lua_ls |
| **Python** | pyright |
| **YAML/JSON** | yamlls/jsonls |
| **SQL** | sqlls |
| **CSV** | rainbow_csv.nvim (coloreado por columnas) |

#### Plugins Principales:
| Categoría | Plugins |
|-----------|---------|
| **Navegación** | Telescope (fuzzy finder), Harpoon (nav rápida), Snacks Explorer |
| **Git** | Fugitive, gitsigns, diffview, lazygit |
| **Debug** | dap (DAP), nvim-dap-ui |
| **UI** | lualine, catppuccin, todo-comments, whichkey |
| **Utilidades** | oil (file manager), undotree, flash, autopairs, smart-splits, fidget (LSP progress), lazydev (Lua types) |
| **Terminal** | Snacks Terminal (integrado) |

#### Comandos Personalizados:
| Comando | Función |
|---------|---------|
| `:GraphifyUpdate` | Actualiza el knowledge graph |
| `:HexCheck` | Verifica arquitectura hexagonal |
| `:OpenCodeBuild` | Reconstruye configuración OpenCode |
| `:MasonInstallEssentials` | Instala todas las herramientas Mason de una vez |

**Archivo**: `.config/nvim/init.lua` y subdirectorios

### 5. **Window Manager: Hyprland + Dank Material Shell**

| Componente | Descripción |
|------------|-------------|
| **Hyprland** | Compositor Wayland |
| **Dank Material Shell** | Shell/material design overlay |

#### Keybindings Hyprland:
| Atajo | Acción |
|-------|--------|
| `Super + Return` | Abrir WezTerm |
| `Super + E` | Thunar (file manager) |
| `Super + D` / `Space` | Launcher DUX |
| `Super + N` | Notificaciones DUX |
| `Super + ,` | Settings DUX |
| `Super + J` | Toggle split |
| `Super + V` | Floating window |
| `Super + Shift + Q` | Cerrar ventana |
| `Super + 1-9` | Workspaces |

**Archivos**:
- `.config/hypr/hyprland.conf`
- `.config/hypr/monitors.conf`
- `.config/hypr/workspaces.conf`

### 6. **Prompt: Starship**

Prompt minimalista escrito en Rust.

**Nota**: Configuración en archivo `starship.toml` (no incluido en repo, configurar vía `starship preset ...`)

### 7. **Utilidades CLI**

| Herramienta | Uso |
|-------------|-----|
| **zoxide** | `cd` inteligente (aprende tus directorios) |
| **atuin** | History universal con sync |
| **broot** | File manager CLI (alias: `br`) |
| **superfile** | File manager TUI moderno (alias: `spf`) |
| **eza** | Reemplazo de `ls` con icons |
| **bat** | Reemplazo de `cat` con sintaxis |
| **rg** | grep optimizado (ripgrep) |
| **fd** | find optimizado |
| **sd** | sed optimizado |
| **fastfetch** | Neofetch más rápido |
| **lazygit** | TUI para Git |
| **btop** | Monitor de sistema |
| **jless** | Visor de JSON interactivo |
| **squeez** | Compresión de output (95% reducción tokens) |
| **codebase-memory-mcp** | Knowledge graph del codebase |

### 8. **OpenCode: Sistema de Agentes IA**

Framework de agentes de IA modular y extensible para Platform Engineering, con modelo de permisos **Deny-First** y **Model Profiles** para cambiar de proveedor sin tocar templates.

> 📄 **Documentación detallada**: Ver [`AGENTS.md`](AGENTS.md) para arquitectura builder, configuración de secretos, MCPs y protocolo de agentes.

#### 🤖 Agentes Disponibles

| Agente | Modelo (perfil `opencodego`, compilado) | Rol |
|--------|------------------------------------------|-----|
| **commander** | `opencode-go/qwen3.8-flash` | Orquestador principal. Planifica, delega y verifica. |
| **PE** | `opencode-go/qwen3.8-flash` | Platform Engineer. IaC, K8s, CI/CD, infra. |
| **go_architect** | `opencode-go/qwen3.8-flash` | Go Senior. Clean Architecture, SOLID. |
| **python_architect** | `opencode-go/qwen3.8-flash` | Python Senior. Type-safe, modern Python. |
| **frontend_architect** | `opencode-go/qwen3.8-flash` | UX/UI + Frontend. Next.js 15, React 19. |
| **qa_architect** | `opencode-go/qwen3.8-flash` | QA SDET. Regression, E2E, performance. |
| **security_architect** | `opencode-go/qwen3.8-flash` | Security Auditor. IaC, secrets, vulnerabilidades. |
| **doc_architect** | `opencode-go/qwen3.8-flash` | Documentation Architect. Spec audit, ADRs, graphify. |
| **7 agentes personales** — sensibles: `finanzas`, `life`, `coach` · factuales: `barista`, `chef`, `organiza`, `habitos` | `opencode-go/gemini-4-argon#medium` (×3) · `opencode-go/gpt-6-luna` (`#medium` chef, `#none` barista, `#low` habitos) · `opencode-go/mimo-v2.6-flash` pelado (organiza) | Agentes primarios de uso personal, sin shell. **Todos por el gateway `opencode-go` desde 2026-11-17 (ADR 0008)**: un solo proveedor, una sola factura. El `#variant` selecciona latencia/profundidad, no coste. `organiza` va **sin sufijo** — `mimo-v2.6-flash` no expone variantes; cualquier sufijo da `provider.no-route`. |

> **2026-11-15:** los perfiles `google` y `gemini` fueron **eliminados** (seleccionarlos aborta el
> build en `oc`). Existe **un único perfil**, `opencodego`.
> **2026-11-17 (ADR 0008):** el roster **ya no es mixto** — los 15 agentes, técnicos y personales,
> resuelven por el gateway `opencode-go`; los 7 personales usan la sintaxis V2
> `provider/model#variant`. El provider `google` nativo con `GEMINI_API_KEY` queda **configurado
> pero sin consumo**, como camino documentado de rollback. Verdad contrastada en
> [`AGENTS.md`](AGENTS.md) → **Model Profiles** y **Model Providers**.

#### 🔌 MCPs Integrados

| MCP | Propósito |
|-----|-----------|
| **context7** | Documentación actualizada de librerías/frameworks |
| **engram** | Memoria persistente local (SQLite) |
| **gh_grep** | Búsqueda semántica en GitHub |
| **gcp** | Google Cloud Platform (OAuth) |
| **codebase-memory-mcp** | Knowledge graph del codebase (tree-sitter + SQLite) |

#### 🧩 Plugins OpenCode

| Plugin | Función |
|--------|---------|
| **opencode-gemini-auth** | Autenticación Gemini |
| **opencode-claude-auth** | Autenticación Claude |
| **opencode-snippets** | Expansión de snippets con `#hashtag` |
| **opencode-notify** | Notificaciones del sistema |
| **envsitter-guard** | Protección de archivos .env |
| **@ykaratkou/opencode-worktree** | Gestión de git worktrees |
| **@tarquinen/opencode-dcp** | Context pruning dinámico |
| **opencode-autotitle** | Generación automática de títulos |
| **opencode-vibeguard** | Redacción de secrets (HMAC-SHA256) |
| **@plannotator/opencode** | UI en navegador para planes |
| **@nick-vi/opencode-type-inject** | Inyección automática de tipos TS |
| **squeez** | Compresión de output (95% reducción tokens) |

#### 🔄 Model Profiles

Los modelos no están hardcodeados. Se gestionan via `model_profiles.json`:

```bash
# Único perfil existente (opencodego) — default
cd .config/opencode/builder && go run main.go

# Override temporal (el nombre del perfil, no el proveedor)
MODEL_PROFILE=opencodego go run main.go
```

> ⚠️ `MODEL_PROFILE=gemini` / `=google` **ya no existen**: el wrapper `oc` aborta con
> `Profile '<name>' not found. Available: opencodego`. Desde 2026-11-17 (ADR 0008) **no hay roster
> mixto**: los 15 agentes son `opencode-go` (técnicos en `qwen3.8-flash`; personales en
> `gemini-4-argon#medium` ×3, `gpt-6-luna#*` ×3, `mimo-v2.6-flash` pelado ×1) — se
> cambia editando valores de `model_profiles.json`, no creando perfiles. **Paridad de versión —
> medida y cumplida (2026-11-17):** opencode 2.2.5 (homesrv/Pi) y 2.3.0 (portátil) resuelven el
> sufijo `#variant` de forma idéntica, y **el Pi ya está sincronizado y verificado** (15 `agent/*.md`
> sin `google/`, turno real de `finanzas` OK, `variant=medium` leído de su propia DB). La regla se
> mantiene para SUFJOS FUTUROS: no sincronices un artefacto a un nodo sin comprobar antes que su
> binario lo entiende. Ojo: en 2.2.5 un frontmatter roto (`model:` → null) **hace desaparecer el
> agente sin ningún aviso** — no hay log que leer; se detecta contando agentes o probando un turno.

#### 🧠 Memoria Persistente (Engram)

Sistema de memoria local SQLite con protocolo **Ask-First**:
- El agente **propone** memorias, el usuario **aprueba** o rechaza.
- Review batch obligatorio al cerrar sesión.
- Trigger manual: "guarda esto" → guarda inmediatamente.
- Todo queda en `~/.engram/engram.db`. Sin cloud.
- Nuevas herramientas: `mem_suggest_topic_key`, `mem_judge`, `mem_capture_passive`

#### 🔐 Modelo de Permisos (Deny-First)

- **Commander**: Acceso total a bash (excepto comandos destructivos: `rm -rf /`, `mkfs*`, `dd *`, etc.).
- **Sub-Agentes**: Pueden leer, editar, compilar y testear. **NO** pueden:
  - Escribir en Git (`add`, `commit`, `push`, `pull`, etc.)
  - Hacer llamadas a la red (`curl`, `wget`, `nc`)
  - Acceder a seguridad del SO (`security`, `sysctl`)

Formato inline con comentarios por sección en los templates:
```yaml
bash:
  # --- Destructive operations (ALWAYS DENY) ---
  "rm -rf /": deny
  "dd *": deny
  # --- Sub-agents get full access to everything else ---
  "*": allow
```

#### 🚀 Despliegue

```bash
# Exporta tus claves (solo las que tengas)
export BRAVE_API_KEY="BSA-xxxxx"

# Regenerar agentes y configs (default: opencodego)
cd .config/opencode/builder
go run main.go

# O usar el wrapper
oc --rebuild

# (MODEL_PROFILE solo acepta `opencodego` — los perfiles `gemini`/`google` fueron
#  ELIMINADOS 2026-11-15; usarlos aborta: `Profile 'gemini' not found.
#  Available: opencodego`. El roster personal cambia por VALORES de
#  `model_profiles.json`, no por perfiles — ver ADR 0008.)
```

---

## 🚀 Alias y Funciones Útiles

### Alias del Sistema
```bash
alias vim='nvim'
alias ls='eza --icons'
alias ll='eza -lah --icons --git'
alias cat='bat --paging=never'
alias grep='rg'
alias find='fd'
alias cd='z'           # zoxide
alias help='tldr'      # TL;DR pages
alias ranger='spf'     # superfile
alias curl='xh'
alias jq='jaq'
alias top='btm'
alias ps='procs'
alias du='dust'
```

### Alias Git
```bash
alias gstatus="git status"
alias gadd="git add"
alias gcommit="git commit -m"
alias gpush="git push origin"
alias gcheck="git checkout"
```

### Funciones Personalizadas
```bash
# Navegación automática con superfile
spf() {
    # Mantiene el directorio actual después de cerrar superfile
    command spf "$@"
    [ -f "$XDG_STATE_HOME/superfile/lastdir" ] && . "$XDG_STATE_HOME/superfile/lastdir"
}
```

---

## ⌨️ Atajos de Teclado Consolidados

### Terminal (WezTerm)
| Atajo | Acción |
|-------|--------|
| `Ctrl+b h/j/k/l` | Navegar panes (vim-style) |
| `Ctrl+b Ctrl+h/j/k/l` | Crear splits |
| `Ctrl+b c` | Nueva tab |
| `Ctrl+b n/p` | Siguiente/anterior tab |
| `Ctrl+b s/w` | Fuzzy workspaces |
| `Ctrl+b z` | Zoom pane |
| `Ctrl+b x` | Cerrar pane |

### Neovim
| Atajo | Acción |
|-------|--------|
| `<Space>` | Whichkey trigger |
| `<C-\>` | Toggle terminal |
| `<Leader>ff` | Telescope find files |
| `<Leader>fg` | Telescope live grep |
| `<Leader>fb` | Telescope buffers |
| `<Leader>fh` | Harpoon marks |
| `<Leader>tt` | Toggle trouble |
| `<Leader>tp` | Toggle Telescope projects |
| `<TAB>` | Snacks Explorer (file tree) |
| `-` | Oil (file manager) |
| `<Leader>og` | Graphify Update |
| `<Leader>oh` | Hexagonal Check |
| `<Leader>ob` | OpenCode Build |
| `:MasonInstallEssentials` | Instala herramientas Mason |

### Hyprland
| Atajo | Acción |
|-------|--------|
| `Super + h/j/k/l` | Mover foco |
| `Super + Shift + h/j/k/l` | Mover ventana |
| `Super + 1-9` | Workspace |
| `Super + Shift + 1-9` | Mover a workspace |
| `Super + Return` | Terminal |
| `Super + D` | Launcher |

---

## 🎨 Temas Visuales

- **Catppuccin Mocha**: Unifies color scheme across Neovim, Tmux, WezTerm, Ghostty, Hyprland
- **Font**: FiraCode Nerd Font (ligatures enabled)
- **Icons**: Nerd Fonts completos

---

## 📁 Estructura del Repo

```
dotfiles/
├── .zshrc                      # Shell config
├── .tmux.conf                  # Tmux config
├── .gitignore
├── install-tools.sh            # Script instalación Arch
├── starship.toml               # Starship config
├── README.md
├── AGENTS.md                   # Guía técnica para agentes IA
├── .config/
│   ├── nvim/                   # Neovim (lazy.nvim style)
│   ├── wezterm/                # WezTerm config
│   ├── hypr/                   # Hyprland + DUX
│   ├── ghostty/                # Ghostty config
│   ├── fastfetch/              # Fastfetch config
│   ├── opencode/               # Sistema de agentes IA
│   │   ├── builder/            # Motor Go (inyección de secretos + model profiles)
│   │   │   ├── main.go         # Builder engine
│   │   │   └── templates/      # SOURCE OF TRUTH
│   │   │       ├── agent/      # Agent templates ({{MODEL:xxx}} placeholders)
│   │   │       ├── config/     # Config template (${VAR} + _requires_env)
│   │   │       └── model_profiles.json # Perfiles de modelos (único: opencodego — `google`/`gemini` eliminados 2026-11-15)
│   │   ├── prompts/            # Módulos de prompts reutilizables (22 archivos)
│   │   │   ├── behavior.md     # Reglas compartidas (no yes-man, planning)
│   │   │   ├── commander_*.md  # Identity + behavior del Commander
│   │   │   ├── engram_memory.md # Protocolo Ask-First de memoria
│   │   │   ├── glossary.md     # Glosario de arquitectura
│   │   │   ├── _installed_capabilities.md # Lista de capacidades instaladas
│   │   │   ├── _subagent_permissions.md   # Permisos centralizados
│   │   ├── plugins/            # Plugins OpenCode (engram.ts, squeez.js, graphify.js)
│   │   ├── squeez/             # Squeez configuration (compresión de output)
│   │   │   └── config.ini      # Compression settings (persona: ultra)
│   │   ├── tool/               # Herramientas platform (TS/Go)
│   │   ├── skill/              # Skills on-demand
│   │   ├── command/            # Slash commands personalizados (trackeados)
│   │   │                       #   commands/ (plural) = salida del installer de Plannotator, gitignored
│   │   └── agent/              # Agentes generados (gitignored)
│   └── superfile/              # Superfile themes
└── graphify-out/               # Knowledge graph del proyecto
```

---

## 🛠️ Requisitos de Instalación

```bash
# Arch Linux / Manjaro
yay -S --needed \
  zsh oh-my-zsh zsh-autosuggestions zsh-syntax-highlighting zsh-completions \
  wezterm ghostty tmux \
  neovim lazygit \
  hyprland dank-material-shell \
  eza bat rg fd sd zoxide atuin broot superfile fastfetch tldr \
  fzf ripgrep \
  dust btop ncdu \
  xh jaq bottom procs jless \
  engram-bin graphify squeez codebase-memory-mcp
```

---

## 🤝 Contribuir

¿Ideas de mejora? Forkea, abre un issue o mandame un PR. Pero antes, asegurate de entender **por qué** está configurado así. Sin tutoriales de YouTube, por favor.
