#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
godot_bin="${GODOT_BIN:-godot}"
target="${1:-Web}"
case "$target" in
  Web) mkdir -p build/web; output="build/web/index.html" ;;
  Linux) mkdir -p build/linux; output="build/linux/little-nook.x86_64" ;;
  *) echo "Usage: tools/export.sh [Web|Linux]" >&2; exit 1 ;;
esac
touch build/.gdignore
"$godot_bin" --headless --path . --export-release "$target" "$output"
output_dir="$(dirname "$output")"
mkdir -p "$output_dir/licenses"
cp LICENSE THIRD_PARTY.md "$output_dir/"
cp licenses/*.txt assets/fonts/OFL-*.txt "$output_dir/licenses/"
if [[ "$target" == Web ]]; then
  python3 tools/finalize_web.py
fi
printf 'Built %s\n' "$output"
