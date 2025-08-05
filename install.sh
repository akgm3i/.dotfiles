#!/usr/bin/env bash
# dotfiles installer.

set -euo pipefail

# --- Configuration ---
DOTPATH=${DOTPATH:-"$HOME/.dotfiles"}
XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-"$HOME/.config"}
XDG_DATA_HOME=${XDG_DATA_HOME:-"$HOME/.local/share"}
DOTFILES_REPO=${DOTFILES_REPO:-"https://github.com/akgm3i/dotfiles.git"}

# --- Globals ---
backup_dir=""

# --- Helper for logging ---
log_info() {
    printf "\e[34m[INFO]\e[m %s\n" "$1"
}

log_error() {
    printf "\e[31m[ERROR]\e[m %s\n" "$1" >&2
}

# --- Cleanup function for trap ---
cleanup() {
    if [ "$?" != "0" ]; then
        log_error "Installation failed."
        if [ -n "$backup_dir" ]; then
            log_info "Your original files were backed up to: $backup_dir"
            log_info "You can restore them manually."
        fi
    fi
}

trap cleanup EXIT

# --- Check if a command exists ---
has() {
    command -v "$1" >/dev/null 2>&1
}

# --- Main functions ---

clone_or_update_repo() {
    if [ -d "$DOTPATH" ]; then
        log_info "Updating dotfiles repository in $DOTPATH..."
        (cd "$DOTPATH" && git pull)
    else
        log_info "Cloning dotfiles repository to $DOTPATH..."
        git clone --depth 1 "$DOTFILES_REPO" "$DOTPATH"
    fi
}

check_dependencies() {
    log_info "Checking dependencies..."
    local required_commands=(
        git
        tmux
        zsh
        curl # for sheldon installation
    )

    for cmd in "${required_commands[@]}"; do
        if ! has "$cmd"; then
            log_error "Command '$cmd' is not found."
            exit 1
        fi
    done
}

install_sheldon() {
    log_info "Installing sheldon..."
    local sheldon_path="$HOME/.local/bin/sheldon"
    if [ ! -f "$sheldon_path" ]; then
        log_info "sheldon not found. Installing..."
        mkdir -p "$HOME/.local/bin"
        curl --proto '=https' -fLsS https://rossmacarthur.github.io/install/crate.sh \
            | bash -s -- --repo rossmacarthur/sheldon --to "$HOME/.local/bin"
    else
        log_info "sheldon is already installed."
    fi
}

create_symlinks() {
    log_info "Creating symbolic links..."

    # Ensure target directories exist
    mkdir -p "$XDG_CONFIG_HOME"

    local symlinks=(
        "$DOTPATH/git:$XDG_CONFIG_HOME/git"
        "$DOTPATH/tmux:$XDG_CONFIG_HOME/tmux"
        "$DOTPATH/sheldon:$XDG_CONFIG_HOME/sheldon"
        "$DOTPATH/zsh:$XDG_CONFIG_HOME/zsh"
        "$DOTPATH/iterm2:$XDG_CONFIG_HOME/iterm2"
        "$DOTPATH/zsh/.zshenv:$HOME/.zshenv"
    )

    for link in "${symlinks[@]}"; do
        local src="${link%%:*}"
        local dest="${link#*:}"

        if [ -e "$dest" ] || [ -L "$dest" ]; then
            if [ -z "$backup_dir" ]; then
                backup_dir="$XDG_DATA_HOME/dotfiles/backup_$(date +%Y%m%d%H%M%S)"
                mkdir -p "$backup_dir"
                log_info "Created backup directory: $backup_dir"
            fi
            log_info "Backing up existing file: $dest"
            # Preserve directory structure in backup
            local backup_path="$backup_dir/$(dirname "${dest#$HOME/}")"
            mkdir -p "$backup_path"
            if ! mv "$dest" "$backup_path/"; then
                log_error "Failed to back up $dest. Aborting."
                exit 1
            fi
        fi

        if [ ! -e "$src" ]; then
            log_error "Source file not found: $src"
            exit 1
        fi
        ln -snf "$src" "$dest"
        log_info "Linked $src -> $dest"
    done
}

main() {
    check_dependencies
    clone_or_update_repo
    install_sheldon
    create_symlinks
    log_info "✅ Installation completed successfully!"
    log_info "Please restart your shell to apply the changes."
}

main
