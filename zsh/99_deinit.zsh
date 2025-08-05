#
# deinitialize.
#

# Source any secret files.
()
{
    local f
    for f in ./*secret*.zsh(N-.)
    do
        source "$f"
    done
}

#
# Display a spider ASCII art on exit, if the terminal is large enough.
#
if [[ -o interactive ]]; then
    source "${0:A:h}/motd.zsh"
fi
