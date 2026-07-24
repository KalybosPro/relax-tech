# CLAUDE.md — env_builder_cli

CLI that generates a typed `env` Flutter package from multiple `.env` files.

## Critical: NOT a workspace member
Intentionally excluded from the root pub workspace — it pins `analyzer ^12` while
`relax_orm_generator` pins `analyzer ^10`, which cannot share one resolution.
Run its own resolution **inside this dir**, not from repo root:
```bash
cd packages/env_builder_cli
dart pub get       # independent of the root workspace
dart analyze
dart test
```

## Conventions
- Strict custom lint set (see `analysis_options.yaml`) incl. `prefer_single_quotes`
  and `avoid_print` — match it.
- Not covered by CI; analyze + test manually before committing.
- Bump `version` + `CHANGELOG.md` for user-facing changes.
