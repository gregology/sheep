#!/usr/bin/env bash
# Downloads the pinned Godot editor (and optionally export templates) into .tools/,
# verifying each file against the official SHA512-SUMS.txt.
#
#   tools/fetch_godot.sh             # editor only
#   tools/fetch_godot.sh templates   # editor + Linux export templates
set -euo pipefail

GODOT_VERSION="${GODOT_VERSION:-4.7.2}"
TAG="${GODOT_VERSION}-stable"
BASE="https://github.com/godotengine/godot/releases/download/${TAG}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="${ROOT}/.tools/godot-${GODOT_VERSION}"
EDITOR_ZIP="Godot_v${TAG}_linux.x86_64.zip"
TEMPLATES_TPZ="Godot_v${TAG}_export_templates.tpz"

mkdir -p "${DEST}"
cd "${DEST}"

[ -f SHA512-SUMS.txt ] || curl -fsSL -o SHA512-SUMS.txt "${BASE}/SHA512-SUMS.txt"

fetch() {
	local name="$1"
	if [ ! -f "${name}" ]; then
		echo "Downloading ${name}..."
		curl -fsSL -o "${name}.part" "${BASE}/${name}"
		mv "${name}.part" "${name}"
	fi
	grep " ${name}\$" SHA512-SUMS.txt | sha512sum -c --quiet -
}

fetch "${EDITOR_ZIP}"
if [ ! -x godot ]; then
	unzip -oq "${EDITOR_ZIP}"
	mv "Godot_v${TAG}_linux.x86_64" godot
	chmod +x godot
fi

if [ "${1:-}" = "templates" ]; then
	TEMPLATE_DIR="${HOME}/.local/share/godot/export_templates/${GODOT_VERSION}.stable"
	if [ ! -f "${TEMPLATE_DIR}/linux_release.x86_64" ]; then
		fetch "${TEMPLATES_TPZ}"
		mkdir -p "${TEMPLATE_DIR}"
		# Only the Linux templates are needed; skip the other platforms.
		unzip -oq -j "${TEMPLATES_TPZ}" 'templates/linux_*.x86_64' 'templates/version.txt' -d "${TEMPLATE_DIR}"
		rm -f "${TEMPLATES_TPZ}"
	fi
fi

ln -sfn "godot-${GODOT_VERSION}/godot" "${ROOT}/.tools/godot"
echo "Godot ${GODOT_VERSION} ready at .tools/godot"
