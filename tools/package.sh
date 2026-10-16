#!/usr/bin/env bash
# Bundles the exported game with its installer into build/sheep-<version>-linux.tar.gz
set -euo pipefail
VERSION="${1:-dev}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
STAGE="${ROOT}/build/package/sheep"
rm -rf "${ROOT}/build/package"
mkdir -p "${STAGE}"
cp "${ROOT}/build/linux/sheep.x86_64" "${STAGE}/"
cp "${ROOT}/dist/install.sh" "${ROOT}/dist/update.sh" "${ROOT}/dist/steam_artwork.py" "${STAGE}/"
cp -r "${ROOT}/dist/steam" "${STAGE}/steam"
cp "${ROOT}/assets/fonts/Fredoka-OFL.txt" "${STAGE}/LICENSE-Fredoka-font.txt"
echo "${VERSION}" > "${STAGE}/VERSION"
chmod +x "${STAGE}/sheep.x86_64" "${STAGE}/install.sh" "${STAGE}/update.sh" "${STAGE}/steam_artwork.py"
tar -C "${ROOT}/build/package" -czf "${ROOT}/build/sheep-${VERSION}-linux.tar.gz" sheep
echo "build/sheep-${VERSION}-linux.tar.gz"
