# Setup
To start writing and deploying your book‑site, follow the steps below.

## Prerequisites
Install the following tools on your machine — you will need them for local preview regardless of which initialization path you choose.

- [mdbook](https://rust-lang.github.io/mdBook/guide/installation.html) — on most systems this is a single command via cargo or a package manager.
- [git](https://git-scm.com/install/)

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
1. Go to **Actions → Init Repository → Run workflow**.
2. Enter your book title and author name, then click **Run workflow**.
3. Wait ~1 minute for a pull request to appear, review it, and **merge it**.
4. Pull the latest changes locally:
    ```bash
    git pull
    ```

### Via init.sh
> **Windows users**: use the [GitHub Actions path](#via-github-actions-recommended) instead, or run the script inside [WSL](https://learn.microsoft.com/en-us/windows/wsl/install).

1. Install [yq](https://mikefarah.gitbook.io/yq#install) — required by the init script, one-time only.
2. Clone your repository:
    ```bash
    git clone https://github.com/YOUR-USERNAME/YOUR-REPO.git
    cd YOUR-REPO
    ```
3. Switch to a new branch:
    ```bash
    git checkout -b init
    ```
4. Run the init script:
    ```bash
    chmod +x init.sh
    ./init.sh
    ```
5. Push the changes and open a pull request against `main`:
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
