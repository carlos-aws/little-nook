#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
godot_bin="${GODOT_BIN:-godot}"
if ! command -v "$godot_bin" >/dev/null; then
  echo "Godot was not found. Install Godot 4.7.2, or set GODOT_BIN to its executable." >&2
  exit 1
fi
# Isolate test progress from the player's save.
test_dir="$(mktemp -d)"
trap 'rm -rf "$test_dir"' EXIT
export XDG_DATA_HOME="$test_dir/data"
export XDG_CONFIG_HOME="$test_dir/config"
export XDG_CACHE_HOME="$test_dir/cache"
"$godot_bin" --headless --path . --editor --import --quit > "$test_dir/import.log" 2>&1
if grep -nE 'SCRIPT ERROR|Parse Error|ERROR:' "$test_dir/import.log"; then
  cat "$test_dir/import.log"
  exit 1
fi
"$godot_bin" --headless --path . --script tests/test_rules.gd 2>&1 | tee "$test_dir/rules.log"
"$godot_bin" --headless --path . -- --ui-test 2>&1 | tee "$test_dir/ui.log"
if grep -nE 'SCRIPT ERROR|Parse Error|ERROR:|leaked at exit' "$test_dir/rules.log" "$test_dir/ui.log"; then
  exit 1
fi
echo "All Godot checks passed."
