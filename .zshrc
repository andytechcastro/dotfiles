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
alias ls='lsd'
alias l='ls -l'
alias la='ls -a'
alias lla='ls -la'
alias lt='ls --tree'
alias t='terraform'
alias home="cd ~"
alias goto="cd -P"
alias ranger='spf'
alias p='. p'
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
# 7. STARTUP LOGIC
# =============================================================================
if [ -z "$NVIM" ]; then
    fastfetch --config /home/andres/.config/fastfetch/config.jsonc --logo-type iterm
fi
