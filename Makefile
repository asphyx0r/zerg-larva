SHELL := /usr/bin/env bash

SCRIPT_FILE := zerg-larva.sh

# Template metadata (overrideable: make release VERSION=v1.0.13 AUTHOR_NAME="..." ...)
APPNAME            ?= zerg-larva
VERSION            ?= v1.0.12
RELEASE_DATE       ?= $(shell date -u +%Y-%m-%d)
SCRIPT_NAME        ?= $(SCRIPT_FILE)
SCRIPT_DESCRIPTION ?= zerg-larva Bash template for zerg-tools
AUTHOR_NAME        ?= $(shell git config user.name 2>/dev/null || echo unknown)
AUTHOR_EMAIL       ?= $(shell git config user.email 2>/dev/null || echo unknown)
LICENSE_ID         ?= MIT
REPOSITORY_URL     ?= $(shell git config --get remote.origin.url 2>/dev/null || echo unknown)

.PHONY: release release-check

release:
	@set -euo pipefail; \
	f="$(SCRIPT_FILE)"; \
	esc_sed() { printf '%s' "$$1" | sed -e 's/[\\&/]/\\&/g'; }; \
	app="$$(esc_sed "$(APPNAME)")"; \
	ver="$$(esc_sed "$(VERSION)")"; \
	dat="$$(esc_sed "$(RELEASE_DATE)")"; \
	snm="$$(esc_sed "$(SCRIPT_NAME)")"; \
	sds="$$(esc_sed "$(SCRIPT_DESCRIPTION)")"; \
	anm="$$(esc_sed "$(AUTHOR_NAME)")"; \
	aem="$$(esc_sed "$(AUTHOR_EMAIL)")"; \
	lic="$$(esc_sed "$(LICENSE_ID)")"; \
	rep="$$(esc_sed "$(REPOSITORY_URL)")"; \
	cp -a "$$f" "$$f.bak"; \
	sed -i \
	  -e "s/__APPNAME__/$$app/g" \
	  -e "s/__VERSION__/$$ver/g" \
	  -e "s/__RELEASE_DATE__/$$dat/g" \
	  -e "s/__SCRIPT_NAME__/$$snm/g" \
	  -e "s/__SCRIPT_DESCRIPTION__/$$sds/g" \
	  -e "s/__AUTHOR_NAME__/$$anm/g" \
	  -e "s/__AUTHOR_EMAIL__/$$aem/g" \
	  -e "s/__LICENSE_ID__/$$lic/g" \
	  -e "s/__REPOSITORY_URL__/$$rep/g" \
	  "$$f"; \
	$(MAKE) release-check

release-check:
	@set -euo pipefail; \
	f="$(SCRIPT_FILE)"; \
	if grep -nE '__[A-Z0-9_]+__' "$$f" >/dev/null; then \
	  echo "ERROR: unresolved tokens remain in $$f:" >&2; \
	  grep -nE '__[A-Z0-9_]+__' "$$f" >&2; \
	  exit 1; \
	fi; \
	echo "OK: tokens updated in $$f"
