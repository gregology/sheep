#!/usr/bin/env bash
# Exports the creature models to assets/models/ with Blender (no GUI needed).
# Blender's glTF exporter needs numpy; if this Blender's Python lacks it, numpy is
# installed into .tools/blender-site (with uv) and handed to Blender.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
BLENDER="${BLENDER:-blender}"
SITE="${ROOT}/.tools/blender-site"

if ! "${BLENDER}" --background --factory-startup --python-exit-code 1 --python-expr "import numpy" >/dev/null 2>&1; then
	if [ ! -d "${SITE}/numpy" ]; then
		py="$("${BLENDER}" --background --factory-startup --python-expr "import sys; print('PY', sys.executable)" 2>/dev/null | awk '/^PY /{print $2}')"
		echo "Installing numpy for Blender's Python (${py}) into .tools/blender-site"
		uv pip install --quiet --target "${SITE}" --python "${py}" numpy
	fi
	export PYTHONPATH="${SITE}${PYTHONPATH:+:${PYTHONPATH}}"
fi

"${BLENDER}" --background --factory-startup --python-use-system-env \
	--python "${ROOT}/tools/blender/build_models.py" -- "${ROOT}/assets/models" 2>&1 \
	| grep -E '^MODEL|Error|Traceback|line [0-9]+' || true
