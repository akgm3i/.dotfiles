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
    local script_path="${1:-${BASH_SOURCE[0]:-$0}}"
    local script_dir git_root
    script_dir="$(cd "$(dirname "$script_path")" && pwd -P)"

    if git_root="$(git -C "$script_dir" rev-parse --show-toplevel 2>/dev/null)" \
        && [ "$(cd "$git_root" && pwd -P)" = "$script_dir" ] \
        && git -C "$script_dir" ls-files --error-unmatch -- "$(basename "$script_path")" >/dev/null 2>&1; then
        # Executed from the root of a local checkout. The remote URL is
        # intentionally irrelevant so SSH remotes and forks work as expected.
        DOTPATH="$script_dir"
    else
        # Executed from a standalone script.
        DOTPATH="$script_dir/.dotfiles"
    fi
}
setup_dotpath "${BASH_SOURCE[0]:-$0}"

XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-"$HOME/.config"}
XDG_CACHE_HOME=${XDG_CACHE_HOME:-"$HOME/.cache"}
XDG_DATA_HOME=${XDG_DATA_HOME:-"$HOME/.local/share"}
XDG_STATE_HOME=${XDG_STATE_HOME:-"$HOME/.local/state"}
XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-"$HOME/.temp"}
DOTFILES_STATE_DIR=${DOTFILES_STATE_DIR:-"$XDG_STATE_HOME/dotfiles"}
DOTFILES_INSTALL_STATE=${DOTFILES_INSTALL_STATE:-"$DOTFILES_STATE_DIR/install-state.tsv"}

# --- Globals ---
backup_dir=""
backup_sequence=0
state_tmp=""

# --- Cleanup function for trap ---
cleanup() {
    local exit_status=$?

    if [ -n "$state_tmp" ] && [ -e "$state_tmp" ]; then
        rm -f "$state_tmp"
    fi

    if [ "$exit_status" != "0" ]; then
        log_error "Installation failed."
        if [ -n "$backup_dir" ]; then
            log_info "Your original files were backed up to: $backup_dir"
            log_info "You can restore them manually."
        fi
    fi

    return "$exit_status"
}

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

canonical_path() {
    local path=$1
    local dir base

    if [ -d "$path" ]; then
        (cd "$path" 2>/dev/null && pwd -P)
        return
    fi

    dir="$(dirname "$path")"
    base="$(basename "$path")"
    (cd "$dir" 2>/dev/null && printf '%s/%s\n' "$(pwd -P)" "$base")
}

symlink_points_to() {
    local link=$1
    local expected=$2
    local target

    [ -L "$link" ] || return 1
    target="$(readlink "$link")"
    case "$target" in
        /*) ;;
        *) target="$(dirname "$link")/$target" ;;
    esac

    [ "$(canonical_path "$target")" = "$(canonical_path "$expected")" ]
}

managed_symlink_matches() {
    local link=$1
    local recorded_source=$2

    [ -L "$link" ] && [ "$(readlink "$link")" = "$recorded_source" ]
}

state_status=""
state_source=""
state_backup=""

load_state_record() {
    local destination=$1
    local record_status record_source record_destination record_backup

    state_status=""
    state_source=""
    state_backup=""
    [ -r "$DOTFILES_INSTALL_STATE" ] || return 1

    while IFS=$'\t' read -r record_status record_source record_destination record_backup; do
        case "$record_status" in
            created|preexisting)
                if [ "$record_destination" = "$destination" ]; then
                    state_status="$record_status"
                    state_source="$record_source"
                    state_backup="$record_backup"
                    return 0
                fi
                ;;
        esac
    done < "$DOTFILES_INSTALL_STATE"

    return 1
}

append_state_record() {
    local status=$1
    local source=$2
    local destination=$3
    local backup=$4

    printf '%s\t%s\t%s\t%s\n' "$status" "$source" "$destination" "$backup" >> "$state_tmp"
}

state_has_destination() {
    local state_file=$1
    local destination=$2
    local record_status record_source record_destination record_backup

    while IFS=$'\t' read -r record_status record_source record_destination record_backup; do
        case "$record_status" in
            created|preexisting)
                [ "$record_destination" = "$destination" ] && return 0
                ;;
        esac
    done < "$state_file"

    return 1
}

create_backup_dir() {
    local backup_parent="$XDG_DATA_HOME/dotfiles"

    [ -n "$backup_dir" ] && return
    mkdir -p "$backup_parent"
    backup_dir="$(mktemp -d "$backup_parent/backup_$(date +%Y%m%d%H%M%S)_XXXXXX")"
    mkdir -p "$backup_dir/items"
    log_info "Created backup directory: $backup_dir"
}

backed_up_path=""

backup_destination() {
    local destination=$1

    create_backup_dir
    while :; do
        backup_sequence=$((backup_sequence + 1))
        backed_up_path="$backup_dir/items/item_$backup_sequence"
        if [ ! -e "$backed_up_path" ] && [ ! -L "$backed_up_path" ]; then
            break
        fi
    done

    log_info "Backing up existing file: $destination"
    if ! mv "$destination" "$backed_up_path"; then
        log_error "Failed to back up $destination. Aborting."
        exit 1
    fi
}

create_symlinks() {
    log_info "Creating symbolic links..."

    # Ensure target directories exist
    mkdir -p \
        "$XDG_CONFIG_HOME" \
        "$XDG_CACHE_HOME" \
        "$XDG_DATA_HOME" \
        "$XDG_STATE_HOME" \
        "$XDG_RUNTIME_DIR" \
        "$DOTFILES_STATE_DIR"
    chmod 700 "$XDG_RUNTIME_DIR" 2>/dev/null || true
    state_tmp="$(mktemp "$DOTFILES_STATE_DIR/.install-state.XXXXXX")"
    chmod 600 "$state_tmp"
    printf 'version\t1\n' > "$state_tmp"

    local symlinks=(
        "$DOTPATH/git:$XDG_CONFIG_HOME/git"
        "$DOTPATH/gh:$XDG_CONFIG_HOME/gh"
        "$DOTPATH/tmux:$XDG_CONFIG_HOME/tmux"
        "$DOTPATH/zsh:$XDG_CONFIG_HOME/zsh"
        "$DOTPATH/sheldon:$XDG_CONFIG_HOME/sheldon"
        "$DOTPATH/mise:$XDG_CONFIG_HOME/mise"
        "$DOTPATH/npm:$XDG_CONFIG_HOME/npm"
        "$DOTPATH/bash:$XDG_CONFIG_HOME/bash"
        "$DOTPATH/bash/.bashrc:$HOME/.bashrc"
        "$DOTPATH/bash/.bash_profile:$HOME/.bash_profile"
        "$DOTPATH/zsh/.zshenv:$HOME/.zshenv"
    )

    # Add OS-specific symlinks
    if [ "$(uname)" = "Darwin" ]; then
        symlinks+=("$DOTPATH/iterm2:$XDG_CONFIG_HOME/iterm2")
    fi

    for link in "${symlinks[@]}"; do
        local src="${link%%:*}"
        local dest="${link#*:}"
        local previous_state=false
        local record_status="created"
        local record_backup="-"

        if [ ! -e "$src" ]; then
            log_error "Source file not found: $src"
            exit 1
        fi

        if load_state_record "$dest"; then
            previous_state=true
        fi

        if symlink_points_to "$dest" "$src"; then
            if [ "$previous_state" = true ] \
                && [ "$state_status" = "created" ] \
                && managed_symlink_matches "$dest" "$state_source"; then
                record_status="created"
                record_backup="$state_backup"
            else
                # Do not claim ownership of a link that predates this install or
                # was changed outside the installer.
                record_status="preexisting"
            fi
            append_state_record "$record_status" "$src" "$dest" "$record_backup"
            log_info "Already linked $src -> $dest"
            continue
        fi

        if [ -e "$dest" ] || [ -L "$dest" ]; then
            if [ "$previous_state" = true ] \
                && [ "$state_status" = "created" ] \
                && managed_symlink_matches "$dest" "$state_source"; then
                if [ "$state_backup" != "-" ] \
                    && [ ! -e "$state_backup" ] \
                    && [ ! -L "$state_backup" ]; then
                    log_error "Recorded backup is missing for $dest: $state_backup"
                    exit 1
                fi
                rm "$dest"
                record_backup="$state_backup"
            else
                backup_destination "$dest"
                record_backup="$backed_up_path"
            fi
        elif [ "$previous_state" = true ] && [ "$state_status" = "created" ]; then
            record_backup="$state_backup"
        fi

        ln -s "$src" "$dest"
        append_state_record "created" "$src" "$dest" "$record_backup"
        log_info "Linked $src -> $dest"
    done

    # Keep records for platform-specific links that are not part of this run.
    if [ -r "$DOTFILES_INSTALL_STATE" ]; then
        local old_status old_source old_destination old_backup
        while IFS=$'\t' read -r old_status old_source old_destination old_backup; do
            case "$old_status" in
                created|preexisting)
                    if ! state_has_destination "$state_tmp" "$old_destination"; then
                        append_state_record "$old_status" "$old_source" "$old_destination" "$old_backup"
                    fi
                    ;;
            esac
        done < "$DOTFILES_INSTALL_STATE"
    fi

    mv "$state_tmp" "$DOTFILES_INSTALL_STATE"
    state_tmp=""
}

install_tools() {
    log_info "Installing additional tools..."

    local local_bin="$HOME/.local/bin"
    mkdir -p "$local_bin"

    local mise_bin="$local_bin/mise"
    if ! has mise && [ ! -x "$mise_bin" ]; then
        log_info "Installing mise..."
        curl -fsSL https://mise.run | sh
    fi

    if [ -x "$mise_bin" ]; then
        local mise_config="$XDG_CONFIG_HOME/mise/config.toml"
        if [ -r "$mise_config" ]; then
            "$mise_bin" trust "$mise_config"
        fi
        "$mise_bin" install
    elif has mise; then
        local mise_config="$XDG_CONFIG_HOME/mise/config.toml"
        if [ -r "$mise_config" ]; then
            mise trust "$mise_config"
        fi
        mise install
    fi

    local sheldon_bin="$local_bin/sheldon"
    if ! has sheldon && [ ! -x "$sheldon_bin" ]; then
        log_info "Installing sheldon..."
        curl --proto '=https' -fLsS https://rossmacarthur.github.io/install/crate.sh \
            | bash -s -- --repo rossmacarthur/sheldon --to "$local_bin"
    fi
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
    trap cleanup EXIT

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

if [ "${BASH_SOURCE[0]:-$0}" = "$0" ]; then
    main "$@"
fi
