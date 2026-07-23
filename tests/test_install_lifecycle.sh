#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
TEST_DIR="$(cd "$(mktemp -d)" && pwd -P)"
trap 'rm -rf "$TEST_DIR"' EXIT

assert_eq() {
    local expected=$1
    local actual=$2
    local test_name=$3

    if [ "$expected" = "$actual" ]; then
        printf 'PASS: %s\n' "$test_name"
        return
    fi

    printf 'FAIL: %s\nexpected: %s\nactual:   %s\n' \
        "$test_name" "$expected" "$actual" >&2
    exit 1
}

assert_exists() {
    local path=$1
    local test_name=$2

    if [ -e "$path" ] || [ -L "$path" ]; then
        printf 'PASS: %s\n' "$test_name"
        return
    fi

    printf 'FAIL: %s\nmissing: %s\n' "$test_name" "$path" >&2
    exit 1
}

assert_not_exists() {
    local path=$1
    local test_name=$2

    if [ ! -e "$path" ] && [ ! -L "$path" ]; then
        printf 'PASS: %s\n' "$test_name"
        return
    fi

    printf 'FAIL: %s\nunexpected path: %s\n' "$test_name" "$path" >&2
    exit 1
}

prepare_home() {
    local name=$1

    HOME="$TEST_DIR/$name"
    XDG_CONFIG_HOME="$HOME/.config"
    XDG_CACHE_HOME="$HOME/.cache"
    XDG_DATA_HOME="$HOME/.local/share"
    XDG_STATE_HOME="$HOME/.local/state"
    XDG_RUNTIME_DIR="$HOME/.temp"
    DOTPATH="$REPO_ROOT"
    DOTFILES_STATE_DIR="$XDG_STATE_HOME/dotfiles"
    DOTFILES_INSTALL_STATE="$DOTFILES_STATE_DIR/install-state.tsv"
    export HOME XDG_CONFIG_HOME XDG_CACHE_HOME XDG_DATA_HOME XDG_STATE_HOME
    export XDG_RUNTIME_DIR DOTPATH DOTFILES_STATE_DIR DOTFILES_INSTALL_STATE
    mkdir -p "$HOME"
}

state_backup_for() {
    local destination=$1

    awk -F '\t' -v destination="$destination" \
        '$1 == "created" && $3 == destination { print $4 }' \
        "$DOTFILES_INSTALL_STATE"
}

backup_count() {
    local count=0
    local path

    for path in "$XDG_DATA_HOME/dotfiles"/backup_*; do
        [ -d "$path" ] || continue
        count=$((count + 1))
    done
    printf '%s\n' "$count"
}

test_local_checkout_detection_ignores_remote_url() (
    local checkout="$TEST_DIR/fork-checkout"
    local home="$TEST_DIR/detection-home"
    local detected

    mkdir -p "$checkout" "$home"
    cp "$REPO_ROOT/install.sh" "$checkout/install.sh"
    git -C "$checkout" init -q
    git -C "$checkout" add install.sh
    git -C "$checkout" remote add origin git@github.com:someone/dotfiles-fork.git

    detected="$(
        env -u DOTPATH HOME="$home" bash -c \
            'source "$1"; printf "%s\n" "$DOTPATH"' \
            _ "$checkout/install.sh"
    )"

    assert_eq "$checkout" "$detected" \
        "local checkout is detected with an SSH fork remote"
)

test_install_repeat_and_restore() (
    prepare_home "lifecycle-home"
    printf 'original bashrc\n' > "$HOME/.bashrc"

    # Sourcing exposes the lifecycle functions without invoking network,
    # package-manager, sudo, or chsh operations.
    # shellcheck source=../install.sh
    source "$REPO_ROOT/install.sh"
    create_symlinks

    assert_eq "$REPO_ROOT/git" "$(readlink "$XDG_CONFIG_HOME/git")" \
        "first install links config directory"
    assert_eq "$REPO_ROOT/zsh/.zshenv" "$(readlink "$HOME/.zshenv")" \
        "first install links home file"

    local original_backup first_backup_count second_backup_count
    original_backup="$(state_backup_for "$HOME/.bashrc")"
    assert_exists "$original_backup" "original file is preserved in recorded backup"
    assert_eq "original bashrc" "$(sed -n '1p' "$original_backup")" \
        "recorded backup retains original content"
    first_backup_count="$(backup_count)"

    create_symlinks

    second_backup_count="$(backup_count)"
    assert_eq "$first_backup_count" "$second_backup_count" \
        "repeat install does not create another backup"
    assert_eq "$original_backup" "$(state_backup_for "$HOME/.bashrc")" \
        "repeat install keeps the original backup association"

    # A newer-looking directory must never influence restoration; only the
    # backup path recorded for this destination is authoritative.
    mkdir -p "$XDG_DATA_HOME/dotfiles/backup_99999999999999_decoy/items"
    printf 'wrong backup\n' \
        > "$XDG_DATA_HOME/dotfiles/backup_99999999999999_decoy/items/item_1"

    mkdir -p "$HOME/.local/bin"
    printf 'shared mise\n' > "$HOME/.local/bin/mise"
    printf 'shared sheldon\n' > "$HOME/.local/bin/sheldon"

    # shellcheck source=../uninstall.sh
    source "$REPO_ROOT/uninstall.sh"
    uninstall_managed_links

    assert_not_exists "$XDG_CONFIG_HOME/git" \
        "uninstall removes a link created by this installation"
    assert_eq "original bashrc" "$(sed -n '1p' "$HOME/.bashrc")" \
        "uninstall restores the associated original"
    assert_not_exists "$DOTFILES_INSTALL_STATE" \
        "successful uninstall consumes installation state"
    assert_exists "$HOME/.local/bin/mise" \
        "uninstall leaves a shared mise installation untouched"
    assert_exists "$HOME/.local/bin/sheldon" \
        "uninstall leaves a shared Sheldon installation untouched"
)

test_preexisting_matching_link_is_not_claimed() (
    prepare_home "preexisting-home"
    ln -s "$REPO_ROOT/zsh/.zshenv" "$HOME/.zshenv"

    # shellcheck source=../install.sh
    source "$REPO_ROOT/install.sh"
    create_symlinks
    # shellcheck source=../uninstall.sh
    source "$REPO_ROOT/uninstall.sh"
    uninstall_managed_links

    assert_eq "$REPO_ROOT/zsh/.zshenv" "$(readlink "$HOME/.zshenv")" \
        "uninstall leaves a pre-existing matching link untouched"
)

test_uninstall_refuses_replaced_link() (
    prepare_home "replaced-home"
    local unrelated="$HOME/unrelated-zshenv"
    printf 'unrelated\n' > "$unrelated"

    # shellcheck source=../install.sh
    source "$REPO_ROOT/install.sh"
    create_symlinks
    rm "$HOME/.zshenv"
    ln -s "$unrelated" "$HOME/.zshenv"

    # shellcheck source=../uninstall.sh
    source "$REPO_ROOT/uninstall.sh"
    if uninstall_managed_links; then
        printf 'FAIL: uninstall unexpectedly accepted a replaced link\n' >&2
        exit 1
    fi

    assert_eq "$unrelated" "$(readlink "$HOME/.zshenv")" \
        "uninstall refuses to remove an unrelated replacement link"
    assert_exists "$DOTFILES_INSTALL_STATE" \
        "unresolved ownership record remains available for retry"
    if awk -F '\t' -v destination="$HOME/.zshenv" \
        '$1 == "created" && $3 == destination { found = 1 } END { exit !found }' \
        "$DOTFILES_INSTALL_STATE"; then
        printf 'PASS: unresolved state identifies the refused link\n'
    else
        printf 'FAIL: unresolved state does not identify refused link\n' >&2
        exit 1
    fi
)

test_local_checkout_detection_ignores_remote_url
test_install_repeat_and_restore
test_preexisting_matching_link_is_not_claimed
test_uninstall_refuses_replaced_link
