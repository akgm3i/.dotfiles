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

test_zsh_dotpath_from_symlink() {
  if ! command -v zsh >/dev/null 2>&1; then
    printf 'SKIP: zsh is not installed\n'
    return
  fi

  local home output dotpath runtime_dir
  home="$TEST_DIR/zsh-home"
  mkdir -p "$home"
  ln -s "$REPO_ROOT/zsh/.zshenv" "$home/.zshenv"

  output="$(
    env -u DOTPATH -u ZDOTDIR -u XDG_RUNTIME_DIR HOME="$home" zsh -c \
      'printf "%s\n%s\n" "$DOTPATH" "$XDG_RUNTIME_DIR"; test -d "$XDG_RUNTIME_DIR"'
  )"
  dotpath="$(printf '%s\n' "$output" | sed -n '1p')"
  runtime_dir="$(printf '%s\n' "$output" | sed -n '2p')"

  assert_eq "$REPO_ROOT" "$dotpath" "zsh resolves DOTPATH from .zshenv symlink"
  assert_eq "$home/.temp" "$runtime_dir" "zsh creates default XDG_RUNTIME_DIR"
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

test_zsh_dotpath_from_symlink
test_bash_dotpath_from_symlink
