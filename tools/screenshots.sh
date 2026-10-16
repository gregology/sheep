#!/usr/bin/env bash
# Renders a frame from each demo scenario using a virtual display, for checking visuals
# without a monitor. Slow on software rendering (minutes), fine on a real GPU.
#   tools/screenshots.sh [out_dir] [seconds_into_round]
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${1:-${ROOT}/build/shots}"
GODOT="${GODOT:-${ROOT}/.tools/godot}"
RES="${RES:-1280x720}"
mkdir -p "${OUT}"
capture() {  # name scenario seconds
	local tmp
	tmp="$(mktemp -d)"
	local frames=$(( $3 * 10 ))
	xvfb-run -a -s "-screen 0 ${RES}x24" "${GODOT}" --path "${ROOT}" --rendering-driver vulkan \
		--resolution "${RES}" --write-movie "${tmp}/f.png" --fixed-fps 10 --quit-after "${frames}" \
		-- --demo="$2" >/dev/null 2>&1 || true
	local last
	last="$(ls "${tmp}"/f*.png 2>/dev/null | tail -1)"
	if [ -n "${last}" ]; then cp "${last}" "${OUT}/$1.png"; echo "${OUT}/$1.png"; else echo "no frames for $1" >&2; fi
	rm -rf "${tmp}"
}
capture join join 3
capture round round "${2:-12}"
capture celebrate celebrate 5
