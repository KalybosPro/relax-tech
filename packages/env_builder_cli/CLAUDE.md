# CLAUDE.md — env_builder_cli

CLI that generates a typed `env` Flutter package from multiple `.env` files.

## Critical: NOT a workspace member
Intentionally excluded from the root pub workspace — it needs `test ^1.31`, whose
`test_api` clashes with the `test_api 0.7.10` that `flutter_test` pins for the
Flutter members; `test >=1.31.2` also demands `analyzer >=13` while `relax_cli` and
`relax_orm_generator` cap it at `^10`. Run its own resolution **inside this dir**,
not from repo root:
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
