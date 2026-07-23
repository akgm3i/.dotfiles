#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
TEST_DIR="$(mktemp -d)"
ORIGINAL_PATH=$PATH
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

assert_regular_file() {
    local path=$1
    local test_name=$2

    if [ -f "$path" ] && [ ! -L "$path" ]; then
        printf 'PASS: %s\n' "$test_name"
        return
    fi

    printf 'FAIL: %s\nnot a regular file: %s\n' "$test_name" "$path" >&2
    exit 1
}

prepare_home() {
    local name=$1
    local os=$2
    local fake_bin="$TEST_DIR/$name-bin"

    HOME="$TEST_DIR/$name"
    XDG_CONFIG_HOME="$HOME/.config"
    XDG_CACHE_HOME="$HOME/.cache"
    XDG_DATA_HOME="$HOME/.local/share"
    XDG_STATE_HOME="$HOME/.local/state"
    XDG_RUNTIME_DIR="$HOME/.temp"
    DOTPATH="$REPO_ROOT"
    DOTFILES_STATE_DIR="$XDG_STATE_HOME/dotfiles"
    DOTFILES_INSTALL_STATE="$DOTFILES_STATE_DIR/install-state.tsv"

    mkdir -p "$HOME" "$fake_bin"
    printf '#!/usr/bin/env bash\nprintf "%%s\\n" "%s"\n' "$os" \
        > "$fake_bin/uname"
    chmod +x "$fake_bin/uname"
    PATH="$fake_bin:$ORIGINAL_PATH"

    export HOME XDG_CONFIG_HOME XDG_CACHE_HOME XDG_DATA_HOME XDG_STATE_HOME
    export XDG_RUNTIME_DIR DOTPATH DOTFILES_STATE_DIR DOTFILES_INSTALL_STATE PATH
}

test_dynamic_profile_json() {
    local profile_file="$REPO_ROOT/iterm2/akgm3i.json"

    if command -v plutil >/dev/null 2>&1; then
        plutil -lint "$profile_file" >/dev/null
        printf 'PASS: dynamic profile is valid property-list syntax\n'
    elif command -v jq >/dev/null 2>&1; then
        jq empty "$profile_file"
        printf 'PASS: dynamic profile is valid JSON syntax\n'
    elif command -v python3 >/dev/null 2>&1; then
        python3 -m json.tool "$profile_file" >/dev/null
        printf 'PASS: dynamic profile is valid JSON syntax\n'
    else
        printf 'SKIP: no JSON/property-list validator is installed\n'
    fi

    if command -v jq >/dev/null 2>&1; then
        jq -e '
            .Profiles as $profiles
            | ($profiles | length) == 2
              and $profiles[0].Name == "akgm"
              and $profiles[1].Name == "akgm for trio"
              and $profiles[1]["Dynamic Profile Parent GUID"] == $profiles[0].Guid
              and ($profiles[0]["Status Bar Layout"].components | length) == 7
        ' "$profile_file" >/dev/null
        printf 'PASS: dynamic profiles retain names, inheritance, and status bar\n'
    fi

    if grep -q '/Users/' "$profile_file" \
        || grep -q '"Working Directory"' "$profile_file"; then
        printf 'FAIL: dynamic profile contains a machine-specific home path\n' >&2
        exit 1
    fi
    printf 'PASS: dynamic profiles contain no machine-specific home path\n'
}

test_macos_installs_owned_dynamic_profile() (
    prepare_home "darwin-home" "Darwin"
    local profiles_dir="$HOME/Library/Application Support/iTerm2/DynamicProfiles"
    local installed_profile="$profiles_dir/akgm3i.json"
    local preferences="$HOME/Library/Preferences/com.googlecode.iterm2.plist"
    local xdg_iterm="$XDG_CONFIG_HOME/iterm2"

    mkdir -p "$profiles_dir" "$(dirname "$preferences")" "$xdg_iterm"
    printf 'personal profile\n' > "$profiles_dir/personal.json"
    printf 'previous akgm profile\n' > "$installed_profile"
    printf 'user preferences\n' > "$preferences"
    printf 'xdg user setting\n' > "$xdg_iterm/custom"

    # shellcheck source=../install.sh
    source "$REPO_ROOT/install.sh"
    create_symlinks

    assert_regular_file "$installed_profile" \
        "macOS copies a regular file into iTerm2 DynamicProfiles"
    if cmp -s "$REPO_ROOT/iterm2/akgm3i.json" "$installed_profile"; then
        printf 'PASS: installed dynamic profile matches the tracked source\n'
    else
        printf 'FAIL: installed dynamic profile differs from its source\n' >&2
        exit 1
    fi
    assert_eq "personal profile" "$(sed -n '1p' "$profiles_dir/personal.json")" \
        "installer leaves other dynamic profiles unchanged"
    assert_eq "user preferences" "$(sed -n '1p' "$preferences")" \
        "installer leaves the iTerm2 preferences database unchanged"
    assert_eq "xdg user setting" "$(sed -n '1p' "$xdg_iterm/custom")" \
        "installer leaves the obsolete XDG location unchanged"

    if awk -F '\t' -v destination="$installed_profile" \
        '$1 == "copied" && $3 == destination && $5 != "" { found = 1 } END { exit !found }' \
        "$DOTFILES_INSTALL_STATE"; then
        printf 'PASS: dynamic profile ownership and fingerprint are recorded\n'
    else
        printf 'FAIL: dynamic profile ownership or fingerprint is not recorded\n' >&2
        exit 1
    fi

    local first_backup second_backup
    first_backup="$(
        awk -F '\t' -v destination="$installed_profile" \
            '$1 == "copied" && $3 == destination { print $4 }' \
            "$DOTFILES_INSTALL_STATE"
    )"
    create_symlinks
    second_backup="$(
        awk -F '\t' -v destination="$installed_profile" \
            '$1 == "copied" && $3 == destination { print $4 }' \
            "$DOTFILES_INSTALL_STATE"
    )"
    assert_eq "$first_backup" "$second_backup" \
        "repeat install retains the original dynamic-profile backup"

    # shellcheck source=../uninstall.sh
    source "$REPO_ROOT/uninstall.sh"
    uninstall_managed_links

    assert_eq "previous akgm profile" "$(sed -n '1p' "$installed_profile")" \
        "uninstall restores a previous same-name profile"
    assert_eq "personal profile" "$(sed -n '1p' "$profiles_dir/personal.json")" \
        "uninstall leaves other dynamic profiles unchanged"
    assert_eq "user preferences" "$(sed -n '1p' "$preferences")" \
        "uninstall leaves iTerm2 preferences unchanged"
)

test_macos_refuses_modified_managed_copy() (
    prepare_home "modified-darwin-home" "Darwin"
    local installed_profile="$HOME/Library/Application Support/iTerm2/DynamicProfiles/akgm3i.json"

    # shellcheck source=../install.sh
    source "$REPO_ROOT/install.sh"
    create_symlinks
    printf '\n' >> "$installed_profile"

    # shellcheck source=../uninstall.sh
    source "$REPO_ROOT/uninstall.sh"
    if uninstall_managed_links; then
        printf 'FAIL: uninstall accepted a modified dynamic profile\n' >&2
        exit 1
    fi

    assert_regular_file "$installed_profile" \
        "uninstall leaves a modified dynamic profile untouched"
    if awk -F '\t' -v destination="$installed_profile" \
        '$1 == "copied" && $3 == destination { found = 1 } END { exit !found }' \
        "$DOTFILES_INSTALL_STATE"; then
        printf 'PASS: modified dynamic-profile ownership remains for retry\n'
    else
        printf 'FAIL: modified dynamic-profile state was discarded\n' >&2
        exit 1
    fi
)

test_linux_does_not_install_iterm_profile() (
    prepare_home "linux-home" "Linux"
    local profiles_dir="$HOME/Library/Application Support/iTerm2/DynamicProfiles"
    local xdg_iterm="$XDG_CONFIG_HOME/iterm2"

    mkdir -p "$xdg_iterm"
    printf 'linux user setting\n' > "$xdg_iterm/custom"

    # shellcheck source=../install.sh
    source "$REPO_ROOT/install.sh"
    create_symlinks

    assert_not_exists "$profiles_dir" \
        "Linux does not create the iTerm2 DynamicProfiles directory"
    assert_eq "linux user setting" "$(sed -n '1p' "$xdg_iterm/custom")" \
        "Linux leaves an existing iTerm2 XDG path unchanged"
    if grep -q 'akgm3i.json' "$DOTFILES_INSTALL_STATE"; then
        printf 'FAIL: Linux installation state contains an iTerm2 profile\n' >&2
        exit 1
    fi
    printf 'PASS: Linux installation state contains no iTerm2 profile\n'
)

test_dynamic_profile_json
test_macos_installs_owned_dynamic_profile
test_macos_refuses_modified_managed_copy
test_linux_does_not_install_iterm_profile
