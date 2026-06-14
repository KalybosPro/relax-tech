# Monorepo migration plan — `KalybosPro/relax-tech`

Status checklist for moving the 7 Relax packages from individual repositories
into a single monorepo (`KalybosPro/relax-tech`) using Dart pub workspaces, while
**preserving git history** (strategy B — `git subtree`).

Legend: ✅ done in this working copy · ⬜ still to do (manual / requires GitHub)

## ⚠️ Important naming note

The package `relax_cli` is hosted at **`KalybosPro/relax`** (the bare `relax`
repo), not at `relax_cli`. Because that name was taken, the new monorepo uses a
**distinct name: `relax-tech`**. Use the correct remote URLs below.

## Already prepared in this working copy

- ✅ Root workspace `pubspec.yaml` (declares the 7 members).
- ✅ Root `README.md` (package table + redirect mapping, pointing to relax-tech).
- ✅ `.gitignore` for the monorepo root.
- ✅ `repository:` / `homepage:` / `issue_tracker:` / `documentation:` fields in
  all 7 package pubspecs repointed to `KalybosPro/relax-tech` (issues centralized).
- ✅ "This repository has moved" banner added on top of the 6 existing package
  READMEs, pointing to `relax-tech`.
- ✅ Stale issue links in `relax/SECURITY.md` and `relax/CODE_OF_CONDUCT.md`
  recentralized to `relax-tech/issues`.

## Packages

| Package | Old repo (remote) | Default branch | Target folder |
|---|---|---|---|
| relax_cli | `KalybosPro/relax` | main | `packages/relax_cli/` |
| relax_orm | `KalybosPro/relax_orm` | main | `packages/relax_orm/` |
| relax_orm_generator | `KalybosPro/relax_orm_generator` | main | `packages/relax_orm_generator/` |
| relax_image_picker | `KalybosPro/relax_image_picker` | main | `packages/relax_image_picker/` |
| relax_pay | _none — never created_ | — | `packages/relax_pay/` |
| relax_storage | `KalybosPro/relax_storage` | main | `packages/relax_storage/` |
| env_builder_cli | `KalybosPro/env_builder_cli` | main | `packages/env_builder_cli/` |

> All existing repos use branch `main`.

## ⬜ Step 1 — Create the new repo and import histories (strategy B)

Create an empty `KalybosPro/relax-tech` repo on GitHub, clone it, then import each
old repo under `packages/<name>` with full history via `git subtree`:

```bash
git clone https://github.com/KalybosPro/relax-tech.git
cd relax-tech

# relax_cli lives in the "relax" repo (note the URL!)
git subtree add --prefix=packages/relax_cli           https://github.com/KalybosPro/relax.git                  main
git subtree add --prefix=packages/relax_orm           https://github.com/KalybosPro/relax_orm.git              main
git subtree add --prefix=packages/relax_orm_generator https://github.com/KalybosPro/relax_orm_generator.git    main
git subtree add --prefix=packages/relax_image_picker  https://github.com/KalybosPro/relax_image_picker.git     main
git subtree add --prefix=packages/relax_storage       https://github.com/KalybosPro/relax_storage.git          main
git subtree add --prefix=packages/env_builder_cli     https://github.com/KalybosPro/env_builder_cli.git        main
```

`relax_pay` has no remote repo — copy its folder in manually:

```bash
cp -r "<this working copy>/relax_pay" packages/relax_pay   # then: git add + commit
```

> The uncommitted local edits in this working copy (banners, pubspec link fixes)
> are NOT pushed yet. Decide per file where they belong:
> - **Banners** → push to each OLD repo before archiving (Step 5). They must NOT
>   end up inside the monorepo package READMEs.
> - **pubspec link fixes + root files** → belong in the monorepo. Re-apply them in
>   `relax-tech` after the subtree import (or copy from here).

## ⬜ Step 2 — Add the root workspace files

Copy these from this working copy into the `relax-tech` root:
`pubspec.yaml`, `README.md`, `.gitignore`, `MIGRATION.md`.

## ⬜ Step 3 — Activate the workspace

In each member `pubspec.yaml` under `packages/`, add at the top level:

```yaml
resolution: workspace
```

Then from the repo root:

```bash
dart pub get   # resolves all 7 packages together; writes one pubspec.lock
```

Fix any `example/` pubspecs that mix `path:` and pub.dev constraints so they
resolve from the workspace.

## ⬜ Step 4 — CI

Consolidate the existing `env_builder_cli/.github/workflows/*` into a single root
`.github/workflows/` that runs analyze + test across the workspace.

## ⬜ Step 5 — Publishing (per package)

- Keep versions independent — never bump a package that did not change.
- Verify each package publishes cleanly: `dart pub publish --dry-run` from its
  `packages/<name>` folder (no leftover `path:` deps on publishable packages).
- If using pub.dev automated publishing (OIDC): on pub.dev, under each package's
  Admin > Automated publishing, authorize the **new** repo `KalybosPro/relax-tech`
  and set a **per-package tag pattern** (e.g. `relax_orm-v{{version}}`) so a tag
  only publishes the matching package.

## ⬜ Step 6 — Archive old repos (do NOT delete)

After the monorepo is pushed and verified:

- Push the updated READMEs (with the "moved" banner) to each old repo,
  including `KalybosPro/relax` (the relax_cli repo).
- GitHub > each repo > Settings > **Archive this repository**.
- Keeping them archived preserves the `repository:` links of already-published
  pub.dev versions (those still point to the old repos and must not 404).
