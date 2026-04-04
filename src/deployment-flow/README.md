# Deployment Flow
A GitHub Actions job is configured to deploy the site after every push to the `main` branch.

## Suggested flow

1. Write your Markdown files and test the generated site locally.
    - Use `mdbook serve` to preview the site; it live‑reloads the page so changes appear immediately.
2. When you are satisfied with your changes, push them to the main branch.
    - The [GitHub Actions](https://docs.github.com/en/actions/get-started/quickstart) workflow will start automatically. After a few minutes, the site will be deployed to GitHub Pages and publicly available.

> **Note**: It is recommended to work on a separate branch for ongoing edits and keep main as stable as possible. See [About branches](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/about-branches) for more details.

## Manual deployment
Even though the workflow is designed to deploy automatically, there may be cases where you want to trigger a deployment manually.
- Go to the `Actions` tab in your repository.
- Select the workflow named `Deploy mdBook site to Pages` and click `Run workflow`.
- See [Manually running a workflow](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/manually-run-a-workflow#running-a-workflow) for more details.

> **Note**: For usage and billing information, see [GitHub Actions billing](https://docs.github.com/en/billing/concepts/product-billing/github-actions).
