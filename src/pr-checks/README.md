# PR Checks

Every pull request targeting `main` is automatically validated by the **PR Checks** workflow. The checks only run against files added or modified in the PR, so they are fast regardless of how large the book grows.

## Spell check

Markdown files are checked for spelling errors using [cspell](https://cspell.org/).

- Misspelled words are surfaced as inline warning annotations directly on the PR diff.
- The check fails the PR if any unrecognized words are found.
- Only Markdown files (`**/*.md`) are checked.

### Adding words to the allowlist

If a word is flagged but is intentional (a technical term, a proper noun, etc.), add it to the `words` list in `cspell.config.yml` at the root of the repository:

```yaml
words:
  - mermaid
  - mdbook
  - your-term
```

<!-- markdown-link-check-disable-next-line -->
> **Note**: Author name parts are added to this list automatically during [initialization](../setup/index.html#initialize-your-book), so your name will never trigger a false positive.

## Link check

All Markdown links in modified files are validated using [github-action-markdown-link-check](https://github.com/tcort/github-action-markdown-link-check).

- Only links in files changed by the PR are checked.
- Both internal relative links and external URLs are verified.
- A broken link will fail the PR.

> **Note**: Unlike spell check, broken link failures are not shown as inline annotations on the PR diff. If the link check fails, open the **Actions** tab, select the failed workflow run, and inspect the job logs to see which links are broken.
