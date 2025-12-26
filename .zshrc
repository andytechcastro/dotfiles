# =============================================================================
# 1. ZSH CONFIGURATION & PLUGINS
# =============================================================================
export ZSH="/home/andres/.oh-my-zsh"

# Plugins
plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-completions k)

source $ZSH/oh-my-zsh.sh

# =============================================================================
# 2. ENVIRONMENT VARIABLES
# =============================================================================
export LANG=en_US.UTF-8
export VISUAL=/usr/bin/nvim
export EDITOR=/usr/bin/nvim
export CLOUDSDK_PYTHON=/usr/bin/python3.8
export USE_GKE_GCLOUD_AUTH_PLUGIN=True

# Load secrets if they exist
[[ -f ~/.secret_envs ]] && source ~/.secret_envs

# =============================================================================
# 3. PATH CONFIGURATION
# =============================================================================
export GOPATH=$HOME/go

# Append to PATH (Clean and consolidated)
export PATH="${PATH}:${HOME}/.krew/bin"
export PATH="${PATH}:$(go env GOPATH)/bin"
export PATH="${PATH}:/snap/bin"
export PATH="${PATH}:${HOME}/.local/bin"

if [ -d "$HOME/.bookmarks" ]; then
    export CDPATH=".:$HOME/.bookmarks:/"
fi

# =============================================================================
# 4. TOOL INITIALIZATION & COMPLETIONS
# =============================================================================

# Starship (Prompt)
eval "$(starship init zsh)"

# Zoxide (Smart cd)
eval "$(zoxide init zsh)"

# Atuin (Shell history)
eval "$(atuin init zsh)"

# Broot (File manager)
source /home/andres/.config/broot/launcher/bash/br

# Google Cloud SDK
if [ -f '/home/andres/servicios/google-cloud-sdk/path.zsh.inc' ]; then 
    . '/home/andres/servicios/google-cloud-sdk/path.zsh.inc'
fi
if [ -f '/home/andres/servicios/google-cloud-sdk/completion.zsh.inc' ]; then 
    . '/home/andres/servicios/google-cloud-sdk/completion.zsh.inc'
fi

# Completions Setup
autoload -Uz compinit && compinit
autoload -U +X bashcompinit && bashcompinit

# Terraform
complete -o nospace -C /usr/bin/terraform terraform

# Kubectl
source <(kubectl completion zsh)

# WezTerm
if command -v wezterm > /dev/null 2>&1; then
  source <(wezterm shell-completion --shell zsh)
fi

# Custom completions
_op() {
    compadd Acreditaciones taskManager/taskManager taskManager/infra brewery
}
compdef _op op
compdef _op p

# =============================================================================
# 5. ALIASES
# =============================================================================
# System & Tools
alias vim='nvim'
alias ls='exa --icons'
alias ll='exa -lah --icons --git'
alias t='terraform'
alias home="cd ~"
alias goto="cd -P"
alias ranger='spf'
alias p='. p'
alias cat='bat --paging=never'
alias grep='rg'
alias find='fd'
alias cd='z'
alias help='tldr'
alias dotfiles='/usr/bin/git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME"'

# Git Aliases
alias gstatus="git status"
alias gadd="git add"
alias gcommit="git commit -m"
alias gpush="git push origin"
alias gcheck="git checkout"
alias gpull="git pull origin"
alias gbranch="git branch"

# =============================================================================
# 6. FUNCTIONS
# =============================================================================
spf() {
    os=$(uname -s)
    local SPF_LAST_DIR=""

    if [[ "$os" == "Linux" ]]; then
        SPF_LAST_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/superfile/lastdir"
    elif [[ "$os" == "Darwin" ]]; then
        SPF_LAST_DIR="$HOME/Library/Application Support/superfile/lastdir"
    fi

    command spf "$@"

    [ ! -f "$SPF_LAST_DIR" ] || {
        . "$SPF_LAST_DIR"
        rm -f -- "$SPF_LAST_DIR" > /dev/null
    }
}

# =============================================================================
# 7. STARTUP LOGIC (TMUX + FASTFETCH)
# =============================================================================
if [[ "$TERM_PROGRAM" == "WezTerm" ]]; then
    # Si es WezTerm: NO ejecutar Tmux, SI ejecutar Fastfetch con logo iterm
    if [ -f "/home/andres/.config/fastfetch/config.jsonc" ]; then
        fastfetch --config /home/andres/.config/fastfetch/config.jsonc --logo-type iterm
    else
        fastfetch
    fi
elif [[ -z "$TMUX" ]]; then
    # Si NO estamos en Tmux y NO es WezTerm...
    if [[ "$TERM_PROGRAM" != "vscode" && -n "$PS1" ]]; then
        exec tmux new-session
    fi
else
    # Si ESTAMOS dentro de Tmux (y no es WezTerm) -> Mostrar Fastfetch estándar
    if [ -f "/home/andres/.config/fastfetch/config.jsonc" ]; then
       fastfetch --config /home/andres/.config/fastfetch/config.jsonc --logo-type kitty-icat
    else
       fastfetch
    fi
fi
