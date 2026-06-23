# relax_cli

A CLI tool to generate Flutter projects with clean architecture, ready to run.

Similar to [Very Good CLI](https://github.com/VeryGoodOpenSource/very_good_cli), relax scaffolds a complete Flutter project with the state management architecture of your choice.

## Installation

```bash
# From pub.dev (when published)
dart pub global activate relax_cli

# From source
dart pub global activate --source path .
```

## Commands

### `relax create` — Create a new project

```bash
relax create my_app                    # interactive architecture prompt
relax create my_app -a bloc            # direct mode
relax create my_app --architecture riverpod

# Customization options
relax create my_app -a bloc \
  --org com.mycompany \
  --description "My awesome app" \
  --primary-color 1565C0 \
  --font Poppins
```

| Option | Default | Description |
|--------|---------|-------------|
| `-a, --architecture` | *(prompt)* | `bloc`, `provider`, `riverpod`, `getx` |
| `-o, --org` | `com.example` | App package prefix (e.g. `com.mycompany`) |
| `-d, --description` | *"A Flutter project..."* | pubspec.yaml description |
| `--primary-color` | `6750A4` | Hex seed color for Material 3 palette |
| `--font` | `Roboto` | `Roboto`, `Inter`, `Poppins`, `Lato`, `Montserrat` |

### `relax generate feature` — Add a feature module

```bash
relax generate feature settings        # auto-detects architecture
relax generate feature cart -a provider # override architecture
relax g feature profile                # shorthand alias
relax g feature auth/login             # nested: creates lib/features/auth/ then the login feature
```

Any generated name may include a `/`-separated parent path. The missing folders are created first, and class/file names are derived from the **last segment only** (`auth/login` → `LoginBloc`, `login.dart`). Works at arbitrary depth (`account/admin/login`); a plain name with no `/` behaves as before.

### `relax generate page` — Add a page to an existing feature

```bash
relax generate page home detail         # add detail page to home feature
relax generate page auth login -a bloc  # override architecture
relax generate page auth/login form     # nested feature folder
relax g page settings notifications     # shorthand alias
```

Generates a `Page` + `View` widget pair inside `lib/features/<folder_name>/view/`. The target feature folder must already exist (create it with `relax generate feature` first) and may be nested (e.g. `auth/login`).

```
lib/features/home/view/
├── detail_page.dart    # new — wired to the feature's state manager
└── detail_view.dart    # new — Scaffold with title and body
```

After generation, add the export to the feature's barrel file:

```dart
// lib/features/home/home.dart
export 'view/detail_page.dart';
```

### `relax generate module` — Add a domain/data module

```bash
relax generate module product          # generates in lib/modules/
relax generate module user -o core/domain  # custom output directory
relax generate module account/user     # nested: lib/modules/account/user/
relax g module order                   # shorthand alias
```

Modules are fully integrated with **RelaxORM**: the model is annotated with `@RelaxTable()`, the data source uses `Collection<T>` for typed CRUD + reactive streams, and `build_runner` is launched automatically to generate the schema.

### `relax generate model` — Add a standalone ORM model

```bash
relax generate model user_profile      # generates in lib/models/
relax g model payment -o core/models   # custom output directory
relax g model billing/invoice          # nested: lib/models/billing/invoice.dart
```

### `relax doctor` — Check your environment

```bash
relax doctor
```

```
relax doctor
v0.1.0

  [+] Dart SDK — 3.11.0
  [+] Flutter SDK — 3.29.0
  [+] Flutter project — detected
```

### `relax pub` — Package management

```bash
relax pub get                        # flutter pub get
relax pub add http                   # flutter pub add http
relax pub add http -V ^1.2.0         # flutter pub add http:^1.2.0
```

### `relax build` — Build release artifacts

```bash
relax build apk                      # production APK (split per ABI)
relax build apk -f staging           # staging APK
relax build apk -f production -t lib/main_production.dart

relax build aab                      # production AAB for Google Play
relax build aab -f staging

relax b apk                          # shorthand alias
```

| Option | Default | Description |
|--------|---------|-------------|
| `-f, --flavor` | `production` | `development`, `staging`, `production` |
| `-t, --target` | `lib/main_<flavor>.dart` | Entry-point Dart file |

Both commands format code first, then apply optimization flags automatically:

| Flag | APK | AAB |
|------|-----|-----|
| `--obfuscate` + `--split-debug-info` | yes | yes |
| `--tree-shake-icons` | yes | yes |
| `--split-per-abi` | yes | no (Play handles it) |

### `relax clean` — Clean build artifacts

```bash
relax clean
```

### `relax sdk` — Flutter SDK version management

Manage multiple Flutter SDK versions without external tools.

```bash
relax sdk install 3.29.0             # install a specific version
relax sdk install stable             # install by channel
relax sdk use 3.29.0                 # pin version for this project
relax sdk use 3.29.0 --global        # set as global default
relax sdk list                       # list installed versions
relax sdk releases                   # browse available releases
relax sdk releases --channel beta    # filter by channel
relax sdk global                     # show current global version
relax sdk global 3.29.0              # set global version
relax sdk remove 3.24.0              # uninstall a version
relax sdk flutter doctor             # run flutter doctor with pinned SDK
relax sdk flutter build apk          # run any flutter command with pinned SDK
relax sdk dart pub global activate X # run dart command with pinned SDK
relax sdk exec make build            # run any command with pinned SDK on PATH
relax sdk spawn 3.29.0 bash          # open shell with specific SDK
relax sdk config                     # show SDK manager config
relax sdk doctor                     # check SDK manager environment
relax sdk destroy                    # remove all cached SDKs and config
```

| Sub-command | Description |
|-------------|-------------|
| `install <version>` | Download and install a Flutter SDK version |
| `use <version>` | Pin a version for the current project |
| `list` | List all installed versions |
| `releases` | Browse available Flutter releases |
| `global [version]` | Get or set the global default version |
| `remove <version>` | Uninstall a version |
| `flutter <args>` | Run a Flutter command with the pinned SDK |
| `dart <args>` | Run a Dart command with the pinned SDK |
| `exec <cmd>` | Run any command with the pinned SDK on PATH |
| `spawn <version> <cmd>` | Run a command with a specific SDK version |
| `config` | Show or update SDK manager configuration |
| `doctor` | Check the SDK manager environment |
| `destroy` | Remove all cached SDKs and configuration |

Partial versions are automatically resolved (`3.29` → `3.29.0`).

### Other commands

```bash
relax --help          # show help
relax --version       # show version
relax generate -h     # show generate subcommands
```

## FVM support

All Flutter commands (`pub get`, `pub add`, `build apk`, `build aab`, `clean`) automatically detect [FVM](https://fvm.app/). If `.fvm/fvm_config.json` is present in the project root, `fvm flutter` is used instead of `flutter` — no configuration needed.

## Supported architectures

| Architecture | `create` | `generate feature` | `generate page` | State management |
|-------------|----------|--------------------|-----------------|------------------|
| **Bloc**    | yes | yes | yes | `flutter_bloc`, `equatable` |
| **Provider**| yes | yes | yes | `provider`, `ChangeNotifier` |
| **Riverpod**| yes | yes | yes | `flutter_riverpod`, `Notifier` |
| **GetX**    | yes | yes | yes | `get`, `GetxController`, `Obx` |

## Generated project structure (Bloc example)

```
my_app/
├── lib/
│   ├── main_development.dart        # development flavor entry point
│   ├── main_staging.dart            # staging flavor entry point
│   ├── main_production.dart         # production flavor entry point
│   ├── bootstrap.dart               # app initialization
│   ├── app/
│   │   └── view/app.dart            # MaterialApp + theme
│   ├── core/
│   │   ├── di/                      # dependency injection (GetIt)
│   │   └── theme/
│   │       ├── app_colors.dart      # Material 3 color palette
│   │       ├── app_theme.dart       # Light & dark ThemeData
│   │       └── app_typography.dart  # M3 type scale
│   ├── features/
│   │   └── home/
│   │       ├── bloc/                # Bloc, Events, States
│   │       └── view/                # Page & View
│   └── i18n/
│       └── slang/                   # translations (generated by slang)
├── test/
├── pubspec.yaml
└── analysis_options.yaml
```

After creation:

```bash
cd my_app
relax pub get

# Run a flavor
flutter run --flavor development -t lib/main_development.dart
flutter run --flavor staging     -t lib/main_staging.dart
flutter run --flavor production  -t lib/main_production.dart

# Regenerate translations after editing .i18n.json files
dart run build_runner build --delete-conflicting-outputs
```

## Generated feature structure

```bash
relax g feature settings
```

```
lib/features/settings/
├── settings.dart                        # barrel
├── bloc/                                # (or notifiers/, providers/, controllers/)
│   ├── settings_bloc.dart
│   ├── settings_event.dart
│   └── settings_state.dart
└── view/
    ├── settings_page.dart               # Provider wrapper
    └── settings_view.dart               # UI
```

## Generated page structure

```bash
relax g page home detail
```

```
lib/features/home/view/
├── detail_page.dart    # Page widget (wires into the feature's state manager)
└── detail_view.dart    # Scaffold UI
```

## Generated module structure

```bash
relax g module product
```

```
lib/modules/product/
├── product.dart                         # barrel
├── models/
│   ├── product.dart                     # @RelaxTable model
│   └── product.g.dart                   # generated schema (auto)
├── repositories/
│   ├── product_repository.dart          # abstract interface
│   └── product_repository_impl.dart     # implementation
└── data_sources/
    └── product_data_source.dart         # RelaxORM Collection<T>
```

## What you get out of the box

- **Material 3** theme with light/dark mode and customizable color palette
- **Multi-flavor** support: development, staging, production entry points
- **Feature-based** architecture with barrel files
- **Sealed classes** for events and states (Dart 3+)
- **Clean Architecture** modules with repository pattern
- **RelaxORM** integration with typed CRUD, reactive streams, and auto-generated schemas
- **Dependency injection** via GetIt
- **Internationalization** via slang (`.i18n.json` → generated Dart)
- **Auto-detection** of your project's architecture for `generate feature`
- **Automatic code generation** — `build_runner` runs after module/model creation
- Ready-to-run project with a Home feature example

## Development

```bash
dart test                  # run tests
dart test --concurrency=1  # sequential (tests use Directory.current)
dart analyze               # static analysis
dart run bin/relax.dart create my_app -a bloc   # run locally
dart compile exe bin/relax.dart -o relax         # native binary
```

## License

MIT
