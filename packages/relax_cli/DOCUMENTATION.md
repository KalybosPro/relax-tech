# Documentation Guide

This repository uses documentation to explain usage, architecture, and contribution workflows for `relax_cli`.

## What belongs in documentation

- Installation and setup instructions.
- CLI command reference and examples.
- Generated project structure and supported architectures.
- Development and testing workflows.
- Release notes, changelog, and version history.

## Repo documentation files

- `README.md` — primary user-facing documentation for installing and using `relax_cli`.
- `CHANGELOG.md` — release notes and bugfix history.
- `CONTRIBUTING.md` — guidelines for contributions and development workflow.
- `CODE_OF_CONDUCT.md` — community behavior expectations.
- `SECURITY.md` — how to report vulnerabilities responsibly.
- `example/README.md` — example project-specific guidance.
- `cahier_des_charges.md` — project requirements and product brief.

## Writing good docs

- Use clear, concise language.
- Keep sections short and scannable.
- Prefer code blocks for commands and examples.
- Use headings and bullet lists for structure.
- Update docs whenever behavior or user-visible output changes.

## Updating documentation

When adding or changing features, make sure to:

1. Update `README.md` with new command options, flags, or examples.
2. Add or revise changelog entries in `CHANGELOG.md` for each release.
3. Keep the example app documentation current in `example/README.md` if generated outputs change.
4. Document any breaking changes clearly.

## Documentation workflow

- Open a pull request for documentation changes.
- Link docs updates to the related feature or bug fix.
- Ask reviewers to validate both the code and the documentation.

## Style notes

- Prefer present-tense, active voice.
- Use consistent terminology: `relax create`, `relax generate`, `feature`, `module`, `model`.
- Keep command examples copy/paste ready.
- Use the same capitalization and naming patterns as the CLI itself.
