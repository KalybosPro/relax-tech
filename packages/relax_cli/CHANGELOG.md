## 1.1.0

- **Added** `relax quality` — a read-only architecture and code-quality analyzer for any Flutter project, independent of state management (GetX, Bloc/Cubit, Riverpod, Provider, MobX, or none). It never writes to source files and never runs `flutter test`.
  - Parses `lib/` with the official `package:analyzer` AST (no external tooling), classifying each file into a layer (widget/controller/usecase/repository/datasource/api_service/model) and detecting the state-management flavor in use.
  - Reports **architecture violations** (`Controller → API`, `Repository missing`), **quality issues** (file length, function length, cyclomatic complexity, duplication, dead code, unused imports, oversized `build()` methods), **missing tests** for detected business functions, and a weighted **project score** (0–100).
  - `relax quality --check` (default) prints a console report; `--json` writes `relax-quality-report.json`; `--ci` additionally writes a JUnit XML and exits non-zero when configured thresholds (`minCoverage`, `maxViolations`, `maxIssues`, `failOnRegression`) are exceeded. `-p/--path` restricts analysis to a sub-path.
  - Thresholds, score weights, business-verb dictionary, and ignore globs are configurable via a `quality` section in `.relaxrc` (plus an optional `.relaxignore`).
  - `--generate-tests` writes `mocktail`-based test scaffolds for untested business functions — one `*_test.dart` per function mirroring the source path, with a `group`/`test` per scenario (success, invalid input, network/server error, timeout) derived from the return type, plus mock/fake declarations for detected repository/service dependencies. Generation is **non-destructive**: new files only, never overwriting; `--dry-run` previews, `-y/--yes` skips the prompt. Scaffolds compile as-is (imports and mock bodies are commented, tests `skip`-marked) so the suite stays green until completed.
  - **Run history & trends.** Each run is recorded to an append-only `.relax/quality/history.jsonl` (score, coverage, test counts, violation count, timestamp, and the git commit SHA when available) — a dependency-free JSONL store, no native SQLite required. The report's `previousScore`/delta is populated from the last run, the dashboard gains a **score-over-time line chart** (`/api/history`), and `--ci` regression gating (`failOnRegression`) now compares against real history. Retention defaults to the last 90 runs (`historyRetention` in `.relaxrc`); `--no-history` disables reading/recording.
  - `--test` runs `flutter test --machine`, parses the structured results (total/passed/failed/skipped/duration + failures), shows them in the report, and folds test health into the project score.
  - `--coverage` runs `flutter test --coverage`, parses `coverage/lcov.info`, and aggregates line coverage **by layer** and **by feature** (folder under `lib/features/`, with an `unknown` fallback for unmapped files). Overall coverage feeds the score and the per-feature percentages drive a console heatmap; the full breakdown (incl. per-file counts) is included in the JSON report.
  - `--dashboard` serves an interactive web dashboard from a self-contained, embedded single-page app (vanilla HTML/CSS/JS — no build step, no runtime dependency) over a local `dart:io` server bound to loopback only (`127.0.0.1`, default port 8080, `--port` to change, `--no-open` to skip launching the browser). Panels: circular project-score gauge, coverage bars by layer, architecture badges (clean flow / repository / usecases / DI), test results, violations, quality issues, missing tests, a per-feature coverage heatmap, and a clickable dependency graph laid out by layer (UI → Controller → UseCase → Repository → Datasource → API). Data is served pre-computed via `/api/report` (plus granular `/api/score`, `/api/coverage`, `/api/violations`, `/api/graph`, `/api/history`); the SPA never recalculates a score. Combine with `--test`/`--coverage` to populate those panels.
  - `--generate-usecases` extracts a UseCase for each business function that lacks one. Detection is name-aware (tolerates `UseCase`/`Usecase` casing and an `Abstract` prefix); generation mirrors the spec template — injected repository/service dependencies plus an `execute(...)` method whose signature matches the function, reconstructing the primary infrastructure call when recoverable. It is strictly **non-destructive**: only **new files** are written (the source controller and its call sites are never rewritten — that transformation is left as reviewed guidance), and every run journals a reversible unified-diff patch under `.relax/quality/patches/<timestamp>/` (auto-added to `.gitignore`). `--dry-run` prints the diff; `-y/--yes` skips the prompt.

## 1.0.1

- **Changed** generated project dependencies to the current stable RelaxORM: `relax_orm: ^1.0.0` (was `^0.1.4`) and `relax_orm_generator: ^0.1.7` (was `^0.1.6`), across all four architectures. The `Collection` CRUD used by generated modules is source-compatible with RelaxORM 1.0.0.

## 1.0.0

First stable release. The command surface and generated project structure are now considered stable.

- **Added** an automatic navigation layer to generated projects for **all four architectures**.
  - `relax create` now scaffolds a router in the app composition root — `lib/app/router/app_router.dart` (go_router) for Bloc/Provider/Riverpod, or `lib/app/router/app_pages.dart` (GetX `getPages`) for GetX — and wires `MaterialApp.router` / `GetMaterialApp(getPages:)`. The router lives in `app/`, so features never depend on it (Clean Architecture dependency rule preserved).
  - Each feature owns its route identity: generated pages expose `static const routeName` / `routePath`. Navigate with `context.goNamed(CartPage.routeName)` (go_router) or `Get.toNamed(CartPage.routePath)` (GetX).
  - `relax g feature <name>` now **auto-registers** the feature's route — a `GoRoute` for go_router architectures, or a `GetPage` carrying the feature's `Binding` for GetX — and exports the feature from `features/features.dart`, with no manual editing. Route name/path derive from the full path spec, so `auth/login` and `admin/login` don't collide.
  - Opt out with `relax g feature <name> --no-route`.
  - Insertion is idempotent and anchor-based (`// relax:router-*`); re-running never duplicates a route, and a missing router/anchor degrades to a warning instead of failing.
- **Added** `relax generate router` — retroactively scaffolds the navigation layer into an **existing** project (created before navigation support, or where the router was removed).
  - Auto-detects the architecture, creates the router file, gives `HomePage` its `routeName`/`routePath`, rewires `app/view/app.dart` to `MaterialApp.router` / `GetMaterialApp(getPages:)`, adds the `go_router` dependency (non-GetX), and creates the `features/features.dart` barrel from existing features.
  - Idempotent and safe: re-running reports "already present", and any hand-customized `app.dart` it can't recognize degrades to actionable warnings instead of corrupting the file.
- **Added** an aggregate `lib/features/features.dart` barrel that re-exports every feature. It is the single import the router uses to reach feature pages. `relax generate feature` registers each new feature there automatically (replacing per-feature router imports).
- **Changed** `relax generate page` — the page name may now be given as a single path spec (`relax g page product/product_details`, leaf = page) in addition to the two-argument form. The new page is **auto-exported** from its feature barrel, and **registered as a child route of its feature**: a nested `GoRoute` under the feature route for go_router, or a flat `GetPage` (with the feature `Binding`) at `/<feature>/<page>` for GetX. Pass `--no-route` to skip.

## 0.1.7

- **Added** path-spec support to every `relax generate` subcommand — the name argument may now include a `/`-separated parent path, and the missing folders are created before the component is generated.
  - `relax g feature auth/login` creates `lib/features/auth/` (if needed) then generates the `login` feature inside it.
  - Works at arbitrary depth, e.g. `relax g feature account/admin/login`.
  - Applies to `feature`, `model`, `module`, and `page` (whose target feature folder may now be nested).
  - Class and file names are derived from the **last segment only** (`auth/login` → `LoginBloc`, `login.dart`); the prefix is used purely as a path.
  - Each path segment is validated as a Dart name; a plain name with no `/` behaves exactly as before (fully backwards compatible).
- **Added** `relax generate page <folder_name> <page_name>` — generates a Page + View pair inside an existing feature folder.
  - Auto-detects the project architecture (Bloc, Provider, Riverpod, GetX) or accepts `-a` to override.
  - Generates `<page_name>_page.dart` and `<page_name>_view.dart` in `lib/features/<folder_name>/view/`.
  - Each architecture produces the correct imports and widget types (BlocProvider/BlocBuilder, ChangeNotifierProvider, ConsumerStatefulWidget/ConsumerWidget, GetView).
  - Validates that the target feature folder exists and that the page does not already exist.
  - Prints a hint to add the new page export to the feature's barrel file.

## 0.1.6

- **Added** `relax pub get` — runs `flutter pub get` in the current project.
- **Added** `relax pub add <package>` — runs `flutter pub add`; accepts `-V <constraint>` to pin a version.
- **Added** `relax build apk` — formats code then builds an optimized release APK with obfuscation, split-debug-info, tree-shaking, and split-per-ABI.
- **Added** `relax build aab` — formats code then builds an optimized release AAB (Android App Bundle) for Google Play.
- **Added** `relax clean` — runs `flutter clean` in the current project.
- **Added** FVM auto-detection — all Flutter commands use `fvm flutter` automatically when `.fvm/fvm_config.json` is present.
- **Added** `--flavor` (`-f`) and `--target` (`-t`) options for `build apk` and `build aab`; defaults to `production` flavor and `lib/main_<flavor>.dart` entry point.

## 0.1.5

- **Added** shared encrypted local storage scaffolding via `relax_storage`, including a generated `CachedStorage` service in the app core.
- **Added** `ENCRYPTION_KEY` to generated flavor environment files and wired it into `RelaxStorage` initialization.
- **Updated** generated project dependencies to `relax_orm ^0.1.4`, `relax_orm_generator ^0.1.6`, and `relax_storage ^1.0.1`.
- **Fixed** generated DI and bootstrap templates so Bloc, Provider, Riverpod, and GetX projects initialize storage consistently and import the cache helper from the correct package path.

## 0.1.4

- **Added** shared encrypted local storage scaffolding via `relax_storage`, including a generated `CachedStorage` service in the app core.
- **Added** `ENCRYPTION_KEY` to generated flavor environment files and wired it into `RelaxStorage` initialization.
- **Updated** generated project dependencies to `relax_orm ^0.1.3`, `relax_orm_generator ^0.1.5`, and `relax_storage ^1.0.1`.
- **Fixed** generated DI and bootstrap templates so Bloc, Provider, Riverpod, and GetX projects initialize storage consistently and import the cache helper from the correct package path.

## 0.1.3

- **Fixed** generated Flutter app templates to include `flutter_localizations` and correct relative `core` imports for Bloc, GetX, Provider, and Riverpod starter projects.
- **Fixed** generated widget test scaffolding by wrapping `const App()` inside `TranslationProvider` correctly.
- **Improved** `relax create` output by adding `flutter pub get` to the next steps instructions.
- **Removed** an incomplete stray generator file from the repository.

## 0.1.2

- **Fixed** generated `build.gradle.kts` failing to compile with Kotlin DSL errors.
  - Replaced Groovy syntax (`def`, `new Properties()`, single-quoted strings, `withReader`, `toInteger()`) with valid Kotlin DSL (`val`, `Properties()`, double-quoted strings, `.reader().use {}`, `.toInt()`).
  - Fixed deprecated `kotlinOptions` → `kotlin { compilerOptions {} }` block.
  - Fixed `Unresolved reference: it` in signing config by using explicit named lambda parameter.
  - Added required `import java.util.Properties` and `import java.io.FileInputStream`.

## 0.1.1

- Added built-in internationalization (i18n) support via **slang**.
  - Projects are scaffolded with `fr` (base) and `en` locale JSON files.
  - `build.yaml` is generated with slang configuration.
  - Translations are auto-generated after `relax create` via `dart run slang` + `build_runner`.
- Automatic `flutter pub get` and code generation run at the end of `relax create`.
- Patched iOS `Info.plist` with supported locales during project creation.
- Improved generated `README.md` with flavor run commands and translation regeneration instructions.
- Removed sample `product` and `user` modules from the example project.
- Removed redundant `flutter pub get` from post-create instructions (now runs automatically).

## 0.1.0

- Initial release.
- `relax create` — scaffold Flutter projects with Bloc, Provider, Riverpod, or GetX.
- `relax generate feature` — add feature modules with auto-detected architecture.
- `relax generate module` — add domain/data modules with RelaxORM integration.
- `relax generate model` — add standalone ORM model classes with `@RelaxTable`.
- `relax doctor` — check Dart, Flutter, and project environment.
- Automatic `build_runner` execution after module and model generation.
- Material 3 theming with customizable color palette and font.
- Android flavor configuration (development, staging, production).
- Environment package generation via `env_builder`.
