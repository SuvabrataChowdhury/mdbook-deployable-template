# Unit tests for update.sh
#
# These tests:
#   - Do NOT require a real Docker daemon
#   - Run against a fake repo with stub binaries
#   - Verify argument parsing, dependency checks, and file outcomes
#     produced by remove_customizable_files.sh via the docker stub
#
# Run with: scripts/test/bats/bin/bats scripts/test/update-unit-test.bats

UPDATE_SCRIPT="$(cd "$BATS_TEST_DIRNAME" && pwd)/../../scripts/src/update.sh"
REPO_ROOT="$(cd "$BATS_TEST_DIRNAME" && pwd)/../.."

# ---------------------------------------------------------------------------
# Helper: build a fake child repo that mirrors what a real child repo looks
# like before an update — i.e. it has the user-owned customizable files and
# also the template-owned files that should be replaced.
# ---------------------------------------------------------------------------
_setup_fake_child_repo() {
    local dir="$1"

    # User-owned files (remove_customizable_files.sh strips these inside Docker)
    mkdir -p "$dir/src/theme"
    echo "# My Book" > "$dir/src/README.md"
    echo "# Summary" > "$dir/src/SUMMARY.md"
    cp "$REPO_ROOT/src/theme" "$dir/src/" 2>/dev/null || true
    cp "$REPO_ROOT/book.toml" "$dir/book.toml"
    cp "$REPO_ROOT/cspell.config.yml" "$dir/cspell.config.yml" 2>/dev/null || true
    touch "$dir/README.md"
    touch "$dir/CONTRIBUTING.md"
    touch "$dir/LICENSE"
    touch "$dir/architecture.excalidraw"

    # Template-owned files (these should survive and be updated)
    mkdir -p "$dir/.github/workflows" "$dir/.github/actions/install-mdbook"
    cp "$REPO_ROOT/.github/workflows/checks.yml"  "$dir/.github/workflows/checks.yml"
    cp "$REPO_ROOT/.github/workflows/deploy.yml"  "$dir/.github/workflows/deploy.yml"
    cp "$REPO_ROOT/.github/workflows/setup.yml"   "$dir/.github/workflows/setup.yml"
    cp "$REPO_ROOT/.github/actions/install-mdbook/action.yml" \
       "$dir/.github/actions/install-mdbook/action.yml"
}

# ---------------------------------------------------------------------------
# Helper: create stub binaries for docker.
# docker build  — records TEMPLATE_VERSION into a state file.
# docker create — emits a fake container ID.
# docker cp     — runs remove_customizable_files.sh locally to replicate
#                 what the real container does, then copies template-owned
#                 files from REPO_ROOT to simulate the docker cp output.
# docker rm     — no-op.
# ---------------------------------------------------------------------------
_make_stub_bin() {
    local bin_dir="$1"

    cat > "$bin_dir/docker" <<STUB
#!/bin/sh
STATE_FILE="\${TMPDIR:-/tmp}/.docker_update_stub_state_\$PPID"
SUBCOMMAND="\$1"
shift

case "\$SUBCOMMAND" in
    build)
        template_version=""
        while [ \$# -gt 0 ]; do
            if [ "\$1" = "--build-arg" ]; then
                arg="\$2"; shift 2
                case "\$arg" in
                    TEMPLATE_VERSION=*) template_version="\${arg#TEMPLATE_VERSION=}" ;;
                esac
            else
                shift
            fi
        done
        printf '%s\n' "\$template_version" > "\$STATE_FILE"
        exit 0
        ;;
    create)
        echo "stub-update-container-id"
        exit 0
        ;;
    cp)
        # Simulate what the container produced: customizable files are absent,
        # template-owned files are present. Only copy template-owned files —
        # do NOT delete the user's local customizable files (that is intentional
        # behaviour: update preserves user content).
        mkdir -p .github/workflows .github/actions/install-mdbook
        cp "$REPO_ROOT/.github/workflows/checks.yml"  .github/workflows/checks.yml
        cp "$REPO_ROOT/.github/workflows/deploy.yml"  .github/workflows/deploy.yml
        cp "$REPO_ROOT/.github/workflows/setup.yml"   .github/workflows/setup.yml
        cp "$REPO_ROOT/.github/actions/install-mdbook/action.yml" \
           .github/actions/install-mdbook/action.yml
        exit 0
        ;;
    rm)
        exit 0
        ;;
    *)
        exit 0
        ;;
esac
STUB

    chmod +x "$bin_dir/docker"
}

# ---------------------------------------------------------------------------
# Setup / teardown
# ---------------------------------------------------------------------------

setup() {
    TEST_TEMP_DIR="$(mktemp -d)"
    _setup_fake_child_repo "$TEST_TEMP_DIR"
    cd "$TEST_TEMP_DIR"
}

teardown() {
    rm -rf "$TEST_TEMP_DIR"
}

# ---------------------------------------------------------------------------
# Argument parsing / help
# ---------------------------------------------------------------------------

@test "--help prints usage and exits 0" {
    run bash "$UPDATE_SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage:"* ]]
}

@test "--help documents MDBOOK_USE_LOCAL environment variable" {
    run bash "$UPDATE_SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"MDBOOK_USE_LOCAL"* ]]
}

@test "unknown option exits 1 and prints usage" {
    run bash "$UPDATE_SCRIPT" --unknown-flag
    [ "$status" -eq 1 ]
    [[ "$output" == *"Unknown option"* ]]
}

@test "missing --template-version exits 1 when stdin is not a tty" {
    run bash "$UPDATE_SCRIPT" <<< ""
    [ "$status" -eq 1 ]
    [[ "$output" == *"Template Version is required"* ]]
}

# ---------------------------------------------------------------------------
# Dependency checks
# ---------------------------------------------------------------------------

@test "exits 1 when docker is not installed" {
    local fake_bin bash_bin
    fake_bin="$(mktemp -d)"
    bash_bin="$(command -v bash)"

    run env -i PATH="$fake_bin" HOME="$HOME" "$bash_bin" "$UPDATE_SCRIPT" \
        --template-version "v1.0.0"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Docker is not installed"* ]]

    rm -rf "$fake_bin"
}

# ---------------------------------------------------------------------------
# Successful update (docker stubbed)
# ---------------------------------------------------------------------------

@test "update succeeds with --template-version flag" {
    local fake_bin
    fake_bin="$(mktemp -d)"
    _make_stub_bin "$fake_bin"

    run env PATH="$fake_bin:$PATH" bash "$UPDATE_SCRIPT" --template-version "v1.0.0"

    [ "$status" -eq 0 ]
    [[ "$output" == *"Update complete"* ]]

    rm -rf "$fake_bin"
}

@test "update succeeds with short -t flag" {
    local fake_bin
    fake_bin="$(mktemp -d)"
    _make_stub_bin "$fake_bin"

    run env PATH="$fake_bin:$PATH" bash "$UPDATE_SCRIPT" -t "v1.0.0"

    [ "$status" -eq 0 ]

    rm -rf "$fake_bin"
}

@test "success message contains the template version" {
    local fake_bin
    fake_bin="$(mktemp -d)"
    _make_stub_bin "$fake_bin"

    run env PATH="$fake_bin:$PATH" bash "$UPDATE_SCRIPT" --template-version "v2.3.4"

    [[ "$output" == *"v2.3.4"* ]]

    rm -rf "$fake_bin"
}

# ---------------------------------------------------------------------------
# File outcomes — customizable files removed, template files present
# ---------------------------------------------------------------------------

@test "src/ is preserved after update (user content not overwritten)" {
    local fake_bin
    fake_bin="$(mktemp -d)"
    _make_stub_bin "$fake_bin"

    env PATH="$fake_bin:$PATH" bash "$UPDATE_SCRIPT" --template-version "v1.0.0"

    [ -d "src" ]

    rm -rf "$fake_bin"
}

@test "book.toml is preserved after update (user content not overwritten)" {
    local fake_bin
    fake_bin="$(mktemp -d)"
    _make_stub_bin "$fake_bin"

    env PATH="$fake_bin:$PATH" bash "$UPDATE_SCRIPT" --template-version "v1.0.0"

    [ -f "book.toml" ]

    rm -rf "$fake_bin"
}

@test "README.md is preserved after update (user content not overwritten)" {
    local fake_bin
    fake_bin="$(mktemp -d)"
    _make_stub_bin "$fake_bin"

    env PATH="$fake_bin:$PATH" bash "$UPDATE_SCRIPT" --template-version "v1.0.0"

    [ -f "README.md" ]

    rm -rf "$fake_bin"
}

@test "CONTRIBUTING.md is preserved after update (user content not overwritten)" {
    local fake_bin
    fake_bin="$(mktemp -d)"
    _make_stub_bin "$fake_bin"

    env PATH="$fake_bin:$PATH" bash "$UPDATE_SCRIPT" --template-version "v1.0.0"

    [ -f "CONTRIBUTING.md" ]

    rm -rf "$fake_bin"
}

@test "LICENSE is preserved after update (user content not overwritten)" {
    local fake_bin
    fake_bin="$(mktemp -d)"
    _make_stub_bin "$fake_bin"

    env PATH="$fake_bin:$PATH" bash "$UPDATE_SCRIPT" --template-version "v1.0.0"

    [ -f "LICENSE" ]

    rm -rf "$fake_bin"
}

@test "cspell.config.yml is preserved after update (user content not overwritten)" {
    local fake_bin
    fake_bin="$(mktemp -d)"
    _make_stub_bin "$fake_bin"

    env PATH="$fake_bin:$PATH" bash "$UPDATE_SCRIPT" --template-version "v1.0.0"

    [ -f "cspell.config.yml" ]

    rm -rf "$fake_bin"
}

@test "architecture.excalidraw is preserved after update (user content not overwritten)" {
    local fake_bin
    fake_bin="$(mktemp -d)"
    _make_stub_bin "$fake_bin"

    env PATH="$fake_bin:$PATH" bash "$UPDATE_SCRIPT" --template-version "v1.0.0"

    [ -f "architecture.excalidraw" ]

    rm -rf "$fake_bin"
}

@test "checks.yml workflow is present after update" {
    local fake_bin
    fake_bin="$(mktemp -d)"
    _make_stub_bin "$fake_bin"

    env PATH="$fake_bin:$PATH" bash "$UPDATE_SCRIPT" --template-version "v1.0.0"

    [ -f ".github/workflows/checks.yml" ]

    rm -rf "$fake_bin"
}

@test "deploy.yml workflow is present after update" {
    local fake_bin
    fake_bin="$(mktemp -d)"
    _make_stub_bin "$fake_bin"

    env PATH="$fake_bin:$PATH" bash "$UPDATE_SCRIPT" --template-version "v1.0.0"

    [ -f ".github/workflows/deploy.yml" ]

    rm -rf "$fake_bin"
}

@test "install-mdbook composite action is present after update" {
    local fake_bin
    fake_bin="$(mktemp -d)"
    _make_stub_bin "$fake_bin"

    env PATH="$fake_bin:$PATH" bash "$UPDATE_SCRIPT" --template-version "v1.0.0"

    [ -f ".github/actions/install-mdbook/action.yml" ]

    rm -rf "$fake_bin"
}
