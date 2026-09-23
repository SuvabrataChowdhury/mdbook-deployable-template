# Updating the Template

Over time, this template receives improvements — new CI workflows, updated composite actions, and other configuration enhancements. This page explains how to pull those changes into your book repository.

## What gets updated

Only **template-owned files** are updated. Your content is never touched.

| Updated (template-owned) | Preserved (yours) |
|---|---|
| `.github/workflows/` | `src/` |
| `.github/actions/` | `book.toml` |
| `scripts/` | `README.md` |
| `Dockerfile.*` | `CONTRIBUTING.md` |
| | `LICENSE` |
| | `cspell.config.yml` |

## Prerequisites

- [Git](https://git-scm.com/install/)
- [Docker](https://www.docker.com/products/docker-desktop/)

## How to update

1. Check the [releases page](https://github.com/SuvabrataChowdhury/mdbook-deployable-template/releases) for the version you want.

2. Clone your repository and switch to a new branch:
    ```bash
    git clone https://github.com/YOUR-USERNAME/YOUR-REPO.git
    cd YOUR-REPO
    git checkout -b update-template
    ```

3. Run the update script:
    ```bash
    .update.sh --template-version "v1.2.0"
    ```
    Or run it without flags to be prompted interactively:
    ```bash
    ./update.sh
    ```

4. Review the changes, then commit and open a pull request:
    ```bash
    git diff
    git add .
    git commit -m "chore: update template to v1.2.0"
    git push --set-upstream origin update-template
    ```

> **Windows users**: run the script inside [WSL](https://learn.microsoft.com/en-us/windows/wsl/install) or use Git Bash.

## How it works

The update script builds a Docker image from `Dockerfile.update` at the requested version tag. Inside the container, `remove_customizable_files.sh` strips your user-owned files, leaving only the template-owned files. Those are then copied back into your local working tree via `docker cp` — your content files are never touched because they were never in the container.
