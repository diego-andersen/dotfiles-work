# Fix $PATH
export PATH=$HOME/bin:$PATH

# Don't use oh-my-zsh on TTY (.psf fonts can't render most things)
if [ "$TERM" != "linux" ]; then
    # Path to oh-my-zsh installation.
    export ZSH="$ZDOTDIR/ohmyzsh"

    # Oh-my-zsh theme
    ZSH_THEME="spaceship"
    source $ZDOTDIR/spaceship.zsh

    # Plugins
    plugins=(
        gitfast
        virtualenv
    )

    source $ZSH/oh-my-zsh.sh
fi

# History
HISTSIZE=5000
SAVEHIST=5000
setopt SHARE_HISTORY
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
setopt HIST_IGNORE_DUPS

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR=nvim
else
  export EDITOR=nvim
fi

export BAT_THEME=ansi

# Aliases
source $ZDOTDIR/aliases

# Env variables
source $ZDOTDIR/env_variables
