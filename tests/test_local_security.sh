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
  local expected="$2"
  local test_name="$3"

  if grep -qF -- "$expected" <<< "$value"; then
    printf 'PASS: %s\n' "$test_name"
  else
    printf 'FAIL: %s\nmissing: %s\nvalue: %s\n' \
      "$test_name" "$expected" "$value" >&2
    exit 1
  fi
}

assert_not_contains() {
  local value="$1"
  local unexpected="$2"
  local test_name="$3"

  if grep -qF -- "$unexpected" <<< "$value"; then
    printf 'FAIL: %s\nunexpected: %s\nvalue: %s\n' \
      "$test_name" "$unexpected" "$value" >&2
    exit 1
  fi
  printf 'PASS: %s\n' "$test_name"
}

run_secret_loader() {
  local config_home="$1"
  local zdotdir="$2"

  HOME="$TEST_DIR/home" XDG_CONFIG_HOME="$config_home" ZDOTDIR="$zdotdir" \
    SECRET_LOADER="$REPO_ROOT/zsh/99_deinit.zsh" \
    "$ZSH_BIN" -fc \
    'unset DOTFILES_TEST_SECRET
     source "$SECRET_LOADER"
     print -r -- "${DOTFILES_TEST_SECRET:-not-loaded}"' 2>&1
}

test_private_secret_is_loaded() {
  local config_home="$TEST_DIR/private-config"
  local zdotdir="$TEST_DIR/private-zdotdir"
  local secret_file="$config_home/dotfiles/secrets.zsh"
  mkdir -p "${secret_file%/*}" "$zdotdir"
  printf '%s\n' "export DOTFILES_TEST_SECRET='loaded'" > "$secret_file"
  chmod 600 "$secret_file"

  assert_eq "loaded" "$(run_secret_loader "$config_home" "$zdotdir")" \
    "owner-only external secret is loaded"
}

test_public_secret_is_rejected_without_leaking() {
  local config_home="$TEST_DIR/public-config"
  local zdotdir="$TEST_DIR/public-zdotdir"
  local secret_file="$config_home/dotfiles/secrets.zsh"
  local output
  mkdir -p "${secret_file%/*}" "$zdotdir"
  printf '%s\n' "export DOTFILES_TEST_SECRET='must-not-leak'" > "$secret_file"
  chmod 644 "$secret_file"

  output="$(run_secret_loader "$config_home" "$zdotdir")"
  assert_contains "$output" "run chmod 600" \
    "group-readable external secret is rejected"
  assert_contains "$output" "not-loaded" \
    "rejected external secret is not sourced"
  assert_not_contains "$output" "must-not-leak" \
    "warning does not expose the rejected secret"
}

test_symlink_secret_is_rejected() {
  local config_home="$TEST_DIR/symlink-config"
  local zdotdir="$TEST_DIR/symlink-zdotdir"
  local secret_file="$config_home/dotfiles/secrets.zsh"
  local target="$TEST_DIR/secret-target.zsh"
  local output
  mkdir -p "${secret_file%/*}" "$zdotdir"
  printf '%s\n' "export DOTFILES_TEST_SECRET='symlink-value'" > "$target"
  chmod 600 "$target"
  ln -s "$target" "$secret_file"

  output="$(run_secret_loader "$config_home" "$zdotdir")"
  assert_contains "$output" "expected a regular, non-symlink file" \
    "symlink secret is rejected"
  assert_contains "$output" "not-loaded" \
    "symlink secret is not sourced"
  assert_not_contains "$output" "symlink-value" \
    "warning does not expose the symlinked secret"
}

test_legacy_secret_warns_without_loading() {
  local config_home="$TEST_DIR/legacy-config"
  local zdotdir="$TEST_DIR/legacy-zdotdir"
  local legacy_file="$zdotdir/my-secret.zsh"
  local output
  mkdir -p "$config_home" "$zdotdir"
  printf '%s\n' "export DOTFILES_TEST_SECRET='legacy-value'" > "$legacy_file"
  chmod 600 "$legacy_file"

  output="$(run_secret_loader "$config_home" "$zdotdir")"
  assert_contains "$output" "repository-local secret files are no longer loaded" \
    "legacy secret emits a migration warning"
  assert_contains "$output" "not-loaded" \
    "legacy secret is not sourced"
  assert_not_contains "$output" "legacy-value" \
    "migration warning does not expose the legacy secret"
}

test_global_ignore_keeps_generic_tmp_visible() {
  local excludes_file="$REPO_ROOT/git/ignore"

  if git -C "$REPO_ROOT" -c core.excludesFile="$excludes_file" \
    check-ignore -q -- "dotfiles-security-source.tmp"; then
    printf 'FAIL: generic .tmp source is globally ignored\n' >&2
    exit 1
  fi
  printf 'PASS: generic .tmp source remains visible to git\n'

  if git -C "$REPO_ROOT" -c core.excludesFile="$excludes_file" \
    check-ignore -q -- '~$dotfiles-security-report.docx'; then
    printf 'PASS: Microsoft Office temporary file remains ignored\n'
  else
    printf 'FAIL: Microsoft Office temporary file is not ignored\n' >&2
    exit 1
  fi
}

test_migration_files_remain_ignored() {
  if git -C "$REPO_ROOT" check-ignore -q -- "zsh/local-secret.zsh"; then
    printf 'PASS: legacy Zsh secret remains guarded from commits\n'
  else
    printf 'FAIL: legacy Zsh secret is not ignored during migration\n' >&2
    exit 1
  fi

  if git -C "$REPO_ROOT" check-ignore -q -- "gh/hosts.yml"; then
    printf 'PASS: GitHub hosts credentials remain guarded from commits\n'
  else
    printf 'FAIL: GitHub hosts credentials are not ignored during migration\n' >&2
    exit 1
  fi
}

test_private_secret_is_loaded
test_public_secret_is_rejected_without_leaking
test_symlink_secret_is_rejected
test_legacy_secret_warns_without_loading
test_global_ignore_keeps_generic_tmp_visible
test_migration_files_remain_ignored
