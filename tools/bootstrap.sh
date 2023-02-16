#! /usr/bin/env bash

# Bootstrap script to install dotfiles

# -e: exit on error
# -u: exit on unset variables
set -eu

# Helper functions
log_color() {
    color_code="$1"
    shift

    printf "\033[${color_code}m%s\033[0m\n" "$*" >&2
}

log_red() {
    log_color "0;31" "$@"
}

log_yellow() {
    log_color "0;33" "$@"
}

log_blue() {
    log_color "0;34" "$@"
}

log_task() {
    log_blue "$@"
}

log_manual_action() {
    log_yellow "$@"
}

log_error() {
    log_red "$@"
}

error() {
    log_error "$@"
    exit 1
}

sudo() {
  # shellcheck disable=SC2312
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
    else
        if ! command sudo --non-interactive true 2>/dev/null; then
            log_manual_action "Permission required, please enter your password below"
            command sudo --validate
        fi
        command sudo "$@"
    fi
}

git_clean() {
    path=$(realpath "$1")
    remote="$2"
    branch="$3"

    log_task "Cleaning '${path}' with '${remote}' at branch '${branch}'"
    git="git -C ${path}"
    ${git} checkout -B "${branch}"
    ${git} fetch "${remote}" "${branch}"
    ${git} reset --hard FETCH_HEAD
    ${git} clean -fdx
    unset path remote branch git
}

# Install the god-shell and basic utilities
sudo apt install -y \
    zsh \
    curl \
    wget \
    neovim \
    git \
    tree \
    ranger \
    nnn \
    ncdu \
    tmux \
    ca-certificates \
    lsb-release \
    gnupg

DOTFILES_REPO_HOST=${DOTFILES_REPO_HOST:-"https://github.com"}
DOTFILES_USER=${DOTFILES_USER:-"diego-andersen"}
DOTFILES_REPO="${DOTFILES_REPO_HOST}/${DOTFILES_USER}/dotfiles-work"
DOTFILES_BRANCH=${DOTFILES_BRANCH:-"master"}
DOTFILES_DIR="$HOME/.dotfiles"
DOTFILES_USER_EMAIL=${DOTFILES_USER_EMAIL:-diego.andersen@protonmail.com}
DOTFILES_USER_NAME=${DOTFILES_USER_NAME:-"Diego Andersen"}

if [ -d "${DOTFILES_DIR}" ]; then
    git_clean "${DOTFILES_DIR}" "${DOTFILES_REPO}" "${DOTFILES_BRANCH}"
else
    log_task "Cloning '${DOTFILES_REPO}' at branch '${DOTFILES_BRANCH}' to '${DOTFILES_DIR}'"
    git clone --bare --branch "${DOTFILES_BRANCH}" "${DOTFILES_REPO}" "${DOTFILES_DIR}"
    dotfiles="git --git-dir=$DOTFILES_DIR --work-tree=$HOME"
    $dotfiles checkout
    $dotfiles config --local status.showUntrackedFiles no
    $dotfiles config --local user.email $DOTFILES_USER_EMAIL
    $dotfiles config --local user.name $DOTFILES_USER_NAME
fi

# Overwrite global zshenv
log_task "Updating /etc/zsh/zshenv"
sudo cp $HOME/.config/zsh/zshenv /etc/zsh/zshenv
sudo chown root:root /etc/zsh/zshenv
sudo chmod 644 /etc/zsh/zshenv

# Set zshenv variables here to keep this script POSIX-compliant
# as /etc/zsh/zshenv contains [[ ... ]] conditionals
export ZDOTDIR="$HOME/.config/zsh"
export HISTFILE="$HOME/.local/share/zsh/history"

# Make histfile parent directory because zsh won't
if [ ! -z "$HISTFILE" ]; then
    log_task "Creating \$HISTFILE parent directory: ${HISTFILE%/*}"
    mkdir -p "${HISTFILE%/*}"
fi

# Add ssh key to machine if provided
SSH_KEY=${SSH_KEY:-$HOME/id_rsa.pub}

if [ -f "$SSH_KEY" ]; then
    log_task "Creating ~/.ssh"
    mkdir -p $HOME/.ssh
    log_task "Adding $SSH_KEY to $HOME/.ssh/authorized_keys"
    cat "$SSH_KEY" >> $HOME/.ssh/authorized_keys
    log_task "Deleting $SSH_KEY"
    rm $SSH_KEY
fi

# Install vim-plug & plugins
log_task "Pimping out neovim"
sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim \
    --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

nvim -es -u $HOME/.config/nvim/bootstrap.vim -i NONE +PlugInstall +qa

# Install oh-my-zsh
log_task "Installing oh-my-zsh"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc

# Install Spaceship prompt
log_task "Installing Spaceship prompt"
git clone https://github.com/spaceship-prompt/spaceship-prompt.git \
    "${ZSH_CUSTOM:="$ZDOTDIR/ohmyzsh/custom"}/themes/spaceship-prompt" --depth=1

ln -s "$ZSH_CUSTOM/themes/spaceship-prompt/spaceship.zsh-theme" \
    "$ZSH_CUSTOM/themes/spaceship.zsh-theme"

log_task "Switching default shell to zsh"
sudo chsh -s $(command -v zsh) $USER
