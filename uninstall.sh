#!/usr/bin/env bash
# dotfiles uninstaller.

set -euo pipefail

# --- Configuration ---
XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-"$HOME/.config"}

# --- Helper for logging ---
log_info() {
    printf "\e[34m[INFO]\e[m %s\n" "$1"
}

log_error() {
    printf "\e[31m[ERROR]\e[m %s\n" "$1" >&2
}

# --- Main functions ---

remove_symlinks() {
    log_info "Removing symbolic links..."

    local symlinks=(
        "$XDG_CONFIG_HOME/git"
        "$XDG_CONFIG_HOME/tmux"
        "$XDG_CONFIG_HOME/sheldon"
        "$XDG_CONFIG_HOME/zsh"
        "$XDG_CONFIG_HOME/iterm2"
        "$HOME/.zshenv"
    )

    for link in "${symlinks[@]}"; do
        if [ -L "$link" ]; then
            rm "$link"
            log_info "Removed symlink: $link"
        else
            log_info "Symlink not found, skipping: $link"
        fi
    done
}

restore_backup() {
    log_info "Searching for backups..."
    local backup_dirs=("$HOME"/.dotfiles_backup_*/)

    if [ ${#backup_dirs[@]} -eq 0 ] || [ ! -d "${backup_dirs}" ]; then
        log_info "No backup directories found."
        return
    fi

    local backup_to_restore
    if [ "${CI-}" = "true" ]; then
        # In CI, automatically select the latest backup
        backup_to_restore=$(ls -td -- "$HOME"/.dotfiles_backup_*/ | head -n 1)
    else
        # In interactive mode, let the user choose
        log_info "Available backups:"
        select backup_dir in "${backup_dirs[@]}" "Skip restoration"; do
            if [ "$REPLY" == "Skip restoration" ] || [ -z "$REPLY" ]; then
                log_info "Skipping restoration."
                return
            fi
            if [ -d "$backup_dir" ]; then
                backup_to_restore=$backup_dir
                break
            else
                log_error "Invalid selection."
            fi
        done
    fi

    if [ -n "$backup_to_restore" ]; then
        log_info "Restoring files from: $backup_to_restore"
        # Use -i for safety in interactive mode
        local cp_opts="-r"
        [ "${CI-}" != "true" ] && cp_opts="-ri"

        # shellcheck disable=SC2086
        cp $cp_opts "$backup_to_restore"/* "$HOME/"
        # Restore to .config as well
        if [ -d "$backup_to_restore/config" ]; then
             # shellcheck disable=SC2086
            cp $cp_opts "$backup_to_restore/config"/* "$XDG_CONFIG_HOME/"
        fi
        log_info "Restoration from backup completed."
        log_info "You may need to move some files manually from $backup_to_restore"
    fi
}

main() {
    remove_symlinks
    restore_backup

    log_info "✅ Uninstallation completed successfully!"
}

main "$@"
