# Relax Tech

Monorepo for the **Relax** suite of Dart & Flutter packages — local-first ORM,
media picker, payments, storage, environment tooling and the Relax CLI.

Repository: **`KalybosPro/relax-tech`**

Each package is published **independently** on [pub.dev](https://pub.dev) and keeps
its own version and changelog. This repository is the single source of truth; the
former standalone repositories are archived and redirect here.

## 📦 Packages

| Package | pub.dev | Source | Previously at (archived) |
|---|---|---|---|
| **relax_cli** | [![pub](https://img.shields.io/pub/v/relax_cli.svg)](https://pub.dev/packages/relax_cli) | [`packages/relax_cli`](packages/relax_cli) | [KalybosPro/relax](https://github.com/KalybosPro/relax) |
| **relax_orm** | [![pub](https://img.shields.io/pub/v/relax_orm.svg)](https://pub.dev/packages/relax_orm) | [`packages/relax_orm`](packages/relax_orm) | [KalybosPro/relax_orm](https://github.com/KalybosPro/relax_orm) |
| **relax_orm_generator** | [![pub](https://img.shields.io/pub/v/relax_orm_generator.svg)](https://pub.dev/packages/relax_orm_generator) | [`packages/relax_orm_generator`](packages/relax_orm_generator) | [KalybosPro/relax_orm_generator](https://github.com/KalybosPro/relax_orm_generator) |
| **relax_image_picker** | [![pub](https://img.shields.io/pub/v/relax_image_picker.svg)](https://pub.dev/packages/relax_image_picker) | [`packages/relax_image_picker`](packages/relax_image_picker) | [KalybosPro/relax_image_picker](https://github.com/KalybosPro/relax_image_picker) |
| **relax_pay** | [![pub](https://img.shields.io/pub/v/relax_pay.svg)](https://pub.dev/packages/relax_pay) | [`packages/relax_pay`](packages/relax_pay) | _new — never had a standalone repo_ |
| **relax_storage** | [![pub](https://img.shields.io/pub/v/relax_storage.svg)](https://pub.dev/packages/relax_storage) | [`packages/relax_storage`](packages/relax_storage) | [KalybosPro/relax_storage](https://github.com/KalybosPro/relax_storage) |
| **env_builder_cli** | [![pub](https://img.shields.io/pub/v/env_builder_cli.svg)](https://pub.dev/packages/env_builder_cli) | [`packages/env_builder_cli`](packages/env_builder_cli) | [KalybosPro/env_builder_cli](https://github.com/KalybosPro/env_builder_cli) |

> **Note:** the package `relax_cli` was previously hosted at `KalybosPro/relax`
> (the bare `relax` repo), **not** `relax_cli`. That is why the new monorepo uses
> a distinct name, `relax-tech`.

## 🗂️ Repository layout

```
relax-tech/
├─ packages/
│  ├─ relax_cli/
│  ├─ relax_orm/
│  ├─ relax_orm_generator/
│  ├─ relax_image_picker/
│  ├─ relax_pay/
│  ├─ relax_storage/
│  └─ env_builder_cli/
└─ pubspec.yaml          # workspace root
```

## 🚀 Getting started

This repository uses [Dart pub workspaces](https://dart.dev/tools/pub/workspaces)
(SDK ≥ 3.11). All packages share a single resolution from the root.

```bash
# from the repository root
dart pub get        # resolves every package in the workspace at once
```

To work on a single package, `cd` into its folder under `packages/`.

## 🔗 Migrating from the old repositories

The following repositories have been **archived** and are read-only. Their code now
lives under `packages/` in this monorepo. The published pub.dev packages are
unaffected — **no action is required for consumers**; `dart pub add <package>`
keeps working exactly as before.

- `KalybosPro/relax` (relax_cli) → [`packages/relax_cli`](packages/relax_cli)
- `KalybosPro/relax_orm` → [`packages/relax_orm`](packages/relax_orm)
- `KalybosPro/relax_orm_generator` → [`packages/relax_orm_generator`](packages/relax_orm_generator)
- `KalybosPro/relax_image_picker` → [`packages/relax_image_picker`](packages/relax_image_picker)
- `KalybosPro/relax_storage` → [`packages/relax_storage`](packages/relax_storage)
- `KalybosPro/env_builder_cli` → [`packages/env_builder_cli`](packages/env_builder_cli)

## 🐛 Issues & contributions

Please open all issues and pull requests here, in the monorepo — even for a single
package. Mention the affected package name in the title (e.g. `[relax_orm] …`).

## 📄 License

See the `LICENSE` file in each package directory.
