<div align="center">

# 🧘 Relax Tech

### The developer suite that makes Dart & Flutter apps effortless to build — *and keep* — clean.

Scaffold production-ready apps, keep them healthy with a built-in quality platform, persist data with a local-first ORM, and ship faster — all from a set of small, focused, independently published packages.

[![CI](https://github.com/KalybosPro/relax-tech/actions/workflows/ci.yml/badge.svg)](https://github.com/KalybosPro/relax-tech/actions/workflows/ci.yml)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![PRs welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)
[![style: lints](https://img.shields.io/badge/style-lints-40c4ff.svg)](https://pub.dev/packages/lints)

**[Get started](#-quickstart)** · **[Packages](#-packages)** · **[Why relax_cli](#-spotlight-relax_cli)** · **[Roadmap](#roadmap)** · **[Contribute](#-contributing)**

</div>

---

**Relax** is a monorepo of Dart & Flutter packages built around one idea: great tooling should get out of your way. Each package solves one problem well and is published **independently** on [pub.dev](https://pub.dev) with its own version and changelog — use one, or use them together.

> ⭐ **If any of this saves you time, a star genuinely helps others find the project — and helps us keep building.**

## ✨ Highlights

- 🏗️ **Scaffold real apps, not boilerplate** — `relax create` generates Clean Architecture Flutter projects for Bloc, Provider, Riverpod, or GetX, ready to run.
- 🔍 **A quality platform in your terminal** — `relax quality` analyzes architecture, generates tests and use cases, measures coverage, and tracks a health score over time. *(Nothing else in the Flutter ecosystem does this.)*
- 🗄️ **Local-first data** — `relax_orm` gives you a typed, reactive ORM with code-gen schemas.
- 🧩 **Focused building blocks** — media picking, storage, payments, and typed environment config, each as its own package.
- 🪶 **Zero-friction** — pure Dart, no native databases, no runtime services. Cross-platform (Windows / macOS / Linux).

## 📦 Packages

| Package | pub.dev | What it does |
|---|---|---|
| **[relax_cli](packages/relax_cli)** | [![pub](https://img.shields.io/pub/v/relax_cli.svg?label=%20)](https://pub.dev/packages/relax_cli) | Scaffold Flutter apps + the `relax quality` analysis platform |
| **[relax_orm](packages/relax_orm)** | [![pub](https://img.shields.io/pub/v/relax_orm.svg?label=%20)](https://pub.dev/packages/relax_orm) | Local-first, reactive ORM |
| **[relax_orm_generator](packages/relax_orm_generator)** | [![pub](https://img.shields.io/pub/v/relax_orm_generator.svg?label=%20)](https://pub.dev/packages/relax_orm_generator) | Code generation for `relax_orm` |
| **[relax_image_picker](packages/relax_image_picker)** | [![pub](https://img.shields.io/pub/v/relax_image_picker.svg?label=%20)](https://pub.dev/packages/relax_image_picker) | Media picker with modern platform support |
| **[relax_storage](packages/relax_storage)** | [![pub](https://img.shields.io/pub/v/relax_storage.svg?label=%20)](https://pub.dev/packages/relax_storage) | Key–value & file storage |
| **[relax_pay](packages/relax_pay)** | [![pub](https://img.shields.io/pub/v/relax_pay.svg?label=%20)](https://pub.dev/packages/relax_pay) | Payments |
| **[env_builder_cli](packages/env_builder_cli)** | [![pub](https://img.shields.io/pub/v/env_builder_cli.svg?label=%20)](https://pub.dev/packages/env_builder_cli) | Typed environment-config generator |

## 🔦 Spotlight: `relax_cli`

The flagship. It scaffolds a complete app **and** gives you a quality platform to keep it clean as it grows.

```bash
dart pub global activate relax_cli

# Scaffold a Clean Architecture app (pick your state management)
relax create my_app -a bloc

# Analyze architecture, tests, and coverage — on ANY Flutter project
cd my_app && relax quality

# See it all in an interactive local dashboard
relax quality --dashboard --test --coverage
```

`relax quality` reads any Flutter project — regardless of state management — and reports architecture violations, code smells, missing tests, coverage by layer/feature, and a 0–100 health score. It can even **generate the missing tests and use cases** for you (new files only — never rewriting your source) and gate your CI on quality.

👉 **[Full `relax_cli` documentation →](packages/relax_cli/README.md)**

## 🚀 Quickstart

This repo is a [Dart pub workspace](https://dart.dev/tools/pub/workspaces) (SDK ≥ 3.11) — one resolution for every package.

```bash
git clone https://github.com/KalybosPro/relax-tech.git
cd relax-tech
dart pub get          # resolves every package at once
```

Work on a single package by `cd`-ing into it under [`packages/`](packages/). To just *use* a published package, add it as usual:

```bash
dart pub add relax_orm
dart pub global activate relax_cli
```

## Roadmap

Planned and in-progress work (upvote or propose via [issues](https://github.com/KalybosPro/relax-tech/issues)):

- [ ] `relax quality` — incremental analysis cache for large monorepos
- [ ] `relax quality` — optional AI advisor (opt-in, signatures only, off by default)
- [ ] `relax quality` — automatic PR comments with the score delta
- [ ] More scaffolding templates and generators
- [ ] Broader CI coverage across all suite packages
- [ ] Richer `relax_orm` querying & migrations

Have an idea? [Open a feature request](https://github.com/KalybosPro/relax-tech/issues/new?template=feature_request.yml) — the roadmap is community-driven.

## 🤝 Contributing

Contributions of every size are welcome — code, docs, tests, bug reports, and ideas. First-timers especially! 💚

- 📖 Read the **[Contributing guide](CONTRIBUTING.md)** for setup and conventions.
- 🌱 Look for **[good first issues](https://github.com/KalybosPro/relax-tech/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22)**.
- 🐛 Found a bug? **[File a report](https://github.com/KalybosPro/relax-tech/issues/new?template=bug_report.yml)**.
- 💬 Questions or ideas? Start a **[discussion](https://github.com/KalybosPro/relax-tech/discussions)**.

Everyone participating agrees to our **[Code of Conduct](CODE_OF_CONDUCT.md)**. Security issue? See the **[Security policy](SECURITY.md)**.

<details>
<summary><b>Repository layout</b></summary>

```
relax-tech/
├─ packages/
│  ├─ relax_cli/              # CLI + quality platform
│  ├─ relax_orm/              # local-first ORM
│  ├─ relax_orm_generator/    # ORM code generation
│  ├─ relax_image_picker/     # media picker
│  ├─ relax_pay/              # payments
│  ├─ relax_storage/          # storage
│  └─ env_builder_cli/        # env config generator
├─ .github/                   # CI, issue & PR templates
└─ pubspec.yaml               # workspace root
```

Each package keeps its own `pubspec.yaml`, version, changelog, and `LICENSE`, and is published independently. `env_builder_cli` lives in the monorepo but resolves independently (it needs a different `analyzer` version), so it isn't a workspace member.

</details>

<details>
<summary><b>Migrating from the old standalone repositories</b></summary>

These repos are **archived** and read-only; their code now lives under `packages/`. Published pub.dev packages are unaffected — `dart pub add <package>` keeps working exactly as before.

| Old repo | Now at |
|---|---|
| `KalybosPro/relax` (relax_cli) | [`packages/relax_cli`](packages/relax_cli) |
| `KalybosPro/relax_orm` | [`packages/relax_orm`](packages/relax_orm) |
| `KalybosPro/relax_orm_generator` | [`packages/relax_orm_generator`](packages/relax_orm_generator) |
| `KalybosPro/relax_image_picker` | [`packages/relax_image_picker`](packages/relax_image_picker) |
| `KalybosPro/relax_storage` | [`packages/relax_storage`](packages/relax_storage) |
| `KalybosPro/env_builder_cli` | [`packages/env_builder_cli`](packages/env_builder_cli) |

> The `relax_cli` package was previously hosted at `KalybosPro/relax` (the bare `relax` repo), which is why this monorepo uses the distinct name `relax-tech`. See [MIGRATION.md](MIGRATION.md) for details.

</details>

## 📄 License

[MIT](LICENSE) © 2025 KalybosPro — free for personal and commercial use.

<div align="center">
<sub>Built with Dart 💙 — if Relax helps you, consider giving it a ⭐.</sub>
</div>
