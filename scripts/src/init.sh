#!/usr/bin/env bash

# mdbook-deployable-template initialization script
# Run this once after cloning a repo created from the template

set -euo pipefail  # Exit on any error

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
    echo ""
    echo "   Visit: https://git-scm.com/install"
    exit 1
fi

if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install docker first."
    echo ""
    echo "   Visit: https://www.docker.com/products/docker-desktop/"
    exit 1
fi

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

DOCKER_TARGET="release"
[[ "${MDBOOK_USE_LOCAL:-}" == "true" ]] && DOCKER_TARGET="local"

docker build -t mdbook-build -f Dockerfile.setup \
    --target "$DOCKER_TARGET" \
    --build-arg BOOK_TITLE="$BOOK_TITLE" \
    --build-arg AUTHOR_NAME="$AUTHOR_NAME" \
    --build-arg REPO_URL="$REPO_URL" .

# After copying files from container the resultant files are nothing but union of the local machine and the container's files.
# Removing files that are not supposed to be in the child repo
rm -rf .github src LICENSE CONTRIBUTING.md

CONTAINER_ID=$(docker create mdbook-build)
docker cp "$CONTAINER_ID":/template/mdbook-deployable-template/. .
docker rm "$CONTAINER_ID"

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
