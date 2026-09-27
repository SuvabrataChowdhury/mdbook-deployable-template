#!/usr/bin/env bash

setup-child-github() {
	rm -rf .github/ISSUE_TEMPLATE/*
	rm -f .github/PULL_REQUEST_TEMPLATE.md
	rm -f .github/dependabot.yml	# TODO: check if removing dependabot is a good idea for child repo
	rm -f .github/workflows/lint_pr.yml  # as child repo does not need these checks
	rm -f .github/workflows/release.yml  # child repos do not have releases

	cp -r .child-github/ISSUE_TEMPLATE .github/
	cp .child-github/PULL_REQUEST_TEMPLATE.md .github/
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup-child-github "$@"
fi
