#
# deinitialize.
#

# Source any secret files.
()
{
    local f secret_dir
    secret_dir="${ZDOTDIR:-${DOTPATH:-$HOME/.dotfiles}/zsh}"
    for f in "${secret_dir}"/*secret*.zsh(N-.)
    do
        source "$f"
    done
}

#
# Display a spider ASCII art on exit, if the terminal is large enough.
#
if [[ -o interactive ]]; then
    motd
fi
