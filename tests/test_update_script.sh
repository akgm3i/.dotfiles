#!/bin/bash
set -eo pipefail

# --- Test Setup ---
TEST_DIR=$(mktemp -d)
trap 'rm -rf "$TEST_DIR"' EXIT

# --- Test Utilities ---
assert_pass() {
  echo "✅ PASS: $1"
}
assert_fail() {
  echo "❌ FAIL: $1"
  exit 1
}
assert_contains() {
  local file_path="$1"
  local expected_content="$2"
  local test_name="$3"
  if grep -qF -- "$expected_content" "$file_path"; then
    assert_pass "$test_name"
  else
    echo "Expected to find: '$expected_content' in '$file_path'"
    assert_fail "$test_name"
  fi
}

# --- Test Cases ---
test_script_existence() {
  local test_name="Script existence and permissions"
  local script_path="scripts/update_zsh_docs.sh"
  if [ -f "$script_path" ] && [ -x "$script_path" ]; then assert_pass "$test_name"; else assert_fail "$test_name"; fi
}

test_plugin_list_generation() {
    local test_name="--plugins-only flag"
    local expected_plugins_md
    expected_plugins_md=$(cat <<'EOF'
- [test-user/test-plugin-1](https://github.com/test-user/test-plugin-1): Test description 1
- [test-user/test-plugin-2](https://github.com/test-user/test-plugin-2): Test description 2
EOF
)
    local output
    output=$(./scripts/update_zsh_docs.sh --plugins-only "tests/fixtures/plugins.toml")
    if [ "$output" == "$expected_plugins_md" ]; then assert_pass "$test_name"; else
        echo "Expected output:"; echo "$expected_plugins_md"; echo "Actual output:"; echo "$output"; assert_fail "$test_name"; fi
}

test_alias_list_generation() {
    local test_name="--aliases-only flag"
    local expected_aliases_md
    expected_aliases_md=$(cat <<'EOF'
### Category 1
| Alias | Command | Description |
| :--- | :--- | :--- |
| `t1` | `test command 1` | description 1 |
| `t2` | `test command 2` | description 2 |

### Category 2
| Alias | Command | Description |
| :--- | :--- | :--- |
| `t3` | `test command 3` | description 3 |
EOF
)
    local output
    output=$(./scripts/update_zsh_docs.sh --aliases-only "tests/fixtures/30_aliases.zsh")
    if diff -w <(echo "$expected_aliases_md") <(echo "$output") >/dev/null; then assert_pass "$test_name"; else
        echo "Expected output:"; echo "$expected_aliases_md"; echo "Actual output:"; echo "$output";
        echo "Diff:"; diff -w <(echo "$expected_aliases_md") <(echo "$output") || true; assert_fail "$test_name"; fi
}

test_readme_update() {
    local test_name="README.md full update"
    local temp_readme="$TEST_DIR/README.md"
    cp "tests/fixtures/README.md" "$temp_readme"

    local expected_section_content
    expected_section_content=$(cat <<'EOF'
## Zsh設定
### Plugins
- [test-user/test-plugin-1](https://github.com/test-user/test-plugin-1): Test description 1
- [test-user/test-plugin-2](https://github.com/test-user/test-plugin-2): Test description 2

### Aliases
### Category 1
| Alias | Command | Description |
| :--- | :--- | :--- |
| `t1` | `test command 1` | description 1 |
| `t2` | `test command 2` | description 2 |

### Category 2
| Alias | Command | Description |
| :--- | :--- | :--- |
| `t3` | `test command 3` | description 3 |

EOF
)
    # Run the script in its main mode
    ./scripts/update_zsh_docs.sh "tests/fixtures/plugins.toml" "tests/fixtures/30_aliases.zsh" "$temp_readme"

    # Extract the updated section from the temp README
    local updated_section
    updated_section=$(awk '/^## Zsh設定/,/^## Another Section/' "$temp_readme" | sed '$d')

    if diff -w <(echo "$expected_section_content") <(echo "$updated_section") >/dev/null; then
        assert_pass "$test_name"
    else
        echo "Expected section content:"; echo "$expected_section_content"
        echo "Actual section content:"; echo "$updated_section"
        echo "Diff:"; diff -w <(echo "$expected_section_content") <(echo "$updated_section") || true
        assert_fail "$test_name"
    fi
    assert_contains "$temp_readme" "## Another Section" "Unaffected following section check"
    assert_contains "$temp_readme" "# My Project" "Unaffected preceding section check"
}


# --- Run Tests ---
test_script_existence
test_plugin_list_generation
test_alias_list_generation
test_readme_update
