#!/usr/bin/env bash
# Installs Sheep! on a Steam Machine (or any Linux PC) and adds it to Steam.
# Run it from Desktop Mode, in the unpacked folder:   ./install.sh
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
DEST="${HOME}/Games/sheep"

if pgrep -f "${DEST}/sheep.x86_64" >/dev/null 2>&1; then
	echo "Sheep! is running. Quit it first (Steam button > Exit game), then run this again." >&2
	exit 1
fi

mkdir -p "${DEST}"
cp "${HERE}/sheep.x86_64" "${HERE}/update.sh" "${HERE}/steam_artwork.py" "${HERE}/VERSION" "${DEST}/"
cp "${HERE}"/LICENSE-* "${DEST}/" 2>/dev/null || true
rm -rf "${DEST}/steam"
cp -r "${HERE}/steam" "${DEST}/steam"
cp "${HERE}/steam/icon.png" "${DEST}/icon.png"
chmod +x "${DEST}/sheep.x86_64" "${DEST}/update.sh" "${DEST}/steam_artwork.py"

# A desktop entry, so it shows up in the app menu.
mkdir -p "${HOME}/.local/share/applications"
cat > "${HOME}/.local/share/applications/sheep.desktop" <<DESKTOP
[Desktop Entry]
Type=Application
Name=Sheep!
Comment=Couch co-op sheep herding with a chaos player
Exec=${DEST}/sheep.x86_64
Path=${DEST}
Icon=${DEST}/icon.png
Categories=Game;
DESKTOP

echo "Installed Sheep! $(cat "${DEST}/VERSION") to ${DEST}"

if [ "${SHEEP_SKIP_STEAM:-}" = "1" ]; then
	exit 0
fi
# SteamOS ships a helper that adds a non-Steam game to the library (Steam must be running).
if command -v steamos-add-to-steam >/dev/null 2>&1; then
	if grep -qs "sheep.x86_64" "${HOME}"/.local/share/Steam/userdata/*/config/shortcuts.vdf; then
		echo "Sheep! is already in your Steam library."
	else
		steamos-add-to-steam "${HOME}/.local/share/applications/sheep.desktop" && \
			echo "Added to Steam: look under Library > Non-Steam."
	fi
	python3 "${DEST}/steam_artwork.py" "${DEST}/steam" "${DEST}/sheep.x86_64" 20 || true
else
	echo "Now add it to Steam: Steam > Games > Add a Non-Steam Game to My Library > Sheep!"
fi
