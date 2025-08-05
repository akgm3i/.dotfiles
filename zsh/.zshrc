#
# Executes commands at the start of an interactive session.
#

# default permission
umask 022

# no dump core file
limit coredumpsize 0

# Return if zsh is called from Vim
if [[ -n $VIMRUNTIME ]]; then
    return 0
fi


# tmux_automatically_attach attachs tmux session
# automatically when your are in zsh
# $DOTPATH/bin/tmuxx

# activate sheldon
eval "$(sheldon source)"

# activate mise
eval "$(mise activate zsh)"


# load local settings
if [[ -f ~/.zshrc.local ]]; then
    source ~/.zshrc.local
fi
