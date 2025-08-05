#!/usr/bin/env bash
# dotfiles uninstaller.

set -euo pipefail

# --- Configuration ---
XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-"$HOME/.config"}
XDG_DATA_HOME=${XDG_DATA_HOME:-"$HOME/.local/share"}

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
    local backup_parent_dir="$XDG_DATA_HOME/dotfiles"
    if [ ! -d "$backup_parent_dir" ]; then
        log_info "No backup directories found."
        return
    fi

    local backup_dirs=("$backup_parent_dir"/backup_*/)
    if [ ${#backup_dirs[@]} -eq 0 ] || [ ! -d "${backup_dirs}" ]; then
        log_info "No backup directories found."
        return
    fi

    local backup_to_restore
    if [ "${CI-}" = "true" ]; then
        # In CI, automatically select the latest backup
        backup_to_restore=$(ls -td -- "$backup_parent_dir"/backup_*/ | head -n 1)
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

        # As we preserved the structure, we can copy the whole backup content to HOME
        # The backup contains subdirectories like .config, etc.
        if [ -d "$backup_to_restore" ]; then
            # shellcheck disable=SC2086
            cp $cp_opts "$backup_to_restore"/. "$HOME/"
            log_info "Restoration from backup completed."
        else
            log_error "Backup directory not found: $backup_to_restore"
        fi
    fi
}

prompt_yes_no() {
    while true; do
        read -r -p "$1 [y/N]: " answer
        case "$answer" in
            [Yy]*) return 0 ;;
            [Nn]*|"" ) return 1 ;;
            *) log_error "Invalid input." ;;
        esac
    done
}

uninstall_sheldon() {
    log_info "Checking for sheldon installation..."
    local sheldon_path="$HOME/.local/bin/sheldon"
    if [ -f "$sheldon_path" ]; then
        # In CI, uninstall without prompting.
        if [ "${CI-}" = "true" ] || prompt_yes_no "Do you want to uninstall sheldon?"; then
            log_info "Uninstalling sheldon..."
            rm "$sheldon_path"
            # Attempt to remove the parent directory if it's empty
            if [ -z "$(ls -A "$HOME/.local/bin")" ]; then
                log_info "Removing empty directory: $HOME/.local/bin"
                rmdir "$HOME/.local/bin"
            fi
            if [ -z "$(ls -A "$HOME/.local")" ]; then
                log_info "Removing empty directory: $HOME/.local"
                rmdir "$HOME/.local"
            fi
            log_info "sheldon uninstalled."
        else
            log_info "Skipping sheldon uninstallation."
        fi
    else
        log_info "sheldon is not installed."
    fi
}

main() {
    remove_symlinks
    restore_backup
    uninstall_sheldon

    log_info "✅ Uninstallation completed successfully!"
}

main
