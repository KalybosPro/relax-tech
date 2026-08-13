# CLAUDE.md

## Stack
Dart **pub workspace** monorepo (SDK `^3.11`) of 7 packages under `packages/`, each
published **independently** to pub.dev with its own version + `CHANGELOG.md`. Mixed
pure-Dart CLIs and Flutter libs.

## Non-obvious conventions
- Root `pubspec.yaml` (`relax_workspace`, `publish_to: none`) only lists members;
  `dart pub get` at root resolves **all** members in one pass.
- **`env_builder_cli` is intentionally NOT a workspace member** (its `test ^1.31`
  clashes with the `test_api` that `flutter_test` pins for the Flutter members) —
  resolve it independently. See `packages/env_builder_cli/CLAUDE.md`.
- Lint sets differ per package — match the file you edit: `flutter_lints`
  (`relax_orm`), strict custom set + `prefer_single_quotes` (`env_builder_cli`,
  `relax_orm_generator`), `package:lints/recommended` (rest).
- `relax_orm_generator` is `build_runner` codegen (see its `build.yaml`); it
  generates `TableSchema` from annotated classes for `relax_orm`.
- User-facing changes: bump the package's `version` **and** `CHANGELOG.md`.
- Commit/PR titles prefix the package: `[relax_cli] fix create output`.

## Commands
```bash
dart pub get                              # root: resolve every member
cd packages/<pkg> && dart analyze && dart test
dart format .                             # before any PR
```

## Pitfalls
- CI only gates `relax_cli` (analyze + test). Other packages are **not** covered —
  analyze/test them manually before committing changes there.
- Per-package specifics live in nested `CLAUDE.md` files: `relax_cli` (Flutter on
  PATH, `--concurrency=1`) and `env_builder_cli` (excluded from workspace).
