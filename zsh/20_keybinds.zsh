#
# Defines keybinds.
#

# Vim-like keybind as default
bindkey -v

# Vim-like escaping jj keybind
bindkey -M viins 'jj' vi-cmd-mode

bindkey -M viins '^A'  beginning-of-line
bindkey -M viins '^E'  end-of-line

_start-tmux() {
    BUFFER="tmux -f $XDG_CONFIG_HOME/tmux/tmux.conf"
    CURSOR=$#BUFFER
    zle accept-line
}
zle -N _start-tmux

if [[ -z ${TMUX:-} ]]; then
    bindkey '^T' _start-tmux
fi
