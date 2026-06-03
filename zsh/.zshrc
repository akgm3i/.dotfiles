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


########
# mise #
########
if command -v mise >/dev/null 2>&1; then
    eval "$(mise activate zsh)"
fi


###########
# sheldon #
###########
if command -v sheldon >/dev/null 2>&1; then
    eval "$(sheldon source)"
fi


# load local settings
if [[ -f ${HOME}/.zshrc.local ]]; then
    source ${HOME}/.zshrc.local
fi
