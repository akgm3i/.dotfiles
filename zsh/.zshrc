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

eval "$(sheldon source)"

if [[ ! -f $ZINIT[BIN_DIR]/zinit.zsh ]]; then
    print -P "%F{33}▓▒░ %F{220}Installing DHARMA Initiative Plugin Manager (zdharma/zinit)…%f"
    command mkdir -p $ZINIT[HOME_DIR] && command chmod g-rwX $ZINIT[HOME_DIR]
    command git clone https://github.com/zdharma-continuum/zinit $ZINIT[BIN_DIR] && \
        print -P "%F{33}▓▒░ %F{34}Installation successful.%f%b" || \
        print -P "%F{160}▓▒░ The clone has failed.%f%b"
fi

source $ZINIT[BIN_DIR]/zinit.zsh
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

source $ZDOTDIR/zinit_load.zsh


# load local settings
if [[ -f ~/.zshrc.local ]]; then
    source ~/.zshrc.local
fi
