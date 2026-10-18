#!/usr/bin/env bash
# Renders the Steam library artwork from the game itself into dist/steam/.
# Needs a display (or xvfb-run, which is used automatically when there isn't one).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="${GODOT:-${ROOT}/.tools/godot}"
OUT="${ROOT}/dist/steam"
mkdir -p "${OUT}"
run=("${GODOT}" --path "${ROOT}" --windowed --resolution 1280x720 -- --demo=artwork "--out=${OUT}")
if [ -z "${DISPLAY:-}" ] && [ -z "${WAYLAND_DISPLAY:-}" ]; then
	run=(xvfb-run -a -s "-screen 0 1280x720x24" "${run[@]:0:1}" --rendering-driver vulkan "${run[@]:1}")
fi
"${run[@]}" 2>&1 | grep -E '^ARTWORK|ERROR' || true
ls -la "${OUT}"
