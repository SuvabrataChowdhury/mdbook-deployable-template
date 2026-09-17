# Absolute path to init.sh — resolved at parse time, before setup() changes $PWD
INIT_SCRIPT="$(cd "$BATS_TEST_DIRNAME" && pwd)/../../scripts/src/init.sh"

# ---------------------------------------------------------------------------
# Helper: build a minimal fake "template repo" that mirrors what init.sh
# expects to find in $PWD when it runs.
# ---------------------------------------------------------------------------
_setup_fake_repo() {
    local dir="$1"

    # src/theme — init.sh does: cp -r ./src/theme ./ then rm -rf ./src
    mkdir -p "$dir/src/theme"
    echo "<html></html>" > "$dir/src/theme/head.hbs"

    # book.toml placeholder (init.sh deletes it)
    cat > "$dir/book.toml" <<'EOF'
[book]
title = "Placeholder"
EOF

    # cspell.config.yml that yq will patch
    cat > "$dir/cspell.config.yml" <<'EOF'
version: "0.2"
words:
  - someword
EOF

    # .github — init.sh removes specific files and replaces templates
    mkdir -p "$dir/.github/ISSUE_TEMPLATE"
    mkdir -p "$dir/.github/workflows"
    echo "old pr template"   > "$dir/.github/PULL_REQUEST_TEMPLATE.md"
    touch "$dir/.github/dependabot.yml"
    touch "$dir/.github/workflows/lint_pr.yml"

    # .child-github — init.sh copies these into .github
    mkdir -p "$dir/.child-github/ISSUE_TEMPLATE"
    echo "child pr template" > "$dir/.child-github/PULL_REQUEST_TEMPLATE.md"
    echo "child issue cfg"   > "$dir/.child-github/ISSUE_TEMPLATE/config.yml"

    # Files init.sh removes
    echo "license text"      > "$dir/LICENSE"
    echo "contributing text" > "$dir/CONTRIBUTING.md"
}

# ---------------------------------------------------------------------------
# Helper: create a bin/ dir with stubs for git, mdbook, yq.
# mdbook init stub creates the minimal src/ structure init.sh depends on.
# ---------------------------------------------------------------------------
_make_stub_bin() {
    local bin_dir="$1"

    printf '#!/bin/sh\nexit 0\n' > "$bin_dir/git"

    # mdbook stub: simulate `mdbook init` creating src/SUMMARY.md + src/README.md
    cat > "$bin_dir/mdbook" <<'STUB'
#!/bin/sh
if [ "$1" = "init" ]; then
    mkdir -p src
    printf '# Summary\n\n- [Introduction](README.md)\n' > src/SUMMARY.md
    printf '# Introduction\n' > src/README.md
    exit 0
fi
exit 0
STUB

    # Delegate yq to the real binary path if available, else no-op stub.
    # Use the absolute path to avoid a fork-bomb when fake_bin is prepended to PATH.
    local real_yq
    real_yq="$(command -v yq 2>/dev/null || true)"
    if [[ -n "$real_yq" ]]; then
        printf '#!/bin/sh\n"%s" "$@"\n' "$real_yq" > "$bin_dir/yq"
    else
        printf '#!/bin/sh\nexit 0\n' > "$bin_dir/yq"
    fi

    chmod +x "$bin_dir/git" "$bin_dir/mdbook" "$bin_dir/yq"
}

# ---------------------------------------------------------------------------
# Setup / teardown — each test gets a fresh isolated temp repo
# ---------------------------------------------------------------------------

setup() {
    TEST_TEMP_DIR="$(mktemp -d)"
    _setup_fake_repo "$TEST_TEMP_DIR"
    cd "$TEST_TEMP_DIR"
}

teardown() {
    rm -rf "$TEST_TEMP_DIR"
}

# ---------------------------------------------------------------------------
# Argument parsing / help
# ---------------------------------------------------------------------------

@test "--help prints usage and exits 0" {
    run bash "$INIT_SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage:"* ]]
}

@test "unknown option exits 1 and prints usage" {
    run bash "$INIT_SCRIPT" --unknown-flag
    [ "$status" -eq 1 ]
    [[ "$output" == *"Unknown option"* ]]
}

# ---------------------------------------------------------------------------
# Dependency checks — use a fake PATH containing only selective stubs
# ---------------------------------------------------------------------------

@test "exits 1 when git is not installed" {
    local fake_bin
    fake_bin="$(mktemp -d)"
    # Keep system dirs so bash internals work; just omit git

    run env PATH="$fake_bin:/usr/bin:/bin" bash "$INIT_SCRIPT" -t T -a A -r http://x
    [ "$status" -ne 0 ]
    [[ "$output" == *"Git is not installed"* ]]

    rm -rf "$fake_bin"
}

@test "exits 1 when mdbook is not installed" {
    local fake_bin
    fake_bin="$(mktemp -d)"
    printf '#!/bin/sh\nexit 0\n' > "$fake_bin/git"
    chmod +x "$fake_bin/git"
    # no mdbook

    run env PATH="$fake_bin:/usr/bin:/bin" bash "$INIT_SCRIPT" -t T -a A -r http://x
    [ "$status" -ne 0 ]
    [[ "$output" == *"mdbook is not installed"* ]]

    rm -rf "$fake_bin"
}

@test "exits 1 when yq is not installed" {
    local fake_bin
    fake_bin="$(mktemp -d)"
    for cmd in git mdbook; do
        printf '#!/bin/sh\nexit 0\n' > "$fake_bin/$cmd"
        chmod +x "$fake_bin/$cmd"
    done
    # no yq

    run env PATH="$fake_bin:/usr/bin:/bin" bash "$INIT_SCRIPT" -t T -a A -r http://x
    [ "$status" -ne 0 ]
    [[ "$output" == *"yq is not installed"* ]]

    rm -rf "$fake_bin"
}

# ---------------------------------------------------------------------------
# Successful initialisation (all deps stubbed, runs inside fake repo)
# ---------------------------------------------------------------------------

@test "init succeeds with all flags provided" {
    local fake_bin
    fake_bin="$(mktemp -d)"
    _make_stub_bin "$fake_bin"

    run env PATH="$fake_bin:$PATH" bash "$INIT_SCRIPT" \
        --title "My Book" --author "Jane Doe" --repo "https://github.com/jane/my-book"

    [ "$status" -eq 0 ]
    [[ "$output" == *"Setup complete"* ]]

    rm -rf "$fake_bin"
}

@test "book.toml is created with correct title and author" {
    local fake_bin
    fake_bin="$(mktemp -d)"
    _make_stub_bin "$fake_bin"

    env PATH="$fake_bin:$PATH" bash "$INIT_SCRIPT" \
        -t "Test Book" -a "Test Author" -r "https://github.com/test/repo"

    [ -f "book.toml" ]
    grep -q 'title = "Test Book"' book.toml
    grep -q 'Test Author' book.toml
    grep -q 'git-repository-url = "https://github.com/test/repo"' book.toml

    rm -rf "$fake_bin"
}

@test "book.toml sets theme to src/theme" {
    local fake_bin
    fake_bin="$(mktemp -d)"
    _make_stub_bin "$fake_bin"

    env PATH="$fake_bin:$PATH" bash "$INIT_SCRIPT" -t T -a A -r http://x

    grep -q 'theme = "src/theme"' book.toml

    rm -rf "$fake_bin"
}

@test "theme directory is moved into src/" {
    local fake_bin
    fake_bin="$(mktemp -d)"
    _make_stub_bin "$fake_bin"

    env PATH="$fake_bin:$PATH" bash "$INIT_SCRIPT" -t T -a A -r http://x

    [ -d "src/theme" ]

    rm -rf "$fake_bin"
}

@test "README.md is created and contains book title" {
    local fake_bin
    fake_bin="$(mktemp -d)"
    _make_stub_bin "$fake_bin"

    env PATH="$fake_bin:$PATH" bash "$INIT_SCRIPT" \
        -t "My README Book" -a A -r http://x

    [ -f "README.md" ]
    grep -q "My README Book" README.md

    rm -rf "$fake_bin"
}

@test "LICENSE is removed after init" {
    local fake_bin
    fake_bin="$(mktemp -d)"
    _make_stub_bin "$fake_bin"

    env PATH="$fake_bin:$PATH" bash "$INIT_SCRIPT" -t T -a A -r http://x

    [ ! -f "LICENSE" ]

    rm -rf "$fake_bin"
}

@test "CONTRIBUTING.md is removed after init" {
    local fake_bin
    fake_bin="$(mktemp -d)"
    _make_stub_bin "$fake_bin"

    env PATH="$fake_bin:$PATH" bash "$INIT_SCRIPT" -t T -a A -r http://x

    [ ! -f "CONTRIBUTING.md" ]

    rm -rf "$fake_bin"
}

@test "child PULL_REQUEST_TEMPLATE replaces parent template" {
    local fake_bin
    fake_bin="$(mktemp -d)"
    _make_stub_bin "$fake_bin"

    env PATH="$fake_bin:$PATH" bash "$INIT_SCRIPT" -t T -a A -r http://x

    [ -f ".github/PULL_REQUEST_TEMPLATE.md" ]
    grep -q "child pr template" .github/PULL_REQUEST_TEMPLATE.md

    rm -rf "$fake_bin"
}

@test "child ISSUE_TEMPLATE is copied into .github" {
    local fake_bin
    fake_bin="$(mktemp -d)"
    _make_stub_bin "$fake_bin"

    env PATH="$fake_bin:$PATH" bash "$INIT_SCRIPT" -t T -a A -r http://x

    [ -f ".github/ISSUE_TEMPLATE/config.yml" ]

    rm -rf "$fake_bin"
}

@test "dependabot.yml is removed after init" {
    local fake_bin
    fake_bin="$(mktemp -d)"
    _make_stub_bin "$fake_bin"

    env PATH="$fake_bin:$PATH" bash "$INIT_SCRIPT" -t T -a A -r http://x

    [ ! -f ".github/dependabot.yml" ]

    rm -rf "$fake_bin"
}

@test "lint_pr.yml workflow is removed after init" {
    local fake_bin
    fake_bin="$(mktemp -d)"
    _make_stub_bin "$fake_bin"

    env PATH="$fake_bin:$PATH" bash "$INIT_SCRIPT" -t T -a A -r http://x

    [ ! -f ".github/workflows/lint_pr.yml" ]

    rm -rf "$fake_bin"
}
