#
# Load fzf's supported Zsh widgets and completion integration.
#

if command -v fzf >/dev/null 2>&1; then
    # Ctrl-T remains reserved for the tmux launcher configured earlier.
    FZF_CTRL_T_COMMAND=
    eval "$(fzf --zsh)"
fi
