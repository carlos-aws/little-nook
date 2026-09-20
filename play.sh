#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
if [[ -x build/linux/little-nook.x86_64 ]]; then
  exec build/linux/little-nook.x86_64 "$@"
fi
godot_bin="${GODOT_BIN:-godot}"
if command -v "$godot_bin" >/dev/null; then
  exec "$godot_bin" --path . "$@"
fi
echo "Open project.godot with Godot 4.7.2, or set GODOT_BIN to its executable." >&2
echo "To make a standalone Linux build: bash tools/export.sh Linux" >&2
exit 1
