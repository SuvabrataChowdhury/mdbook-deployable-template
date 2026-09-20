#!/usr/bin/env bash

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
	rm -rf ./book.toml

	# Use mdbook to build author's project
	mdbook init --title "$BOOK_TITLE" --ignore none .

	# Initialize book.toml with user's info
	cat > book.toml << EOF
[book]
title = "$BOOK_TITLE"
authors = ["$AUTHOR_NAME"]
language = "en"

[output.html]
git-repository-url = "$REPO_URL"
mathjax-support = false
smart-punctuation = false
theme = "src/theme"
EOF

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
	rm -rf .github/ISSUE_TEMPLATE/*
	rm -f .github/PULL_REQUEST_TEMPLATE.md
	rm -f .github/dependabot.yml	# TODO: check if removing dependabot is a good idea for child repo
	rm -f .github/workflows/lint_pr.yml  # as child repo does not need these checks
	rm -f .github/workflows/release.yml  # child repos do not have releases

	cp -r .child-github/ISSUE_TEMPLATE .github/
	cp .child-github/PULL_REQUEST_TEMPLATE.md .github/

	# Remove LICENSE and CONTRIBUTING.md in child repo as author should add them manually if needed.
	rm -f LICENSE
	rm -f CONTRIBUTING.md

	# Test if mdbook can build
	if mdbook build --dry-run > /dev/null 2>&1; then
		echo "✅ mdbook build test passed"
	else
		echo "⚠️  mdbook build encountered an issue"
		echo "   Try running: mdbook serve"
	fi

}

