#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
TEST_DIR="$(mktemp -d)"
trap 'rm -rf "$TEST_DIR"' EXIT

ZSH_BIN="$(command -v zsh || true)"
if [ -z "$ZSH_BIN" ]; then
  printf 'SKIP: zsh is not installed\n'
  exit 0
fi

assert_eq() {
  local expected="$1"
  local actual="$2"
  local test_name="$3"

  if [ "$expected" = "$actual" ]; then
    printf 'PASS: %s\n' "$test_name"
  else
    printf 'FAIL: %s\nexpected: %s\nactual:   %s\n' \
      "$test_name" "$expected" "$actual" >&2
    exit 1
  fi
}

assert_contains() {
  local value="$1"
  local pattern="$2"
  local test_name="$3"

  if grep -Eq -- "$pattern" <<< "$value"; then
    printf 'PASS: %s\n' "$test_name"
  else
    printf 'FAIL: %s\nmissing pattern: %s\nvalue: %s\n' \
      "$test_name" "$pattern" "$value" >&2
    exit 1
  fi
}

make_stubs() {
  local destination="$1"
  shift

  mkdir -p "$destination"
  local command_name
  for command_name in "$@"; do
    ln -s "$REPO_ROOT/tests/fixtures/motd-command-stub.sh" \
      "$destination/$command_name"
  done
}

test_startup_is_opt_in() {
  local secret_dir output
  secret_dir="$TEST_DIR/secrets"
  mkdir -p "$secret_dir"

  output="$(
    ZDOTDIR="$secret_dir" MOTD_DEINIT="$REPO_ROOT/zsh/99_deinit.zsh" \
      "$ZSH_BIN" -f -ic \
      'unset DOTFILES_MOTD_ON_START
       motd() { print -r -- called; }
       source "$MOTD_DEINIT"' 2>/dev/null
  )"
  assert_eq "" "$output" "interactive startup does not run motd by default"

  output="$(
    ZDOTDIR="$secret_dir" DOTFILES_MOTD_ON_START=1 \
      MOTD_DEINIT="$REPO_ROOT/zsh/99_deinit.zsh" \
      "$ZSH_BIN" -f -ic \
      'motd() { print -r -- called; }
       source "$MOTD_DEINIT"' 2>/dev/null
  )"
  assert_eq "called" "$output" "interactive startup can opt in to motd"
}

test_small_terminal_short_circuits() {
  local fake_bin log output
  fake_bin="$TEST_DIR/small-bin"
  log="$TEST_DIR/small-commands.log"
  : > "$log"

  make_stubs "$fake_bin" \
    git uname uptime df awk sw_vers free tput hostname whoami stat date \
    cat grep cut tr wc top lsb_release \
    brew mise curl wget gh ssh apt apt-get softwareupdate

  output="$(
    MOTD_COMMAND_LOG="$log" PATH="$fake_bin:$PATH" \
      LINES=5 COLUMNS=40 "$ZSH_BIN" "$REPO_ROOT/bin/motd"
  )"

  assert_eq "" "$output" "small terminal produces no output"
  assert_eq "" "$(cat "$log")" "small terminal collects no system information"
}

test_summary_is_local_only() {
  local fake_bin log output forbidden
  fake_bin="$TEST_DIR/local-bin"
  log="$TEST_DIR/local-commands.log"
  mkdir -p "$TEST_DIR/repo/.git"
  : > "$log"

  make_stubs "$fake_bin" \
    git brew mise curl wget gh ssh apt apt-get softwareupdate

  output="$(
    MOTD_COMMAND_LOG="$log" PATH="$fake_bin:$PATH" \
      DOTPATH="$TEST_DIR/repo" LINES=24 COLUMNS=100 \
      "$ZSH_BIN" "$REPO_ROOT/bin/motd"
  )"

  assert_contains "$output" 'Dotfiles: feature/test, dirty, ahead 2, behind 1' \
    "summary uses the configured branch and its upstream"
  assert_contains "$(cat "$log")" '^git .* status --porcelain' \
    "summary inspects local git status"

  forbidden='^(brew|mise|curl|wget|gh|ssh|apt|apt-get|softwareupdate) |^git .* (fetch|pull|push|clone|ls-remote)( |$)'
  if grep -Eq -- "$forbidden" "$log"; then
    printf 'FAIL: summary invoked a network or update command\n' >&2
    cat "$log" >&2
    exit 1
  fi
  printf 'PASS: summary invokes no network or update commands\n'
}

test_startup_is_opt_in
test_small_terminal_short_circuits
test_summary_is_local_only
