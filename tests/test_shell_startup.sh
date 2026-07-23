#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
TEST_DIR="$(mktemp -d)"
trap 'rm -rf "$TEST_DIR"' EXIT

assert_eq() {
  local expected="$1"
  local actual="$2"
  local test_name="$3"

  if [ "$expected" = "$actual" ]; then
    printf 'PASS: %s\n' "$test_name"
  else
    printf 'FAIL: %s\nexpected: %s\nactual:   %s\n' "$test_name" "$expected" "$actual" >&2
    exit 1
  fi
}

test_zsh_noninteractive_startup() {
  if ! command -v zsh >/dev/null 2>&1; then
    printf 'SKIP: zsh is not installed\n'
    return
  fi

  local home output dotpath zdotdir histfile global_rcs
  home="$TEST_DIR/zsh-noninteractive-home"
  mkdir -p "$home"
  ln -s "$REPO_ROOT/zsh/.zshenv" "$home/.zshenv"

  output="$(
    env \
      -u DOTPATH \
      -u HISTFILE \
      -u XDG_CACHE_HOME \
      -u XDG_CONFIG_HOME \
      -u XDG_DATA_HOME \
      -u XDG_RUNTIME_DIR \
      -u XDG_STATE_HOME \
      -u ZDOTDIR \
      HOME="$home" \
      zsh -c 'printf "%s\n%s\n%s\n%s\n" "$DOTPATH" "$ZDOTDIR" "${HISTFILE-unset}" "$options[globalrcs]"'
  )"
  dotpath="$(printf '%s\n' "$output" | sed -n '1p')"
  zdotdir="$(printf '%s\n' "$output" | sed -n '2p')"
  histfile="$(printf '%s\n' "$output" | sed -n '3p')"
  global_rcs="$(printf '%s\n' "$output" | sed -n '4p')"

  assert_eq "$REPO_ROOT" "$dotpath" "noninteractive zsh resolves DOTPATH from .zshenv symlink"
  assert_eq "$home/.config/zsh" "$zdotdir" "noninteractive zsh selects the XDG startup directory"
  assert_eq "unset" "$histfile" "noninteractive zsh does not configure interactive history"
  assert_eq "on" "$global_rcs" "zsh keeps global startup files enabled"
  assert_eq "absent" "$([ -e "$home/.local" ] && printf 'present' || printf 'absent')" \
    "noninteractive zsh does not create state directories"
}

test_zsh_interactive_startup() {
  if ! command -v zsh >/dev/null 2>&1; then
    return
  fi

  local home output histfile lang lc_all append_history share_history
  home="$TEST_DIR/zsh-interactive-home"
  mkdir -p "$home/.config/zsh"
  ln -s "$REPO_ROOT/zsh/.zshenv" "$home/.zshenv"
  ln -s "$REPO_ROOT/zsh/.zshrc" "$home/.config/zsh/.zshrc"

  output="$(
    env \
      -u DOTPATH \
      -u HISTFILE \
      -u LANG \
      -u LANGUAGE \
      -u LC_ALL \
      -u XDG_CACHE_HOME \
      -u XDG_CONFIG_HOME \
      -u XDG_DATA_HOME \
      -u XDG_RUNTIME_DIR \
      -u XDG_STATE_HOME \
      -u ZDOTDIR \
      HOME="$home" \
      PATH="/usr/bin:/bin" \
      zsh -ic \
      'printf "__HISTFILE__%s\n__LANG__%s\n__LC_ALL__%s\n__APPEND__%s\n__SHARE__%s\n" \
        "$HISTFILE" "$LANG" "${LC_ALL-unset}" "$options[appendhistory]" "$options[sharehistory]"' \
      2>/dev/null
  )"
  histfile="$(printf '%s\n' "$output" | sed -n 's/^__HISTFILE__//p')"
  lang="$(printf '%s\n' "$output" | sed -n 's/^__LANG__//p')"
  lc_all="$(printf '%s\n' "$output" | sed -n 's/^__LC_ALL__//p')"
  append_history="$(printf '%s\n' "$output" | sed -n 's/^__APPEND__//p')"
  share_history="$(printf '%s\n' "$output" | sed -n 's/^__SHARE__//p')"

  assert_eq "$home/.local/state/zsh/history" "$histfile" "interactive zsh stores history under XDG state"
  assert_eq "en_US.UTF-8" "$lang" "interactive zsh supplies a LANG default"
  assert_eq "unset" "$lc_all" "interactive zsh does not force LC_ALL"
  assert_eq "on" "$append_history" "interactive zsh appends history across sessions"
  assert_eq "on" "$share_history" "interactive zsh shares history across sessions"
  assert_eq "present" "$([ -d "$home/.local/state/zsh" ] && printf 'present' || printf 'absent')" \
    "interactive zsh creates its history directory"
  assert_eq "present" "$([ -d "$home/.cache/zsh" ] && printf 'present' || printf 'absent')" \
    "interactive zsh creates its cache directory"
}

test_zsh_preserves_locale_overrides() {
  if ! command -v zsh >/dev/null 2>&1; then
    return
  fi

  local home output
  home="$TEST_DIR/zsh-locale-home"
  mkdir -p "$home/.config/zsh"
  ln -s "$REPO_ROOT/zsh/.zshenv" "$home/.zshenv"
  ln -s "$REPO_ROOT/zsh/.zshrc" "$home/.config/zsh/.zshrc"

  output="$(
    env \
      -u DOTPATH \
      -u LANGUAGE \
      -u XDG_CACHE_HOME \
      -u XDG_CONFIG_HOME \
      -u XDG_DATA_HOME \
      -u XDG_RUNTIME_DIR \
      -u XDG_STATE_HOME \
      -u ZDOTDIR \
      HOME="$home" \
      LANG=C \
      LC_ALL=C \
      PATH="/usr/bin:/bin" \
      zsh -ic 'printf "%s\n%s\n" "$LANG" "$LC_ALL"' \
      2>/dev/null
  )"

  assert_eq "C"$'\n'"C" "$output" "interactive zsh preserves caller locale overrides"
}

test_bash_dotpath_from_symlink() {
  local home output dotpath runtime_dir
  home="$TEST_DIR/bash-home"
  mkdir -p "$home"
  ln -s "$REPO_ROOT/bash/.bashrc" "$home/.bashrc"

  output="$(
    env -u DOTPATH -u XDG_RUNTIME_DIR HOME="$home" bash -ic \
      'printf "__DOTPATH__%s\n__RUNTIME__%s\n" "$DOTPATH" "$XDG_RUNTIME_DIR"; test -d "$XDG_RUNTIME_DIR"' \
      2>/dev/null
  )"
  dotpath="$(printf '%s\n' "$output" | sed -n 's/^__DOTPATH__//p')"
  runtime_dir="$(printf '%s\n' "$output" | sed -n 's/^__RUNTIME__//p')"

  assert_eq "$REPO_ROOT" "$dotpath" "bash resolves DOTPATH from .bashrc symlink"
  assert_eq "$home/.temp" "$runtime_dir" "bash creates default XDG_RUNTIME_DIR"
}

test_zsh_noninteractive_startup
test_zsh_interactive_startup
test_zsh_preserves_locale_overrides
test_bash_dotpath_from_symlink
