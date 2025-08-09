#!/usr/bin/env bash
# dotfiles installer.

set -euo pipefail

# --- Helper for logging ---
log_info() {
    printf "\e[34m[INFO]\e[m %s\n" "$1"
}

log_error() {
    printf "\e[31m[ERROR]\e[m %s\n" "$1" >&2
}

# --- Configuration ---
DOTFILES_REPO=${DOTFILES_REPO:-"https://github.com/akgm3i/.dotfiles.git"}

# Determine script directory if DOTPATH is not set
setup_dotpath() {
    if [ -n "${DOTPATH:-}" ]; then
        return
    fi

    # Executed from a local file.
    local script_dir
    script_dir="$(cd "$(dirname "$0")" && pwd)"
    local git_config_path="$script_dir/.git/config"

    if [ -f "$git_config_path" ] && grep -q "url = ${DOTFILES_REPO}" "$git_config_path"; then
        # Executed from a local git directory.
        DOTPATH="$script_dir"
    else
        # Executed from a standalone script.
        DOTPATH="$script_dir/.dotfiles"
    fi
}
setup_dotpath
unset -f setup_dotpath

XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-"$HOME/.config"}
XDG_DATA_HOME=${XDG_DATA_HOME:-"$HOME/.local/share"}

# --- Globals ---
backup_dir=""

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
    log_info "Checking and installing dependencies..."
    local required_commands=(git tmux zsh curl)
    local os
    os="$(uname)"

    install_commands() {
        local manager=$1
        shift
        local commands_to_check=("$@")
        local commands_to_install=()

        for cmd in "${commands_to_check[@]}"; do
            if ! has "$cmd"; then
                log_info "$cmd is not installed. Adding to installation list."
                commands_to_install+=("$cmd")
            else
                log_info "$cmd is already installed."
            fi
        done

        if [ ${#commands_to_install[@]} -gt 0 ]; then
            log_info "Installing ${commands_to_install[*]} with $manager..."
            if [ "$manager" = "apt" ]; then
                sudo apt-get -qq update
                sudo apt-get -qq install -y "${commands_to_install[@]}"
            elif [ "$manager" = "brew" ]; then
                brew install "${commands_to_install[@]}"
            fi
        else
            log_info "All required dependencies are already installed."
        fi
    }

    if [ "$os" = "Linux" ]; then
        # Assuming Debian/Ubuntu-based Linux
        if has "apt"; then
            install_commands "apt" "${required_commands[@]}"
        else
            log_error "apt not found. Cannot install dependencies on this Linux distribution."
            exit 1
        fi
    elif [ "$os" = "Darwin" ]; then
        # macOS
        if ! has "brew"; then
            NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        log_info "Updating Homebrew..."
        brew update
        install_commands "brew" "${required_commands[@]}"
    else
        log_info "Unsupported OS: $os. Checking for commands without installation."
        for cmd in "${required_commands[@]}"; do
            if ! has "$cmd"; then
                log_error "Command '$cmd' is not found. Please install it manually."
                exit 1
            fi
        done
    fi
}


create_symlinks() {
    log_info "Creating symbolic links..."

    # Ensure target directories exist
    mkdir -p "$XDG_CONFIG_HOME"

    local symlinks=(
        "$DOTPATH/git:$XDG_CONFIG_HOME/git"
        "$DOTPATH/gh:$XDG_CONFIG_HOME/gh"
        "$DOTPATH/tmux:$XDG_CONFIG_HOME/tmux"
        "$DOTPATH/zsh:$XDG_CONFIG_HOME/zsh"
        "$DOTPATH/sheldon:$XDG_CONFIG_HOME/sheldon"
        "$DOTPATH/mise:$XDG_CONFIG_HOME/mise"
        "$DOTPATH/npm:$XDG_CONFIG_HOME/npm"
        "$DOTPATH/zsh/.zshenv:$HOME/.zshenv"
    )

    # Add OS-specific symlinks
    if [ "$(uname)" = "Darwin" ]; then
        symlinks+=("$DOTPATH/iterm2:$XDG_CONFIG_HOME/iterm2")
    fi

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

install_tools() {
    log_info "Installing additional tools..."
}

switch_shell_to_zsh() {
    local zsh_path
    zsh_path=$(command -v zsh)

    # Change default shell if it's not already zsh
    if [[ "$(basename "$SHELL")" != "zsh" ]]; then
        log_info "Changing your default shell to Zsh..."
        log_info "You might be prompted for your password."
        if chsh -s "$zsh_path"; then
            log_info "Default shell successfully changed to Zsh."
        else
            log_error "Failed to change default shell. Please try running 'chsh -s $zsh_path' manually."
            log_error "You may need to add '$zsh_path' to /etc/shells."
        fi
    else
        log_info "Your default shell is already Zsh."
    fi
}

main() {
    check_dependencies
    clone_or_update_repo
    create_symlinks
    install_tools
    switch_shell_to_zsh

    log_info "✅ Installation completed successfully!"

    # Guide the user to switch their shell for the current session.
    local current_shell
    current_shell=$(basename "$(ps -p $$ -o comm=)")
    if [[ "$current_shell" != "zsh" ]] && [ -t 1 ]; then
        log_info "To switch your current shell to zsh, please run the following command:"
        printf "\n    \e[32mexec zsh -l\e[m\n\n"
    else
        log_info "Please restart your shell to apply all changes."
        printf "\n    \e[32mexec $SHELL -l\e[m\n\n"
    fi
}

main
