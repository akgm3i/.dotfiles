#!/usr/bin/env bash
# dotfiles uninstaller.

set -euo pipefail

# --- Configuration ---
XDG_STATE_HOME=${XDG_STATE_HOME:-"$HOME/.local/state"}
DOTFILES_STATE_DIR=${DOTFILES_STATE_DIR:-"$XDG_STATE_HOME/dotfiles"}
DOTFILES_INSTALL_STATE=${DOTFILES_INSTALL_STATE:-"$DOTFILES_STATE_DIR/install-state.tsv"}

# --- Helper for logging ---
log_info() {
    printf "\e[34m[INFO]\e[m %s\n" "$1"
}

log_error() {
    printf "\e[31m[ERROR]\e[m %s\n" "$1" >&2
}

# --- Main functions ---

append_state_record() {
    local state_file=$1
    local status=$2
    local source=$3
    local destination=$4
    local backup=$5
    local fingerprint=${6:--}

    printf '%s\t%s\t%s\t%s\t%s\n' \
        "$status" "$source" "$destination" "$backup" "$fingerprint" >> "$state_file"
}

file_fingerprint() {
    local file=$1
    local output checksum size

    [ -f "$file" ] && [ ! -L "$file" ] || return 1
    if command -v shasum >/dev/null 2>&1; then
        output="$(shasum -a 256 "$file")"
        printf 'sha256:%s\n' "${output%% *}"
        return
    fi
    if command -v sha256sum >/dev/null 2>&1; then
        output="$(sha256sum "$file")"
        printf 'sha256:%s\n' "${output%% *}"
        return
    fi

    read -r checksum size _ < <(cksum "$file")
    printf 'cksum:%s:%s\n' "$checksum" "$size"
}

uninstall_managed_links() {
    log_info "Removing paths recorded by the installer..."

    if [ ! -r "$DOTFILES_INSTALL_STATE" ]; then
        log_info "No installation state found; no paths will be removed."
        return 0
    fi

    local state_tmp
    state_tmp="$(mktemp "$DOTFILES_STATE_DIR/.uninstall-state.XXXXXX")"
    chmod 600 "$state_tmp"
    printf 'version\t2\n' > "$state_tmp"

    local incomplete=0
    local status source destination backup fingerprint
    while IFS=$'\t' read -r status source destination backup fingerprint; do
        case "$status" in
            version)
                continue
                ;;
            preexisting)
                log_info "Leaving pre-existing path untouched: $destination"
                continue
                ;;
            copied|created)
                ;;
            *)
                log_error "Keeping an unrecognized installation-state record."
                append_state_record \
                    "$state_tmp" \
                    "$status" \
                    "$source" \
                    "$destination" \
                    "$backup" \
                    "${fingerprint:--}"
                incomplete=1
                continue
                ;;
        esac

        if [ "$backup" != "-" ] \
            && [ ! -e "$backup" ] \
            && [ ! -L "$backup" ]; then
            log_error "Refusing to remove $destination because its recorded backup is missing: $backup"
            append_state_record \
                "$state_tmp" \
                "$status" \
                "$source" \
                "$destination" \
                "$backup" \
                "${fingerprint:--}"
            incomplete=1
            continue
        fi

        if [ "$status" = "created" ]; then
            if [ -L "$destination" ]; then
                if [ "$(readlink "$destination")" != "$source" ]; then
                    log_error "Refusing to remove a link not owned by this installation: $destination"
                    append_state_record \
                        "$state_tmp" \
                        "$status" \
                        "$source" \
                        "$destination" \
                        "$backup" \
                        "${fingerprint:--}"
                    incomplete=1
                    continue
                fi
                rm "$destination"
                log_info "Removed managed link: $destination"
            elif [ -e "$destination" ]; then
                log_error "Refusing to replace an unmanaged path: $destination"
                append_state_record \
                    "$state_tmp" \
                    "$status" \
                    "$source" \
                    "$destination" \
                    "$backup" \
                    "${fingerprint:--}"
                incomplete=1
                continue
            else
                log_info "Managed link already absent: $destination"
            fi
        else
            if [ -f "$destination" ] \
                && [ ! -L "$destination" ] \
                && [ "$(file_fingerprint "$destination")" = "$fingerprint" ]; then
                rm "$destination"
                log_info "Removed managed copy: $destination"
            elif [ -e "$destination" ] || [ -L "$destination" ]; then
                log_error "Refusing to remove a modified managed copy: $destination"
                append_state_record \
                    "$state_tmp" \
                    "$status" \
                    "$source" \
                    "$destination" \
                    "$backup" \
                    "${fingerprint:--}"
                incomplete=1
                continue
            else
                log_info "Managed copy already absent: $destination"
            fi
        fi

        if [ "$backup" != "-" ]; then
            if ! mkdir -p "$(dirname "$destination")"; then
                log_error "Could not create the parent directory for: $destination"
                append_state_record \
                    "$state_tmp" \
                    "$status" \
                    "$source" \
                    "$destination" \
                    "$backup" \
                    "${fingerprint:--}"
                incomplete=1
                continue
            fi
            if mv "$backup" "$destination"; then
                log_info "Restored original path: $destination"
            else
                log_error "Could not restore the recorded backup for: $destination"
                append_state_record \
                    "$state_tmp" \
                    "$status" \
                    "$source" \
                    "$destination" \
                    "$backup" \
                    "${fingerprint:--}"
                incomplete=1
            fi
        fi
    done < "$DOTFILES_INSTALL_STATE"

    if [ "$incomplete" -eq 0 ]; then
        rm "$state_tmp" "$DOTFILES_INSTALL_STATE"
        log_info "Installation state removed."
        return 0
    fi

    mv "$state_tmp" "$DOTFILES_INSTALL_STATE"
    return 1
}

main() {
    if uninstall_managed_links; then
        log_info "mise and Sheldon installations were left untouched."
        log_info "✅ Uninstallation completed successfully!"
        return
    fi

    log_error "Uninstallation is incomplete; unresolved entries remain in $DOTFILES_INSTALL_STATE"
    return 1
}

if [ "${BASH_SOURCE[0]:-$0}" = "$0" ]; then
    main "$@"
fi
