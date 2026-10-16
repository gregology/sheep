# Sheep! — common tasks. `make help` lists them.
GODOT ?= .tools/godot
VERSION ?= $(shell git describe --tags --always --dirty 2>/dev/null || echo dev)
DEMO ?= round

.PHONY: help import test run demo balance shots models sounds export package clean

help: ## Show this list
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  make %-9s %s\n", $$1, $$2}'

$(GODOT):
	tools/fetch_godot.sh

import: $(GODOT) ## Import assets (run after pulling new files)
	$(GODOT) --headless --path . --import >/dev/null 2>&1 || true

test: import ## Run the unit tests
	$(GODOT) --headless --path . -s res://tests/run_tests.gd

run: import ## Play the game in a window
	$(GODOT) --path . --windowed

demo: import ## Watch robot players (DEMO=join|round|celebrate)
	$(GODOT) --path . --windowed -- --demo=$(DEMO)

balance: import ## Time three robot-herded rounds, headless
	@for i in 1 2 3; do \
		$(GODOT) --headless --path . --fixed-fps 60 --quit-after 36000 -- --demo=round --quit-when-won 2>/dev/null | grep DEMO_WON || echo "round $$i: not won in 10 minutes"; \
	done

shots: import ## Render screenshots of each demo scene into build/shots
	tools/screenshots.sh build/shots

models: ## Rebuild the creature models with Blender (assets/models/*.glb)
	tools/blender/build_models.sh
	$(MAKE) import

sounds: ## Rebuild the CC0 sound effects and music with ffmpeg (assets/audio/)
	python3 tools/audio/build_sounds.py
	$(MAKE) import

export: import ## Build the Linux game into build/linux
	tools/fetch_godot.sh templates
	mkdir -p build/linux
	$(GODOT) --headless --path . --export-release "Linux" build/linux/sheep.x86_64

package: export ## Make the release tarball for the Steam Machine
	tools/package.sh $(VERSION)

clean: ## Remove build output and the import cache
	rm -rf build .godot
