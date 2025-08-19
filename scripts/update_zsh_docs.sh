#!/bin/bash
# This script automatically updates the Zsh configuration in README.md

set -eo pipefail

generate_plugins_markdown() {
  local toml_file="$1"
  # Use awk to parse plugins.toml, capturing the comment above the github line.
  # Then, sort the output alphabetically.
  awk '
    {
      if (/^\s*#\s*.*/) {
        comment = $0;
        sub(/^\s*#\s*/, "", comment);
        next;
      }
      if (/github =/) {
        repo = $0;
        gsub(/.*github = '\''/, "", repo);
        gsub(/'\''/, "", repo);
        printf "%s\t- [%s](https://github.com/%s): %s\n", repo, repo, repo, comment;
        comment = ""; # Reset comment AFTER using it.
        next;
      }
    }
  ' "$toml_file" | sort -t $'\t' -k 1 | cut -f 2-
}

generate_aliases_markdown() {
  local aliases_file="$1"
  awk '
    function print_header() {
      print "| Alias | Command | Description |"
      print "| :--- | :--- | :--- |"
    }
    /^#[[:space:]][A-Za-z0-9-]+([[:space:]][A-Za-z0-9-]+)?$/ {
      if (category_name != "") { print "" }
      category_name = $0
      gsub(/^#[[:space:]]+/, "", category_name)
      print "### " category_name
      print_header()
      next
    }
    /^alias / {
      alias_name = $2; gsub(/=.*/, "", alias_name)
      command_str = $0; match(command_str, /'\''(.*)'\''/); command = substr(command_str, RSTART + 1, RLENGTH - 2)
      description = $0
      if (match(description, /#[[:space:]]+(.*)/)) {
        description = substr(description, RSTART + 1); gsub(/^[[:space:]]+/, "", description)
      } else { description = "" }
      printf "| `%s` | `%s` | %s |\n", alias_name, command, description
    }
  ' "$aliases_file"
}

update_readme() {
    local plugins_file="$1"
    local aliases_file="$2"
    local readme_file="$3"

    local plugins_docs
    plugins_docs=$(generate_plugins_markdown "$plugins_file")

    local aliases_docs
    aliases_docs=$(generate_aliases_markdown "$aliases_file")

    local full_docs
    full_docs=$(cat <<EOF
### Plugins
$plugins_docs

### Aliases
$aliases_docs

EOF
)

    # Use awk to replace the content in README.md
    local temp_readme
    temp_readme=$(mktemp)

    awk -v content="$full_docs" '
        BEGIN { in_section = 0 }
        /^## Zsh設定/ {
            print;
            print content;
            print "";
            in_section = 1;
            next;
        }
        /^## / {
            in_section = 0;
        }
        !in_section { print }
    ' "$readme_file" > "$temp_readme"

    mv "$temp_readme" "$readme_file"
}


# --- Main Logic ---
case "$1" in
    --plugins-only)
        if [ -z "$2" ]; then echo "Error: Missing input file for --plugins-only" >&2; exit 1; fi
        generate_plugins_markdown "$2"
        ;;
    --aliases-only)
        if [ -z "$2" ]; then echo "Error: Missing input file for --aliases-only" >&2; exit 1; fi
        generate_aliases_markdown "$2"
        ;;
    "")
        echo "Usage: $0 <plugins.toml> <aliases.zsh> <README.md>" >&2
        exit 1
        ;;
    *)
        if [ "$#" -ne 3 ]; then
            echo "Usage: $0 <plugins.toml> <aliases.zsh> <README.md>" >&2
            exit 1
        fi
        update_readme "$1" "$2" "$3"
        ;;
esac
