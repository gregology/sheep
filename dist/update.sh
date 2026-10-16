#!/usr/bin/env bash
# Downloads the newest Sheep! release from GitHub and installs it:
#     ~/Games/sheep/update.sh            (add --force to reinstall the same version)
#
# No login is needed while the repository is public. If it is ever made private,
# save a read-only GitHub token once and this script will use it:
#     mkdir -p ~/.config/sheep && echo YOUR_TOKEN > ~/.config/sheep/github-token
set -euo pipefail

REPO="${SHEEP_REPO:-gregology/sheep}"
TOKEN_FILE="${HOME}/.config/sheep/github-token"
TOKEN="${GITHUB_TOKEN:-$(cat "${TOKEN_FILE}" 2>/dev/null || true)}"
api() {
	if [ -n "${TOKEN}" ]; then
		curl -fsSL -H "Authorization: Bearer ${TOKEN}" -H "X-GitHub-Api-Version: 2022-11-28" "$@"
	else
		curl -fsSL -H "X-GitHub-Api-Version: 2022-11-28" "$@"
	fi
}

release="$(api "https://api.github.com/repos/${REPO}/releases/latest")"
tag="$(printf '%s' "${release}" | python3 -c 'import json,sys; print(json.load(sys.stdin)["tag_name"])')"
asset="$(printf '%s' "${release}" | python3 -c '
import json, sys
for a in json.load(sys.stdin)["assets"]:
    if a["name"].endswith("-linux.tar.gz"):
        print(a["url"]); break
')"
if [ -z "${asset}" ]; then
	echo "Release ${tag} has no Linux build attached." >&2
	exit 1
fi
current="$(cat "${HOME}/Games/sheep/VERSION" 2>/dev/null || echo none)"
if [ "${current}" = "${tag}" ] && [ "${1:-}" != "--force" ]; then
	echo "Already on the newest version (${tag})."
	exit 0
fi

work="$(mktemp -d)"
trap 'rm -rf "${work}"' EXIT
echo "Downloading ${tag}..."
api -H "Accept: application/octet-stream" -o "${work}/sheep.tar.gz" "${asset}"
tar -C "${work}" -xzf "${work}/sheep.tar.gz"
"${work}/sheep/install.sh"
