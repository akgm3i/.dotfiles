#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
TEST_DIR="$(mktemp -d)"
trap 'rm -rf "$TEST_DIR"' EXIT

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local test_name="$3"

  case "$haystack" in
    *"$needle"*) printf 'PASS: %s\n' "$test_name" ;;
    *) fail "$test_name" ;;
  esac
}

test_runtime_versions() {
  local config
  config="$(cat "$REPO_ROOT/mise/config.toml")"

  assert_contains "$config" 'deno = "2.9"' "Deno follows the current LTS line"
  assert_contains "$config" 'go = "1.26"' "Go follows the current stable line"
  assert_contains "$config" 'node = "24"' "Node follows the active LTS line"
  assert_contains "$config" 'python = "3.14"' "Python follows the current feature line"
  assert_contains "$config" 'rust = "1.97"' "Rust follows the current stable line"
  assert_contains "$config" 'neovim = "latest"' "The configured editor is installed by mise"
}

test_tool_bins_are_on_path() {
  local home xdg_data output
  home="$TEST_DIR/home"
  xdg_data="$home/.local/share"
  mkdir -p "$xdg_data/go/bin" "$xdg_data/npm/bin"

  output="$(
    env -u GOPATH \
      HOME="$home" \
      DOTPATH="$REPO_ROOT" \
      XDG_DATA_HOME="$xdg_data" \
      PATH="/usr/bin:/bin" \
      sh -c '. "$DOTPATH/shell/env.sh"; printf "%s" "$PATH"'
  )"

  assert_contains "$output" "$xdg_data/go/bin" "GOPATH binaries are discoverable"
  assert_contains "$output" "$xdg_data/npm/bin" "npm global binaries are discoverable"
}

test_npm_config_uses_supported_paths() {
  if grep -q '^tmp=' "$REPO_ROOT/npm/npmrc"; then
    fail "npm config does not use the removed tmp setting"
  fi

  printf 'PASS: npm config does not use the removed tmp setting\n'
}

test_lockfile_covers_supported_platforms() {
  local lockfile tool
  lockfile="$REPO_ROOT/mise/mise.lock"

  [ -s "$lockfile" ] || fail "mise lockfile exists"

  for tool in antigravity-cli bat codex deno eza fd fzf gh ghq go jq neovim node python rust usage; do
    grep -qF "[[tools.$tool]]" "$lockfile" ||
      fail "mise lockfile contains $tool"
  done

  grep -qF 'platforms.linux-x64' "$lockfile" ||
    fail "mise lockfile covers Linux x64"
  grep -qF 'platforms.macos-arm64' "$lockfile" ||
    fail "mise lockfile covers macOS arm64"

  printf 'PASS: mise lockfile covers configured tools and platforms\n'
}

test_runtime_versions
test_tool_bins_are_on_path
test_npm_config_uses_supported_paths
test_lockfile_covers_supported_platforms
