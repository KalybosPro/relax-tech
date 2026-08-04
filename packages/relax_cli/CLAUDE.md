# CLAUDE.md — relax_cli

Flagship CLI: scaffolds Clean-Architecture Flutter apps + the `relax quality`
platform. Entry point `bin/relax.dart`. Workspace member (`package:lints/recommended`).

## Commands
```bash
dart run bin/relax.dart --help     # run the CLI locally
dart analyze
dart test --concurrency=1          # see pitfalls
```

## Pitfalls
- Integration tests scaffold a real project and **shell out to `flutter`** — a
  Flutter SDK must be on `PATH` for the full suite to pass.
- Always use `--concurrency=1`: several tests mutate `Directory.current` and flake
  when run in parallel.
- This is the **only** package gated by CI (analyze + test).
- For user-facing changes bump `version` + `CHANGELOG.md`; prefix PR title
  `[relax_cli] …`.
