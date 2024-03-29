#
# Defines keybinds.
#

# Vim-like keybind as default
bindkey -v

# Vim-like escaping jj keybind
bindkey -M viins 'jj' vi-cmd-mode

bindkey -M viins '^A'  beginning-of-line
bindkey -M viins '^E'  end-of-line

bindkey '^R' _fuzzy-select-history

if ! is_tmux_runnning; then
    bindkey '^T' _start-tmux
fi

# Ctrl-R
# fuzzy history search
_fuzzy-select-history() {
    BUFFER="$(
    history 1 \
        | sort -k1,1nr \
        | perl -ne 'BEGIN { my @lines = (); } s/^\s*\d+\s*//; $in=$_; if (!(grep {$in eq $_} @lines)) { push(@lines, $in); print $in; }' \
        | fzf --query "$LBUFFER"
    )"

    CURSOR=$#BUFFER
    zle reset-prompt
}
zle -N _fuzzy-select-history

_start-tmux() {
    BUFFER="tmux -f $XDG_CONFIG_HOME/tmux/tmux.conf"
    CURSOR=$#BUFFER
    zle accept-line
}
zle -N _start-tmux
