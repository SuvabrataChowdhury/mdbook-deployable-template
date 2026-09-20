# Integration tests for init.sh
#
# Unlike unit tests (init-unit-test.bats), these tests:
#   - Require a real Docker daemon
#   - Copy the full template repo into a temp dir
#   - Run init.sh against it with no stubs
#   - Verify the resulting repo structure
#
# Run with: scripts/test/bats/bin/bats scripts/test/init-integration-test.bats

REPO_ROOT="$(cd "$BATS_TEST_DIRNAME" && pwd)/../.."
INIT_SCRIPT="$REPO_ROOT/init.sh"

# ---------------------------------------------------------------------------
# Each test gets a full copy of the template repo in a temp dir
# ---------------------------------------------------------------------------

setup() {
    TEST_TEMP_DIR="$(mktemp -d)"

    # Copy the full template repo (excluding .git and build artefacts)
    rsync -a --exclude='.git' --exclude='book' --exclude='scripts/test/bats' \
        --exclude='scripts/test/test_helper' \
        "$REPO_ROOT/" "$TEST_TEMP_DIR/"

    cd "$TEST_TEMP_DIR"

    # Use the local working tree inside the Docker build so the current branch
    # is tested rather than the last published release on GitHub.
    export MDBOOK_USE_LOCAL=true
}

teardown() {
    rm -rf "$TEST_TEMP_DIR"
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

_run_init() {
    bash "$INIT_SCRIPT" --title "${1:-Test Book}" --author "${2:-Test Author}" --repo "${3:-https://github.com/test/repo}"
}

# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

@test "init.sh completes without error on a full template repo copy" {
    run _run_init "My Book" "Jane Doe" "https://github.com/jane/my-book"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Setup complete"* ]]
}

@test "book.toml is created with correct content after init" {
    _run_init "Valid Toml" "Jane Doe" "https://github.com/jane/valid-toml"

    [ -f "book.toml" ]
    grep -q 'title = "Valid Toml"' book.toml
    grep -q 'Jane Doe' book.toml
    grep -q 'git-repository-url = "https://github.com/jane/valid-toml"' book.toml
}

@test "cspell.config.yml is present after init" {
    _run_init "Spell Test" "Jane Doe" "https://github.com/jane/spell-test"
    [ -f "cspell.config.yml" ]
}

@test "src/theme is present after init" {
    _run_init "Theme Test" "Jane Doe" "https://github.com/jane/theme-test"
    [ -d "src/theme" ]
}

@test "setup.yml workflow is present in child repo after init" {
    _run_init "CI Test" "Jane Doe" "https://github.com/jane/ci-test"
    [ -f ".github/workflows/setup.yml" ]
}

@test "deploy.yml workflow is present in child repo after init" {
    _run_init "CI Test" "Jane Doe" "https://github.com/jane/ci-test"
    [ -f ".github/workflows/deploy.yml" ]
}

@test "checks.yml workflow is present in child repo after init" {
    _run_init "CI Test" "Jane Doe" "https://github.com/jane/ci-test"
    [ -f ".github/workflows/checks.yml" ]
}

@test "template-only workflows are removed after init" {
    _run_init "CI Test" "Jane Doe" "https://github.com/jane/ci-test"
    [ ! -f ".github/workflows/lint_pr.yml" ]
    [ ! -f ".github/workflows/release.yml" ]
}

@test "composite actions are present for child repo workflows" {
    _run_init "CI Test" "Jane Doe" "https://github.com/jane/ci-test"
    [ -f ".github/actions/install-mdbook/action.yml" ]
}

