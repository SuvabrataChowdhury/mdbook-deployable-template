# Setup
To start writing and deploying your book‑site, follow the steps below.

## Prerequisites
- [git](https://git-scm.com/install/) — required regardless of which initialization path you choose.
- [Docker](https://www.docker.com/products/docker-desktop/) — only needed for the local `init.sh` path.
- [mdbook](https://rust-lang.github.io/mdBook/guide/installation.html) — only needed if you want to preview your book locally before pushing.

> **Note:** Docker is being adopted progressively across this template's tooling. The goal is that Git and Docker are the only prerequisites — no other binaries or language runtimes needed. In future updates, local preview and other workflows will also run inside Docker.

## Step 1 — Create your repository
Create a new repository from [this template](https://github.com/SuvabrataChowdhury/mdbook-deployable-template).
- Click **"Use this template" → "Create a new repository"** at the top of the template repository page.
- **Helpful doc**: [Creating a repository from a template](https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-repository-from-a-template).

## Step 2 — Enable GitHub Pages
- In your new repo, go to **Settings → Pages**.
- Under *Build and deployment → Source*, select **GitHub Actions**.
- **Helpful doc**: [Publishing with a custom GitHub Actions workflow](https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site#publishing-with-a-custom-github-actions-workflow).

> Once Pages is enabled, the deploy workflow runs automatically on every push to `main`.

Optionally, edit the repository description so you always have quick access to the deployed page's URL:
- Go to **About → Settings → Tick `Use your GitHub Pages website` → Save Changes**

![URL-in-description](image.png)

## Step 3 — Allow Actions to create pull requests
The init workflow opens a pull request on your behalf. GitHub requires this permission to be enabled explicitly.
- Go to **Settings → Actions → General**.
- Scroll to *Workflow permissions*, tick **"Allow GitHub Actions to create and approve pull requests"**, and click **Save**.

## Step 4 — Initialize your book
Choose one of the two paths below. The GitHub Actions path is recommended — it requires no local tooling and works on all platforms including Windows.

### Via GitHub Actions (Recommended)
No tools needed on your machine.

1. Go to **Actions → Init Repository → Run workflow**.
2. Enter your book title and author name, then click **Run workflow**.
3. Wait ~1 minute for a pull request to appear, review it, and **merge it**.
4. Pull the latest changes locally:
    ```bash
    git pull
    ```

### Via init.sh
This path runs the same setup locally inside Docker. You need [Git](https://git-scm.com/install/) and [Docker](https://www.docker.com/products/docker-desktop/) installed.

> **Windows users**: use the [GitHub Actions path](#via-github-actions-recommended) instead, or run the script inside [WSL](https://learn.microsoft.com/en-us/windows/wsl/install).

1. Clone your repository:
    ```bash
    git clone https://github.com/YOUR-USERNAME/YOUR-REPO.git
    cd YOUR-REPO
    ```
2. Switch to a new branch:
    ```bash
    git checkout -b init
    ```
3. Run the init script:
    ```bash
    chmod +x init.sh
    ./init.sh
    ```
    The script will prompt for your book title, author name, and repository URL (or pass them as flags — run `./init.sh --help` for details).
4. Push the changes and open a pull request against `main`:
    ```bash
    git add .
    git commit -m "init"
    git push --set-upstream origin init
    ```

## Step 5 — Start writing
- Edit Markdown files in `src/`.
- Update `src/SUMMARY.md` to add or remove chapters.
- Preview locally with `mdbook serve` — the page live‑reloads as you edit.
- Push to `main` — your site deploys automatically and will be live at `https://<your-username>.github.io/<your-repo>/` within a couple of minutes.
