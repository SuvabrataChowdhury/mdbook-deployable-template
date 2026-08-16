#!/bin/bash

# mdbook-deployable-template initialization script
# Run this once after cloning a repo created from the template

set -e  # Exit on any error

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Initialize your mdbook project from the deployable template."
    echo ""
    echo "Options:"
    echo "  -t, --title <title>    Book title"
    echo "  -a, --author <name>    Author name"
    echo "  -r, --repo <url>       GitHub repository URL"
    echo "  -h, --help             Show this help message"
    echo ""
    echo "If options are omitted, the script will prompt interactively."
    echo ""
    echo "Example:"
    echo "  $0 --title \"My Book\" --author \"Jane Doe\" --repo https://github.com/jane/my-book"
}

BOOK_TITLE=""
AUTHOR_NAME=""
REPO_URL_ARG=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -t|--title)  BOOK_TITLE="$2";    shift 2 ;;
        -a|--author) AUTHOR_NAME="$2";   shift 2 ;;
        -r|--repo)   REPO_URL_ARG="$2";  shift 2 ;;
        -h|--help)   usage; exit 0 ;;
        *) echo "Unknown option: $1"; usage; exit 1 ;;
    esac
done

echo "🚀 Initializing your mdbook project..."
echo ""

# Check if Git is installed
if ! command -v git &> /dev/null; then
    echo "❌ Git is not installed. Please install Git first."
    echo "   Visit: https://git-scm.com/install"
    exit 1
fi

# Check if mdbook is installed
if ! command -v mdbook &> /dev/null; then
    echo "⚠️  mdbook is not installed."
    echo ""
    echo "Install mdbook from: https://rust-lang.github.io/mdBook/guide/installation.html"
    echo ""
    exit 1
fi

echo "✅ mdbook is installed"
echo ""

# Collect user information (prompt only for values not provided as arguments)
echo "📋 Project Configuration"
echo "========================"
echo ""

if [[ -z "$BOOK_TITLE" ]]; then
    read -p "📕 Book title: " BOOK_TITLE
    [[ -z "$BOOK_TITLE" ]] && { echo "❌ Book title is required."; exit 1; }
fi
if [[ -z "$AUTHOR_NAME" ]]; then
    read -p "✍️  Author name: " AUTHOR_NAME
    [[ -z "$AUTHOR_NAME" ]] && { echo "❌ Author name is required."; exit 1; }
fi

if [[ -n "$REPO_URL_ARG" ]]; then
    REPO_URL="$REPO_URL_ARG"
else
    read -p "🔗 GitHub repository URL: " REPO_URL
    [[ -z "$REPO_URL" ]] && { echo "❌ Repository URL is required."; exit 1; }
fi

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
# rm -rf ./theme # TODO: Add it back
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
echo "✅ Created sample src/README.md"

# Include child repo's pr and issue templates
rm -rf .github/ISSUE_TEMPLATE/*
rm -f .github/PULL_REQUEST_TEMPLATE.md
rm -f .github/dependabot.yml

cp -r .child-github/ISSUE_TEMPLATE .github/
cp .child-github/PULL_REQUEST_TEMPLATE.md .github/

# Remove LICENSE and CONTRIBUTING.md in child repo as author should add them manually if needed.
rm LICENSE
rm CONTRIBUTING.md

# Test if mdbook can build
if mdbook build --dry-run > /dev/null 2>&1; then
    echo "✅ mdbook build test passed"
else
    echo "⚠️  mdbook build encountered an issue"
    echo "   Try running: mdbook serve"
fi

echo ""
echo "========================================="
echo "✅ Setup complete! 🎉"
echo "========================================="
echo ""
echo "📚 Your book is ready to write!"
echo ""
echo "Next steps:"
echo "  1. Push current changes to GitHub: git add . && git commit -m 'init' && git push"
echo "  2. Update src/SUMMARY.md if you add/remove chapters"
echo "  3. Preview: mdbook serve"
echo "  4. Push to GitHub: git add . && git commit -m 'Initial content' && git push"
echo ""
echo "📖 Full documentation:"
echo "   https://suvabratachowdhury.github.io/mdbook-deployable-template/"
echo ""