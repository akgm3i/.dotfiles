#
# Executes commands at the start of an interactive session.
#

# default permission
umask 022

# no dump core file
limit coredumpsize 0

# Return if zsh is called from Vim
if [[ -n ${VIMRUNTIME} ]]; then
    return 0
fi


# tmux_automatically_attach attachs tmux session
# automatically when your are in zsh
# $DOTPATH/bin/tmuxx

###########
# sheldon #
###########
if [[ ! -x ${HOME}/.local/bin/sheldon ]]; then
    # Install sheldon if not found
    echo "sheldon not found. Installing..."
    curl --proto '=https' -fLsS https://rossmacarthur.github.io/install/crate.sh \
        | bash -s -- --repo rossmacarthur/sheldon --to "${HOME}/.local/bin"
    echo "sheldon installed."
fi

# activate sheldon
eval "$(sheldon source)"

########
# mise #
########
if [[ ! -f ${HOME}/.local/bin/mise ]]; then
    # Install mise if not found
    echo "mise not found. Installing..."
    curl https://mise.run | sh
    echo "mise installed."
fi
# activate mise
eval "$(mise activate zsh)"


# load local settings
if [[ -f ${HOME}/.zshrc.local ]]; then
    source ${HOME}/.zshrc.local
fi
