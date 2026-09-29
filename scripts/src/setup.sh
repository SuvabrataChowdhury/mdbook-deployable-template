#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/setup_child_github.sh"

set -euo pipefail

setup() {
	BOOK_TITLE=$1
	AUTHOR_NAME=$2
	REPO_URL=$3

	echo ""
	echo "📁 Setting up directories..."

	# Remove existing mdbook files except the theme
	cp -r ./src/theme ./
	rm -rf ./src
	mv ./book.toml ./book.toml.tmp # backup copy of book.toml

	# Use mdbook to build author's project
	mdbook init --title "$BOOK_TITLE" --ignore none .

	# Initialize book.toml with user's info
	mv ./book.toml.tmp ./book.toml 

	yq -i ".book.title = \"$BOOK_TITLE\"" book.toml
	yq -i ".book.authors = [\"$AUTHOR_NAME\"]" book.toml
	yq -i ".output.html[\"git-repository-url\"] |= \"$REPO_URL\"" book.toml
	yq -i "del(.output.html[\"site-url\"])" book.toml

	echo "✅ Created book.toml with your project details"

	# Move theme back into src
	mv theme src/
	echo "✅ Created theme for your project"

	# Create sample README
	cat > README.md << EOF
# Introduction

Welcome to **$BOOK_TITLE**!

This is your book. Write your content here in Markdown format.

## Getting Started

- Edit files in the \`src/\` directory
- Update \`src/SUMMARY.md\` to add/remove chapters
- Run \`mdbook serve\` to preview changes locally
- Push to GitHub to deploy automatically

Learn more: [mdbook documentation](https://rust-lang.github.io/mdBook/)
EOF
	echo "✅ Created sample README.md"

	# cspell.config.yml changes
	yq '.words = ["mermaid", "mdbook", "latex", "katex"]' -i cspell.config.yml

	read -ra AUTHOR_NAME_PARTS <<< "$AUTHOR_NAME"
	for name_part in "${AUTHOR_NAME_PARTS[@]}"; do
		NAME_PART="$name_part" yq '.words += [env(NAME_PART)]' -i cspell.config.yml
	done

	# Include child repo's pr and issue templates
	setup-child-github

	# Remove LICENSE, CONTRIBUTING.md and architecture in child repo as author should add them manually if needed.
	rm -f LICENSE
	rm -f CONTRIBUTING.md
	rm -f architecture.excalidraw

	# Remove init.sh so that script does not changes itself
	rm -f init.sh
	rm -f ./scripts/src/init.sh

	# Test if mdbook can build
	if mdbook build --dry-run > /dev/null 2>&1; then
		echo "✅ mdbook build test passed"
	else
		echo "⚠️  mdbook build encountered an issue"
		echo "   Try running: mdbook serve"
	fi
}

# Only call setup when executed directly, not when sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup "$@"
fi

