#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/setup_child_github.sh"

CUSTOMIZABLE_FILES=("src" "book.toml" "CONTRIBUTING.md" "LICENSE" "README.md" "architecture.excalidraw" "cspell.config.yml")

rm -rf "${CUSTOMIZABLE_FILES[@]}"

setup-child-github
