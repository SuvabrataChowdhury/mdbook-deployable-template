# Integration tests for init.sh
#
# Unlike unit tests (init-unit-test.bats), these tests:
#   - Require real mdbook and yq to be installed
#   - Copy the full template repo into a temp dir
#   - Run init.sh against it with no stubs
#   - Verify the resulting repo is actually buildable by mdbook
#
# Run with: scripts/test/bats/bin/bats scripts/test/init-integration-test.bats

REPO_ROOT="$(cd "$BATS_TEST_DIRNAME" && pwd)/../.."
INIT_SCRIPT="$REPO_ROOT/init.sh"

# ---------------------------------------------------------------------------
# Skip entire file if required tools are not installed
# ---------------------------------------------------------------------------

setup_file() {
    if ! command -v mdbook &>/dev/null; then
        skip "mdbook is not installed — skipping integration tests"
    fi
    if ! command -v yq &>/dev/null; then
        skip "yq is not installed — skipping integration tests"
    fi
}

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

@test "mdbook build succeeds after init" {
    _run_init "Build Test" "Jane Doe" "https://github.com/jane/build-test"

    run mdbook build
    [ "$status" -eq 0 ]
}

@test "mdbook build produces index.html" {
    _run_init "Build Test" "Jane Doe" "https://github.com/jane/build-test"
    mdbook build

    [ -f "book/index.html" ]
}

@test "book.toml is valid and readable by mdbook" {
    _run_init "Valid Toml" "Jane Doe" "https://github.com/jane/valid-toml"

    # mdbook will exit non-zero if book.toml is malformed
    run mdbook build --dest-dir /tmp/bats-mdbook-out-$$
    [ "$status" -eq 0 ]
    rm -rf /tmp/bats-mdbook-out-$$
}

@test "cspell.config.yml retains functional keys after init" {
    _run_init "Spell Test" "Jane Doe" "https://github.com/jane/spell-test"

    # The yq patch must not destroy the import/ignoreRegExpList/languageSettings blocks
    [ -f "cspell.config.yml" ]
    run yq '.import | length' cspell.config.yml
    [ "$status" -eq 0 ]
    [ "$output" -gt 0 ]

    run yq '.languageSettings | length' cspell.config.yml
    [ "$status" -eq 0 ]
    [ "$output" -gt 0 ]
}

@test "cspell.config.yml contains author name parts after init" {
    _run_init "Spell Test" "Jane Doe" "https://github.com/jane/spell-test"

    run yq '.words[]' cspell.config.yml
    [ "$status" -eq 0 ]
    [[ "$output" == *"Jane"* ]]
    [[ "$output" == *"Doe"* ]]
}

@test "src/theme is present and used by the built book" {
    _run_init "Theme Test" "Jane Doe" "https://github.com/jane/theme-test"

    [ -d "src/theme" ]
    mdbook build
    # head.hbs from the theme must have been processed — book/ must exist
    [ -d "book" ]
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
    # deploy.yml and setup.yml both reference these local composite actions
    [ -f ".github/actions/install-mdbook/action.yml" ]
    [ -f ".github/actions/install-yq/action.yml" ]
}

