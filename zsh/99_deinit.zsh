#
# deinitialize.
#

# Load local secrets from outside the repository.
()
{
    local secret_file="${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/secrets.zsh"
    local legacy_dir="${ZDOTDIR:-${DOTPATH:-$HOME/.dotfiles}/zsh}"
    local -a legacy_files
    local -A secret_stat

    legacy_files=("${legacy_dir}"/*secret*.zsh(N-.))
    if (( ${#legacy_files} > 0 )); then
        print -ru2 -- \
            "dotfiles: repository-local secret files are no longer loaded; move them to $secret_file"
    fi

    [[ -e "$secret_file" || -L "$secret_file" ]] || return

    if [[ -L "$secret_file" || ! -f "$secret_file" ]]; then
        print -ru2 -- \
            "dotfiles: not loading $secret_file: expected a regular, non-symlink file"
        return
    fi
    if [[ ! -O "$secret_file" ]]; then
        print -ru2 -- \
            "dotfiles: not loading $secret_file: file must be owned by the current user"
        return
    fi
    if [[ ! -r "$secret_file" ]]; then
        print -ru2 -- \
            "dotfiles: not loading $secret_file: file is not readable"
        return
    fi
    if ! zmodload -F zsh/stat b:zstat 2>/dev/null \
        || ! zstat -H secret_stat -- "$secret_file" 2>/dev/null; then
        print -ru2 -- \
            "dotfiles: not loading $secret_file: unable to verify file permissions"
        return
    fi
    if (( (secret_stat[mode] & 077) != 0 )); then
        print -ru2 -- \
            "dotfiles: not loading $secret_file: run chmod 600 on this file"
        return
    fi

    source "$secret_file"
}

# The local system summary is disabled by default. Run `motd` explicitly, or
# opt in to displaying it during interactive startup.
if [[ -o interactive && "${DOTFILES_MOTD_ON_START:-0}" == 1 ]] \
    && (( $+commands[motd] || $+functions[motd] )); then
    motd
fi
