if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

if [[ -f "/opt/homebrew/bin/brew" ]] then
  # If you're using macOS, you'll want this enabled
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Set the directory we want to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# Add in Powerlevel10k
zinit ice depth=1; zinit light romkatv/powerlevel10k

# Add in zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab

# Load completions
autoload -Uz compinit && compinit
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

bindkey -v  # Enable vi mode
bindkey -M viins '^Y' autosuggest-accept
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward

# History
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
setopt hist_find_no_dups
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'

# Aliases
alias ls='ls --color'

# Shell integrations
eval "$(fzf --zsh)" # C-R for fzf history search
eval "$(zoxide init zsh)"

# loacl zshrc
[ -f ~/.zshrc.local ] && source ~/.zshrc.local

# alias
alias la='ls -la'
alias vim='nvim'
alias c='clear'
alias cd='z'
alias cdf='zf'


tcode() {
  local sidebar_bin="$HOME/.config/tmux/plugins/tmux-agent-sidebar/bin/tmux-agent-sidebar"
  if [ -n "$TMUX" ] && [ -x "$sidebar_bin" ]; then
    "$sidebar_bin" toggle "$(tmux display -p '#{window_id}')" "$(pwd)"
  fi
  command opencode "$@"
}

tcc() {
  local sidebar_bin="$HOME/.config/tmux/plugins/tmux-agent-sidebar/bin/tmux-agent-sidebar"
  if [ -n "$TMUX" ] && [ -x "$sidebar_bin" ]; then
    "$sidebar_bin" toggle "$(tmux display -p '#{window_id}')" "$(pwd)"
  fi
  command claude "$@"
}


source ~/.config/scripts/new_session.sh

create_branch() {
  local name="$1"
  local base="${2:-main}"
  local wt="${name//\//_}"
  local branch="ron/$name"

  git --git-dir=deepkeep-sentinel.git worktree add \
    "$wt" \
    -b "$branch" \
    "$base"
}

# Change cursor color
autoload -Uz colors && colors
echo -ne "\e]12;#b39ddb\a"  # Dusty Violet

# Atuin shell history (curl-install puts env in ~/.atuin, brew doesn't need it)
[ -f "$HOME/.atuin/bin/env" ] && . "$HOME/.atuin/bin/env"
eval "$(atuin init zsh)"

# PATH
export PATH="$HOME/.opencode/bin:$HOME/.local/bin:$PATH"
