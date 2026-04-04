# Introduction
This repository is a template for publishing a static book‑style website with almost no coding required. You write your book in Markdown, then push it to the repository. The rest—building the site and deploying it to the web—is handled automatically.

You don’t need to know HTML, CSS, JavaScript, or DevOps. If you can write a document and use Git a little, you can publish a book site.

## Purpose
This project’s purpose is to make it easy for anyone to publish a book‑style website, including:

- **Students** writing notes or tutorials.
- **Authors** publishing short books or technical guides.
- **Educators** sharing course material.
- **Anyone** who wants a clean, readable website without writing code.

The template is opinionated but simple: you focus on the content, and the template handles tooling, building, and deployment.

## What you need to know
You don’t need to be a developer to use this repository. The only things you need are:
1. **Markdown**: Think of it like a simple way to format text (headings, lists, links, etc.). All your book content lives in Markdown files (such as SUMMARY.md and chapter files).
    - **Helpful resources**:
        - [Basic writing and formatting on GitHub (Markdown guide).](https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax)
        - [Basic mdbook structure.](https://rust-lang.github.io/mdBook/format/index.html)
    > **Note**: most of the mdbook configuration is already done as part of the template. Authors just need to follow mdbook's format as described above.
2. **Git / GitHub**: A tool for version control and collaboration.
    - You only need to:
        - Create or clone a repository.
        - Make changes to Markdown files.
        - Commit and push those changes.
    - **Quick intro**: [About GitHub and Git.](https://docs.github.com/en/get-started/start-your-journey/about-github-and-git)
    
Once you push your Markdown content to the repository, the GitHub‑based workflow automatically:
- Builds your book with [mdbook](https://rust-lang.github.io/mdBook/format/index.html).
- Deploys the generated site to [GitHub Pages](https://docs.github.com/en/pages/getting-started-with-github-pages/what-is-github-pages) so it’s publicly accessible.