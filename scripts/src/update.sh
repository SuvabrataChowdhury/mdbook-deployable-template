#!/usr/bin/env bash

set -euo pipefail  # Exit on any error

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Update your mdbook project with the latest releases of the deployable template."
    echo ""
    echo "Options:"
    echo "  -t, --template-version <version>  Template Version"
    echo "  -h, --help						  Show this help message"
    echo ""
    echo "If options are omitted, the script will prompt interactively."
    echo "Please refer the github releases for getting the valid version. https://github.com/SuvabrataChowdhury/mdbook-deployable-template/releases"
    echo ""
    echo "Environment Variables:"
    echo "  MDBOOK_USE_LOCAL=true  Use the local working tree instead of pulling from GitHub."
    echo "                         Useful for testing local changes before publishing a release."
    echo "                         Note: --template-version is still required but ignored by Docker."
    echo ""
    echo "Example:"
    echo "  $0 --template-version \"v1.0.0\""
    echo ""
    echo "  # Test with local changes:"
    echo "  MDBOOK_USE_LOCAL=true $0 --template-version \"v1.0.0\""
}

TEMPLATE_VERSION=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -t|--template-version)  TEMPLATE_VERSION="$2";    shift 2 ;;
        -h|--help)   usage; exit 0 ;;
        *) echo "Unknown option: $1"; usage; exit 1 ;;
    esac
done

if [[ -z "$TEMPLATE_VERSION" ]]; then
    read -p "⚙️ Template Version: " TEMPLATE_VERSION
    [[ -z "$TEMPLATE_VERSION" ]] && { echo "❌ Template Version is required."; exit 1; }
fi

if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install docker first."
    echo ""
    echo "   Visit: https://www.docker.com/products/docker-desktop/"
    exit 1
fi

DOCKER_TARGET="release"
[[ "${MDBOOK_USE_LOCAL:-}" == "true" ]] && DOCKER_TARGET="local"
docker build -t mdbook-update-build -f Dockerfile.update \
    --target "$DOCKER_TARGET" \
    --build-arg TEMPLATE_VERSION="$TEMPLATE_VERSION" .

CONTAINER_ID=$(docker create mdbook-update-build)
docker cp "$CONTAINER_ID":/template/mdbook-deployable-template/. .
docker rm "$CONTAINER_ID"

echo ""
echo "========================================="
echo "✅ Update complete! 🎉"
echo "========================================="
echo ""
echo "📦 Template updated to $TEMPLATE_VERSION"
echo ""
echo "Next steps:"
echo "  1. Review the changes: git diff"
echo "  2. Commit the update: git add . && git commit -m 'chore: update template to $TEMPLATE_VERSION'"
echo "  3. Push to GitHub: git push"
echo ""

