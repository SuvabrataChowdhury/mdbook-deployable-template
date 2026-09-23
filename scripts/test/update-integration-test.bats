# Integration tests for update.sh
#
# Unlike unit tests (update-unit-test.bats), these tests:
#   - Require a real Docker daemon
#   - Copy the full template repo into a temp dir to simulate a child repo
#   - Run update.sh against it with no stubs (MDBOOK_USE_LOCAL=true)
#   - Verify the resulting repo structure
#
# Run with: scripts/test/bats/bin/bats scripts/test/update-integration-test.bats

REPO_ROOT="$(cd "$BATS_TEST_DIRNAME" && pwd)/../.."
UPDATE_SCRIPT="$REPO_ROOT/scripts/src/update.sh"

# ---------------------------------------------------------------------------
# Each test gets a full copy of the template repo in a temp dir,
# simulating a child repo that is about to receive a template update.
# ---------------------------------------------------------------------------

setup() {
    TEST_TEMP_DIR="$(mktemp -d)"

    rsync -a --exclude='.git' --exclude='book' --exclude='scripts/test/bats' \
        --exclude='scripts/test/test_helper' \
        "$REPO_ROOT/" "$TEST_TEMP_DIR/"

    cd "$TEST_TEMP_DIR"

    export MDBOOK_USE_LOCAL=true
}

teardown() {
    rm -rf "$TEST_TEMP_DIR"
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

_run_update() {
    bash "$UPDATE_SCRIPT" --template-version "${1:-v1.0.0}"
}

# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

@test "update.sh completes without error on a full template repo copy" {
    run _run_update "v1.0.0"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Update complete"* ]]
}

@test "success message contains the requested template version" {
    run _run_update "v1.2.3"
    [ "$status" -eq 0 ]
    [[ "$output" == *"v1.2.3"* ]]
}

@test "src/ is preserved after update (user content not overwritten)" {
    _run_update "v1.0.0"
    [ -d "src" ]
}

@test "book.toml is preserved after update (user content not overwritten)" {
    _run_update "v1.0.0"
    [ -f "book.toml" ]
}

@test "README.md is preserved after update (user content not overwritten)" {
    _run_update "v1.0.0"
    [ -f "README.md" ]
}

@test "CONTRIBUTING.md is preserved after update (user content not overwritten)" {
    _run_update "v1.0.0"
    [ -f "CONTRIBUTING.md" ]
}

@test "LICENSE is preserved after update (user content not overwritten)" {
    _run_update "v1.0.0"
    [ -f "LICENSE" ]
}

@test "cspell.config.yml is preserved after update (user content not overwritten)" {
    _run_update "v1.0.0"
    [ -f "cspell.config.yml" ]
}

@test "architecture.excalidraw is preserved after update (user content not overwritten)" {
    _run_update "v1.0.0"
    [ -f "architecture.excalidraw" ]
}

@test "checks.yml workflow is present after update" {
    _run_update "v1.0.0"
    [ -f ".github/workflows/checks.yml" ]
}

@test "deploy.yml workflow is present after update" {
    _run_update "v1.0.0"
    [ -f ".github/workflows/deploy.yml" ]
}

@test "setup.yml workflow is present after update" {
    _run_update "v1.0.0"
    [ -f ".github/workflows/setup.yml" ]
}

@test "install-mdbook composite action is present after update" {
    _run_update "v1.0.0"
    [ -f ".github/actions/install-mdbook/action.yml" ]
}
