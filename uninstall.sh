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
        "$XDG_CONFIG_HOME/mise"
        "$XDG_CONFIG_HOME/npm"
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

uninstall_mise() {
    log_info "Checking for mise installation..."
    local mise_path="$HOME/.local/bin/mise"

    # Check for the existence of the mise binary as the primary indicator of installation.
    if [ ! -f "$mise_path" ]; then
        log_info "mise binary not found at $mise_path. Skipping uninstallation."
        return
    fi

    if [ "${CI-}" = "true" ] || prompt_yes_no "Do you want to uninstall mise?"; then
        # Attempt to use the official uninstaller first if the command is available.
        if command -v mise &> /dev/null; then
            log_info "Uninstalling mise using 'mise implode'..."
            if mise implode; then
                log_info "mise uninstalled successfully via 'mise implode'."
                # implode should remove the binary, but we double-check and remove if it's still there.
                if [ -f "$mise_path" ]; then
                    rm "$mise_path"
                fi
                log_info "mise uninstallation complete."
                return
            else
                log_error "'mise implode' command failed. Proceeding with manual removal."
            fi
        else
            log_info "'mise' command not found in PATH. Proceeding with manual removal."
        fi

        # Fallback to manual removal.
        log_info "Attempting to manually remove mise files..."

        # Remove the binary
        log_info "Removing mise binary: $mise_path"
        rm "$mise_path"

        # Remove directories
        local mise_data_dir=${MISE_DATA_DIR:-"$XDG_DATA_HOME/mise"}
        local mise_state_dir=${MISE_STATE_DIR:-"$HOME/.local/state/mise"}
        local mise_config_dir=${MISE_CONFIG_DIR:-"$XDG_CONFIG_HOME/mise"}
        local mise_cache_dir

        case "$(uname -s)" in
            Linux*)
                mise_cache_dir=${MISE_CACHE_DIR:-"$HOME/.cache/mise"}
                ;;
            Darwin*)
                mise_cache_dir=${MISE_CACHE_DIR:-"$HOME/Library/Caches/mise"}
                ;;
            *)
                mise_cache_dir=""
                ;;
        esac

        local dirs_to_remove=("$mise_data_dir" "$mise_state_dir" "$mise_config_dir")
        if [ -n "$mise_cache_dir" ]; then
            dirs_to_remove+=("$mise_cache_dir")
        fi

        for dir in "${dirs_to_remove[@]}"; do
            if [ -d "$dir" ]; then
                log_info "Removing directory: $dir"
                rm -rf "$dir"
            else
                log_info "Directory not found, skipping: $dir"
            fi
        done

        log_info "mise manual uninstallation process completed."
    else
        log_info "Skipping mise uninstallation."
    fi
}

main() {
    remove_symlinks
    restore_backup
    uninstall_sheldon
    uninstall_mise

    log_info "✅ Uninstallation completed successfully!"
}

main
