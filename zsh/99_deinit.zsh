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

# The local system summary is disabled by default. Run `motd` explicitly, or
# opt in to displaying it during interactive startup.
if [[ -o interactive && "${DOTFILES_MOTD_ON_START:-0}" == 1 ]] \
    && (( $+commands[motd] || $+functions[motd] )); then
    motd
fi
