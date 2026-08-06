#!/usr/bin/env bash
set -euo pipefail

# Detect OS
OS="$(uname -s)"
case "$OS" in
Linux*)
    PACKAGE_MANAGER="apt"
    ;;
Darwin*)
    PACKAGE_MANAGER="brew"
    ;;
*)
    echo "Unsupported OS: $OS"
    exit 1
    ;;
esac

# ── macOS (Homebrew) ─────────────────────────────────────────────────────────
if [ "$PACKAGE_MANAGER" = "brew" ]; then
    brew update

    # Core tools
    brew install \
        make \
        ripgrep \
        unzip \
        git \
        git-lfs \
        tmux \
        neovim \
        zsh \
        fzf \
        stow \
        zoxide \
        bat \
        btop \
        fd \
        dust \
        gh \
        lazygit \
        yq \
        wget \
        watch \
        gnu-sed \
        pipx \
        atuin

    # Check for Xcode Command Line Tools
    if ! xcode-select -p &>/dev/null; then
        echo "Installing Xcode Command Line Tools..."
        xcode-select --install
        echo "Waiting for Xcode Command Line Tools to be installed..."
        until xcode-select -p &>/dev/null; do sleep 5; done
    fi
    echo "Xcode Command Line Tools detected at $(xcode-select -p)"

    # macOS-only brew formulae
    brew install \
        python@3.10 \
        node \
        gcc \
        pyenv \
        rust \
        git-filter-repo \
        git-sizer \
        opencode

    # Taps + tap formulae
    brew tap acsandmann/tap   # rift
    brew tap modem-dev/tap    # hunk
    brew install acsandmann/tap/rift
    brew install modem-dev/tap/hunk

    # Casks
    brew install --cask \
        ghostty \
        nikitabobko/tap/aerospace \
        vorssaint \
        codex \
        chatgpt \
        gcloud-cli \
        font-jetbrains-mono-nerd-font

    # Cargo tools (requires rust)
    if command -v cargo &>/dev/null; then
        echo "Installing cargo tools..."
        cargo install gg-search   # gg - fast ripgrep alternative
        cargo install tuicr       # code review TUI
    fi

# ── Linux (apt) ──────────────────────────────────────────────────────────────
elif [ "$PACKAGE_MANAGER" = "apt" ]; then
    sudo apt update

    # Bootstrap: ensure curl and add-apt-repository are available
    sudo apt install -y curl software-properties-common

    # Neovim unstable PPA
    sudo add-apt-repository ppa:neovim-ppa/unstable -y || true
    sudo apt update

    # Core tools available in apt repos
    sudo apt install -y \
        make \
        ripgrep \
        unzip \
        git \
        git-lfs \
        tmux \
        neovim \
        zsh \
        fzf \
        stow \
        zoxide \
        bat \
        btop \
        fd-find \
        pipx \
        wget \
        gcc \
        npm \
        xclip \
        python3.10-venv

    # fd-find installs as 'fdfind' -- symlink to 'fd'
    mkdir -p "$HOME/.local/bin"
    ln -sf "$(which fdfind)" "$HOME/.local/bin/fd" 2>/dev/null || true
    # bat may install as 'batcat' on older Ubuntu -- symlink to 'bat'
    ln -sf "$(which batcat)" "$HOME/.local/bin/bat" 2>/dev/null || true

    # ── gh (GitHub CLI) via official apt repo ────────────────────────────────
    if ! command -v gh &>/dev/null; then
        echo "Installing GitHub CLI..."
        sudo mkdir -p -m 755 /etc/apt/keyrings
        wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg \
            | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
        sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
            | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
        sudo apt update && sudo apt install -y gh
    fi

    # ── lazygit from GitHub releases ─────────────────────────────────────────
    if ! command -v lazygit &>/dev/null; then
        echo "Installing lazygit..."
        LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" \
            | grep -Po '"tag_name": *"v\K[^"]*')
        curl -Lo /tmp/lazygit.tar.gz \
            "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_$(uname -m | sed 's/aarch64/arm64/').tar.gz"
        tar xf /tmp/lazygit.tar.gz -C /tmp lazygit
        sudo install /tmp/lazygit /usr/local/bin/lazygit
        rm -f /tmp/lazygit /tmp/lazygit.tar.gz
    fi

    # ── yq from GitHub releases ──────────────────────────────────────────────
    if ! command -v yq &>/dev/null; then
        echo "Installing yq..."
        YQ_ARCH=$(uname -m | sed -e 's/x86_64/amd64/' -e 's/aarch64/arm64/')
        sudo wget -qO /usr/local/bin/yq \
            "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_${YQ_ARCH}"
        sudo chmod +x /usr/local/bin/yq
    fi

    # ── dust from install script ─────────────────────────────────────────────
    if ! command -v dust &>/dev/null; then
        echo "Installing dust..."
        curl -sSfL https://raw.githubusercontent.com/bootandy/dust/refs/heads/master/install.sh | sh
    fi

    # ── atuin via install script ─────────────────────────────────────────────
    if ! command -v atuin &>/dev/null; then
        echo "Installing atuin..."
        curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh
    fi

    # ── Nerd Font (manual download for Linux) ────────────────────────────────
    FONT_DIR="$HOME/.local/share/fonts"
    if [ ! -d "$FONT_DIR/JetBrainsMonoNerdFont" ]; then
        echo "Installing JetBrains Mono Nerd Font..."
        mkdir -p "$FONT_DIR/JetBrainsMonoNerdFont"
        curl -fLo /tmp/JetBrainsMono.tar.xz \
            "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz"
        tar xf /tmp/JetBrainsMono.tar.xz -C "$FONT_DIR/JetBrainsMonoNerdFont"
        fc-cache -fv
        rm -f /tmp/JetBrainsMono.tar.xz
    fi
fi

# ── Clone dotfiles if not exists ─────────────────────────────────────────────
DOTFILES_DIR="${XDG_CONFIG_HOME:-$HOME/dotfiles}"
if [ ! -d "$DOTFILES_DIR/.git" ]; then
    git clone https://github.com/Soyuz0/dotfiles.git "$DOTFILES_DIR"
else
    echo "dotfiles repo already exists."
fi

# ── Stow configuration (must happen before TPM plugin install) ───────────────
cd "$DOTFILES_DIR"
stow .

# ── Clone TPM if not exists ──────────────────────────────────────────────────
TPM_DIR="$HOME/.config/tmux/plugins/tpm"
if [ ! -d "$TPM_DIR" ]; then
    git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
else
    echo "TPM already cloned."
fi

# ── Install tmux plugins (after stow so tmux.conf is in place) ───────────────
echo "Installing tmux plugins..."
"$TPM_DIR/bin/install_plugins" || true

# ── Set zsh as default shell ─────────────────────────────────────────────────
if [ "$SHELL" != "$(which zsh)" ]; then
    ZSH_PATH="$(which zsh)"
    if ! grep -q "$ZSH_PATH" /etc/shells; then
        echo "$ZSH_PATH" | sudo tee -a /etc/shells
    fi
    chsh -s "$ZSH_PATH"
    echo "Zsh set as default shell. You may need to log out and log in again."
else
    echo "Zsh is already the default shell."
fi

# ── Start a new zsh shell ────────────────────────────────────────────────────
ZDOT="$DOTFILES_DIR/.zshrc"
if [ -f "$ZDOT" ]; then
    exec zsh -c "source $ZDOT; exec zsh"
else
    echo "Dotfiles .zshrc not found at $ZDOT"
fi
