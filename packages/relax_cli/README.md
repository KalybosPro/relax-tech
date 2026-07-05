<div align="center">

# ⚡ relax_cli

### Scaffold, ship, and *keep* Flutter apps clean — from one CLI.

Generate a production-ready Flutter project in seconds, then measure and improve its architecture, tests, and coverage as it grows.

[![pub version](https://img.shields.io/pub/v/relax_cli.svg?logo=dart&label=pub.dev)](https://pub.dev/packages/relax_cli)
[![pub points](https://img.shields.io/pub/points/relax_cli)](https://pub.dev/packages/relax_cli/score)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![platform](https://img.shields.io/badge/platform-windows%20%7C%20macos%20%7C%20linux-lightgrey.svg)](https://pub.dev/packages/relax_cli)

```bash
dart pub global activate relax_cli
```

</div>

---

Most scaffolding tools stop the moment your project is created. **relax keeps going.** It generates a clean, multi-flavor Flutter app with the state management *you* choose — Bloc, Provider, Riverpod, or GetX — and then gives you a full **quality platform** to analyze architecture, generate tests, measure coverage, and track your project's health over time. All from your terminal, with zero config.

## Contents

- [Why relax?](#why-relax)
- [Quickstart](#quickstart)
- [The `relax quality` platform](#the-relax-quality-platform) — analyze, generate tests & use cases, dashboard, CI
- [Scaffolding and code generation](#scaffolding-and-code-generation)
- [Environment, packages, and builds](#environment-packages-and-builds)
- [Supported architectures](#supported-architectures)
- [What you get out of the box](#what-you-get-out-of-the-box)
- [Installation](#installation)
- [Development and contributing](#development-and-contributing)
- [License](#license)

## Why relax?

- 🏗️ **Real projects, not templates.** `relax create` scaffolds Clean Architecture, Material 3 theming, dependency injection, i18n, multi-flavor entry points, navigation, and a working example feature — ready to `flutter run`.
- 🔍 **A quality platform built in.** `relax quality` reads *any* Flutter project (regardless of state management) and reports architecture violations, code smells, missing tests, and a 0–100 health score — then generates the tests and use cases to fix them.
- 📊 **See it, don't guess it.** An embedded, offline **web dashboard** (`--dashboard`) with a score gauge, coverage heatmap, and clickable dependency graph. No accounts, no telemetry, localhost only.
- 🤖 **CI-ready.** JSON + JUnit reports, configurable quality gates, and score-regression detection out of the box.
- 🧩 **Batteries included.** Manage Flutter SDK versions, add packages, and build optimized release artifacts without leaving the CLI.
- 🚀 **One dependency-free binary.** Pure Dart. No Node, no native database, no build step.

## Quickstart

```bash
# Install
dart pub global activate relax_cli

# Create a Clean Architecture app (pick your state management)
relax create my_app -a bloc

# Run it
cd my_app
relax pub get
flutter run --flavor development -t lib/main_development.dart

# Later: check its health
relax quality
```

That's it — a real, running app with theming, navigation, DI, and tests, plus a quality baseline.

## The `relax quality` platform

Point it at **any** Flutter project — one you generated with relax, or a legacy codebase using GetX, Bloc/Cubit, Riverpod, Provider, MobX, or nothing at all. Analysis is **read-only and non-destructive** by default.

```bash
relax quality                     # instant health report in your terminal
relax quality --dashboard         # interactive web dashboard on localhost
relax quality --generate-tests    # scaffold mocktail tests for untested logic
relax quality --generate-usecases # extract UseCases from your controllers
relax quality --test --coverage   # run tests + coverage, fold into the score
relax quality --ci                # JSON + JUnit + quality gate for your pipeline
```

It parses `lib/` with the official Dart `analyzer`, classifies every file into a layer (widget → controller → usecase → repository → datasource → api_service → model), and surfaces:

| What it finds | Examples |
|---------------|----------|
| **Architecture violations** | A controller calling an API directly (`Controller → API`), a missing repository layer |
| **Code-quality issues** | File/function length, cyclomatic complexity, duplicated logic, dead code, unused imports, bloated `build()` methods |
| **Missing tests** | Business functions (`login`, `createOrder`, `fetch…`) with no matching `*_test.dart` |
| **Coverage** | Line coverage aggregated **by layer** and **by feature**, as a heatmap |
| **A single score** | A weighted 0–100 project score with a trend delta on every run |

And it doesn't just *report* — it **fixes**:

- **`--generate-tests`** writes `mocktail`-based test scaffolds (one `group`/`test` per scenario: success, invalid input, network/server error, timeout) for every untested business function.
- **`--generate-usecases`** extracts a UseCase class from each controller method that carries domain logic — injected dependencies, an `execute()` matching the signature, the infra call reconstructed for you.

> **Safe by design.** Generation only ever creates **new files** — it never rewrites your source. Every write is previewable with `--dry-run` and journals a reversible unified-diff patch under `.relax/quality/patches/`.

### The dashboard

```bash
relax quality --dashboard --test --coverage
```

A self-contained single-page app (ships inside the CLI — no build step, no external assets) served on `127.0.0.1` only. Score gauge, coverage bars by layer, architecture badges, test results, violations, a per-feature heatmap, a score-over-time trend chart, and a **clickable dependency graph** laid out UI → Controller → UseCase → Repository → Datasource → API.

### Ship it in CI

```yaml
# e.g. GitHub Actions
- run: relax quality --ci
```

Writes `relax-quality-report.json` + `relax-quality-junit.xml`, and exits non-zero when your thresholds aren't met. Configure everything in `.relaxrc`:

```jsonc
{
  "quality": {
    "rules": { "maxFileLength": 400, "maxFunctionLength": 50, "maxCyclomaticComplexity": 10 },
    "ci":    { "minCoverage": 80, "maxViolations": 5, "failOnRegression": true },
    "historyRetention": 90
  }
}
```

Every run is recorded to `.relax/quality/history.jsonl` (score, coverage, test counts, git SHA) — powering the score delta, the dashboard trend chart, and regression gating. Nothing leaves your machine.

<details>
<summary><b>Full <code>relax quality</code> option reference</b></summary>

| Option | Description |
|--------|-------------|
| `--check` | Read-only console report (default) |
| `--generate-tests` | Scaffold `mocktail` test files for untested business functions (new files only) |
| `--generate-usecases` | Extract a UseCase per controller method that lacks one (new files only; reversible patch journaled) |
| `--dry-run` | With a generator, preview (and print the diff) without writing |
| `-y, --yes` | Skip the generation confirmation prompt |
| `--test` | Run `flutter test --machine` and fold results into the report/score |
| `--coverage` | Run `flutter test --coverage`, aggregate LCOV by layer/feature |
| `--dashboard` | Serve the web dashboard on `localhost` (loopback only); `--port` to change, `--no-open` to skip the browser |
| `--json` | Write `relax-quality-report.json` |
| `--ci` | Write JSON + `relax-quality-junit.xml`; exit non-zero on gate failure |
| `--no-history` | Don't read or record run history |
| `-p, --path` | Restrict analysis to a sub-path (e.g. `lib/features/orders`) |

Generated tests are **scaffolds**: imports and mock bodies are commented and each case is `skip`-marked so they compile immediately. Add `mocktail` as a dev dependency, uncomment, fill in the assertions, and drop the `skip:`.

</details>

## Scaffolding and code generation

### `relax create` — a new project

```bash
relax create my_app                    # interactive architecture prompt
relax create my_app -a bloc            # or pick directly

relax create my_app -a riverpod \
  --org com.mycompany \
  --description "My awesome app" \
  --primary-color 1565C0 \
  --font Poppins
```

| Option | Default | Description |
|--------|---------|-------------|
| `-a, --architecture` | *(prompt)* | `bloc`, `provider`, `riverpod`, `getx` |
| `-o, --org` | `com.example` | App package prefix (e.g. `com.mycompany`) |
| `-d, --description` | *"A Flutter project…"* | pubspec.yaml description |
| `--primary-color` | `6750A4` | Hex seed color for the Material 3 palette |
| `--font` | `Roboto` | `Roboto`, `Inter`, `Poppins`, `Lato`, `Montserrat` |

### `relax generate` — add pieces to an existing project

```bash
relax g feature settings          # feature + auto-registered route
relax g feature auth/login         # nested feature folders, arbitrary depth
relax g page product/product_details   # page wired into its feature + child route
relax g module product             # Clean Architecture module with RelaxORM CRUD
relax g model user_profile         # standalone @RelaxTable ORM model
relax g router                     # retrofit navigation into an older project
```

- **Auto-detects** your project's architecture — no need to repeat `-a`.
- **Auto-wires routes** for every architecture (go_router `GoRoute` or GetX `GetPage` + `Binding`); idempotent, opt out with `--no-route`.
- **Auto-exports** new pages from the feature barrel and runs `build_runner` after module/model generation.

<details>
<summary><b>Generation details & examples</b></summary>

**`relax generate feature <name>`** — creates `lib/features/<name>/` with state-management folder (`bloc/`, `notifiers/`, `providers/`, or `controllers/`) + `view/` (Page + View) + barrel, and registers the route.

Any name may include a `/`-separated parent path; folders are created first and class names derive from the **last segment** (`auth/login` → `LoginBloc`, `login.dart`). Works at any depth.

| Architecture | Router file | Inserted entry | Navigate with |
|-------------|-------------|----------------|---------------|
| Bloc / Provider / Riverpod | `lib/app/router/app_router.dart` | `GoRoute` | `context.goNamed(<Name>Page.routeName)` |
| GetX | `lib/app/router/app_pages.dart` | `GetPage` + `Binding` | `Get.toNamed(<Name>Page.routePath)` |

**`relax generate page <feature> <page>`** (or `relax g page <feature>/<page>`) — generates a `Page` + `View` pair in `lib/features/<feature>/view/`, auto-exports it, and registers it as a **child route** of the feature. Pass `--no-route` to skip.

**`relax generate module <name>`** — a Clean Architecture module in `lib/modules/`, fully integrated with **RelaxORM**: `@RelaxTable()` model, `Collection<T>` typed CRUD + reactive streams, abstract repository + impl, and `build_runner` run automatically.

**`relax generate model <name>`** — a standalone `@RelaxTable` ORM model in `lib/models/`.

**`relax generate router`** — retroactively scaffolds the navigation layer into a project created before navigation support. Idempotent and safe: re-running reports *"already present"*, and hand-customized files degrade to warnings instead of corruption.

</details>

## Environment, packages, and builds

### `relax sdk` — manage Flutter SDK versions

No external tools required. Install, pin per-project or globally, and run any command against a specific SDK.

```bash
relax sdk install 3.29.0            # or: relax sdk install stable
relax sdk use 3.29.0               # pin for this project (--global for default)
relax sdk list                     # list installed versions
relax sdk releases --channel beta  # browse available releases
relax sdk flutter build apk        # run flutter with the pinned SDK
relax sdk exec make build          # run any command with the SDK on PATH
```

<details>
<summary><b>All <code>relax sdk</code> sub-commands</b></summary>

| Sub-command | Description |
|-------------|-------------|
| `install <version>` | Download and install a Flutter SDK version |
| `use <version>` | Pin a version for the current project (`--global` for default) |
| `list` | List all installed versions |
| `releases` | Browse available Flutter releases (`--channel` to filter) |
| `global [version]` | Get or set the global default version |
| `remove <version>` | Uninstall a version |
| `flutter <args>` / `dart <args>` | Run Flutter/Dart with the pinned SDK |
| `exec <cmd>` | Run any command with the pinned SDK on PATH |
| `spawn <version> <cmd>` | Run a command with a specific SDK version |
| `config` / `doctor` / `destroy` | Inspect config, check the environment, or reset |

Partial versions resolve automatically (`3.29` → `3.29.0`).

</details>

### `relax build` — optimized release artifacts

```bash
relax build apk                    # production APK, split per ABI
relax build apk -f staging         # staging flavor
relax build aab                    # production AAB for Google Play
```

Formats code first, then applies `--obfuscate`, `--split-debug-info`, `--tree-shake-icons`, and (APK) `--split-per-abi` automatically. `-f/--flavor` selects `development`/`staging`/`production`; `-t/--target` overrides the entry point.

### `relax pub`, `relax clean`, `relax doctor`

```bash
relax pub get                      # flutter pub get
relax pub add http -V ^1.2.0       # add a package at a version
relax clean                        # clean build artifacts
relax doctor                       # verify Dart, Flutter, and project setup
```

```
relax doctor
v1.1.0

  [+] Dart SDK — 3.11.0
  [+] Flutter SDK — 3.29.0
  [+] Flutter project — detected
```

> **FVM-aware:** every Flutter command auto-detects [FVM](https://fvm.app/). If `.fvm/fvm_config.json` is present, `fvm flutter` is used automatically — no configuration.

## Supported architectures

| Architecture | `create` | `generate feature` | `generate page` | State management |
|-------------|:--------:|:------------------:|:---------------:|------------------|
| **Bloc**    | ✅ | ✅ | ✅ | `flutter_bloc`, `equatable` |
| **Provider**| ✅ | ✅ | ✅ | `provider`, `ChangeNotifier` |
| **Riverpod**| ✅ | ✅ | ✅ | `flutter_riverpod`, `Notifier` |
| **GetX**    | ✅ | ✅ | ✅ | `get`, `GetxController`, `Obx` |

## What you get out of the box

- **Material 3** theming with light/dark mode and a customizable seed color
- **Multi-flavor** entry points: development, staging, production
- **Feature-based Clean Architecture** with barrel files and the repository pattern
- **Navigation** wired automatically (go_router / GetX) with type-safe route names
- **RelaxORM** integration: typed CRUD, reactive streams, auto-generated schemas
- **Dependency injection** via GetIt, **i18n** via slang, **sealed** events/states (Dart 3+)
- **Auto code generation** — `build_runner` runs after module/model creation
- A ready-to-run project with a working Home feature

<details>
<summary><b>Generated project structure (Bloc example)</b></summary>

```
my_app/
├── lib/
│   ├── main_development.dart        # flavor entry points
│   ├── main_staging.dart
│   ├── main_production.dart
│   ├── bootstrap.dart               # app initialization
│   ├── app/
│   │   ├── router/app_router.dart   # navigation
│   │   └── view/app.dart            # MaterialApp + theme
│   ├── core/
│   │   ├── di/                      # dependency injection (GetIt)
│   │   └── theme/                   # colors, theme, typography (Material 3)
│   ├── features/
│   │   ├── features.dart            # aggregate barrel
│   │   └── home/
│   │       ├── bloc/                # Bloc, Events, States
│   │       └── view/                # Page & View
│   └── i18n/slang/                  # translations (generated)
├── test/
├── pubspec.yaml
└── analysis_options.yaml
```

Module structure (`relax g module product`):

```
lib/modules/product/
├── product.dart                     # barrel
├── models/product.dart              # @RelaxTable model (+ product.g.dart, generated)
├── repositories/                    # abstract interface + implementation
└── data_sources/                    # RelaxORM Collection<T>
```

</details>

## Installation

```bash
# From pub.dev
dart pub global activate relax_cli

# From source
dart pub global activate --source path .
```

Make sure the pub global bin directory is on your `PATH` (`~/.pub-cache/bin` on macOS/Linux, `%LOCALAPPDATA%\Pub\Cache\bin` on Windows).

## Development and contributing

```bash
dart test                  # run tests
dart test --concurrency=1  # sequential (some tests use Directory.current)
dart analyze               # static analysis
dart run bin/relax.dart create my_app -a bloc   # run locally
dart compile exe bin/relax.dart -o relax         # native binary
```

Issues and PRs welcome — see [CONTRIBUTING.md](CONTRIBUTING.md). By participating you agree to the [Code of Conduct](CODE_OF_CONDUCT.md).

## License

[MIT](LICENSE) © 2025 KalybosPro
