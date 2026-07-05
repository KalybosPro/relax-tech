# Contributing to Relax Tech

First off — **thank you** for taking the time to contribute! 🎉 Every issue,
idea, doc fix, and pull request makes the suite better, and first-time
contributors are genuinely welcome here.

This is a **monorepo**. All packages live under [`packages/`](packages/) and
share a single [Dart pub workspace](https://dart.dev/tools/pub/workspaces).
Please open all issues and PRs here, even for a single package.

## Table of contents

- [Ways to contribute](#ways-to-contribute)
- [Good first issues](#good-first-issues)
- [Project setup](#project-setup)
- [Making a change](#making-a-change)
- [Commit & PR conventions](#commit--pr-conventions)
- [Coding guidelines](#coding-guidelines)
- [Where things live](#where-things-live)

## Ways to contribute

You don't have to write code to help:

- ⭐ **Star the repo** — it genuinely helps others discover the project.
- 🐛 **Report a bug** using the issue form.
- 💡 **Propose a feature** or share a use case.
- 📖 **Improve the docs** — typos, examples, clarifications all count.
- 🧪 **Add tests** for an under-covered area.
- 🗳️ **Give feedback** on open issues and PRs.

## Good first issues

New here? Look for issues labeled
[`good first issue`](https://github.com/KalybosPro/relax-tech/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22)
or [`help wanted`](https://github.com/KalybosPro/relax-tech/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22).
Comment on the issue to let us know you're taking it — we're happy to guide you.

## Project setup

You need the **Dart/Flutter SDK ≥ 3.11**. From the repository root:

```bash
git clone https://github.com/KalybosPro/relax-tech.git
cd relax-tech
dart pub get          # resolves every workspace package at once
```

To work on one package, `cd` into it under `packages/`:

```bash
cd packages/relax_cli
dart analyze
dart test
dart run bin/relax.dart --help     # run the CLI locally
```

> Some `relax_cli` integration tests generate a project and shell out to
> `flutter`, so a Flutter SDK on your `PATH` is required to run the full suite.
> Run `dart test --concurrency=1` if you hit flakiness (a few tests use
> `Directory.current`).

## Making a change

1. **Fork** the repo and create a topic branch off `main`:
   `fix/relax_cli-create-output` or `feat/relax_orm-batch-insert`.
2. Keep changes **small and focused** — one logical change per PR.
3. **Add or update tests** for the behavior you change.
4. Run the checks below before opening your PR:

   ```bash
   dart format .        # format
   dart analyze         # static analysis — must be clean
   dart test            # in the package(s) you touched
   ```

5. Update the affected package's `CHANGELOG.md` and any docs.
6. Open a PR against `main` and fill in the template.

## Commit & PR conventions

- **Prefix the package** in issue/PR titles: `[relax_cli] fix create output`.
- Write clear, imperative commit messages (`add coverage aggregation`, not
  `added stuff`).
- CI (analyze + tests) must be green before a PR is merged.
- Bump the package version + changelog for user-facing changes (maintainers can
  help with this).

## Coding guidelines

- Follow Dart idioms and the conventions already in the file you're editing —
  match its naming, comments, and structure.
- Keep public APIs documented and CLI output clear and friendly.
- Prefer small, incremental changes over large rewrites.
- Don't introduce heavy dependencies without discussion.

## Where things live

| Package | What it is |
|---|---|
| [`relax_cli`](packages/relax_cli) | CLI: scaffold Flutter apps + the `relax quality` analysis platform |
| [`relax_orm`](packages/relax_orm) | Local-first ORM |
| [`relax_orm_generator`](packages/relax_orm_generator) | Codegen for `relax_orm` |
| [`relax_image_picker`](packages/relax_image_picker) | Media picker |
| [`relax_storage`](packages/relax_storage) | Key–value / file storage |
| [`relax_pay`](packages/relax_pay) | Payments |
| [`env_builder_cli`](packages/env_builder_cli) | Typed environment config generator |

Not sure where to start or how to approach something? **Open an issue and ask** —
early discussion is welcome and we're glad to help you land your first PR.

By contributing, you agree that your contributions will be licensed under the
[MIT License](LICENSE) and that you will follow our
[Code of Conduct](CODE_OF_CONDUCT.md).
