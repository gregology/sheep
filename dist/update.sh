#!/usr/bin/env bash
# Downloads the newest Sheep! release from GitHub and installs it.
#
# The repository is private, so this needs a GitHub token that can read it:
# make a fine-grained token (github.com > Settings > Developer settings) with
# read-only "Contents" access to gregology/sheep, then save it once:
#     mkdir -p ~/.config/sheep && echo YOUR_TOKEN > ~/.config/sheep/github-token
# After that, from Desktop Mode:   ~/Games/sheep/update.sh
set -euo pipefail

REPO="${SHEEP_REPO:-gregology/sheep}"
TOKEN_FILE="${HOME}/.config/sheep/github-token"
TOKEN="${GITHUB_TOKEN:-$(cat "${TOKEN_FILE}" 2>/dev/null || true)}"
if [ -z "${TOKEN}" ]; then
	echo "No GitHub token found. See the instructions at the top of this script." >&2
	exit 1
fi
api() { curl -fsSL -H "Authorization: Bearer ${TOKEN}" -H "X-GitHub-Api-Version: 2022-11-28" "$@"; }

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
