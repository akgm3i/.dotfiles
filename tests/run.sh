#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

for test_file in "$REPO_ROOT"/tests/test_*.sh; do
  printf '\n==> %s\n' "${test_file#"$REPO_ROOT"/}"
  "$test_file"
done
