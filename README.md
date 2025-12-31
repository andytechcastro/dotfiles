# 🔧 Dotfiles de Andrés

Configuración de un entorno de desarrollo **Linux (Arch-based)** optimizado para un Platform Engineer/Golang Developer. Enfocado en productividad, velocidad y minimalismo con integración visual consistente (Catppuccin Mocha).

> **Nota**: Estas configs están pensadas para usar `stow` o un bare git repo para gestionar los symlinks.

---

## 📦 Instalación Rápida

```bash
# Clonar como bare repo
git clone --bare https://github.com/andres/dotfiles.git $HOME/.dotfiles

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

Setup completo con **LazyVim** como base (plugin manager: lazy.nvim).

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
| **CSV** | csv-ls |

#### Plugins Principales:
| Categoría | Plugins |
|-----------|---------|
| **Navegación** | Telescope (fuzzy finder), Harpoon (nav rápida), nvim-tree |
| **Git** | Fugitive, gitsigns, diffview, lazygit |
| **Debug** | dap (DAP), nvim-dap-ui |
| **UI** | lualine, catppuccin, alpha (dashboard), todo-comments |
| **Utilidades** | oil (file manager), toggleterm, undotree, flash, autopairs |
| **Terminal** | toggleterm (integrado en `<C-\>`) |

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
| `Super + D` / `Space` | Launcher DMS |
| `Super + N` | Notificaciones DMS |
| `Super + ,` | Settings DMS |
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

### 8. **OpenCode: Sistema de Agentes IA**

Framework de agentes de IA modular y extensible para Platform Engineering.

> 📄 **Documentación detallada**: Ver [`.config/opencode/README.md`](.config/opencode/README.md) para arquitectura builder, configuración de secretos y MCPs.

#### 🤖 Agentes Disponibles

| Agente | Rol |
|--------|-----|
| **PE_plan** | Arquitecto Estratégico (solo planificación) |
| **PE_build** | Ejecutor Táctico (implementación) |
| **PE** | Ingeniero Full-Stack (consultas generales) |
| **go_architect** | Go Senior (Clean Architecture) |
| **python_architect** | Python Senior (Type Hinting estricto) |

#### 🚀 Despliegue

```bash
# Exporta tus claves (solo las que tengas)
export BRAVE_API_KEY="BSA-xxxxx"

# Regenerar agentes y configs
cd .config/opencode/builder
go run main.go
```

---

## 🚀 Alias y Funciones Útiles

### Alias del Sistema
```bash
alias vim='nvim'
alias ls='exa --icons'
alias ll='exa -lah --icons --git'
alias cat='bat --paging=never'
alias grep='rg'
alias find='fd'
alias cd='z'           # zoxide
alias help='tldr'      # TL;DR pages
alias ranger='spf'     # superfile
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
├── .config/
│   ├── nvim/                   # Neovim (LazyVim style)
│   ├── wezterm/                # WezTerm config
│   ├── hypr/                   # Hyprland + DMS
│   ├── ghostty/                # Ghostty config
│   ├── fastfetch/              # Fastfetch config
│   ├── opencode/               # Sistema de agentes IA (builder + prompts)
│   │   ├── builder/            # Motor Go (inyección de secretos)
│   │   ├── prompts/            # Módulos de prompts
│   │   └── agent/              # Agentes generados (gitignored)
│   └── superfile/              # Superfile themes
└── README.md
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
  exa dust btop ncdu
```

---

## 🤝 Contribuir

¿Ideas de mejora? Forkea, abre un issue o mandame un PR. Pero antes, asegurate de entender **por qué** está configurado así. Sin tutoriales de YouTube, por favor.
