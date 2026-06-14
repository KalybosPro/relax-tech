# Example

A Flutter project generated with [Relax CLI](https://pub.dev/packages/relax_cli).

## Getting Started

```bash
cd example
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

## Running the App

This project uses **flavors** for environment separation. Use one of the following commands:

```bash
# Development
flutter run --flavor development -t lib/main_development.dart

# Staging
flutter run --flavor staging -t lib/main_staging.dart

# Production
flutter run --flavor production -t lib/main_production.dart
```

## Architecture

This project uses **Bloc** for state management.

```
lib/
├── app/              → Application root (MaterialApp)
├── core/             → Theme, colors, typography, DI
├── i18n/             → Localization (slang)
└── features/         → Feature modules (home, ...)
    └── <feature>/
        ├── bloc/     → Bloc, Events, States
        └── view/     → Pages & Widgets
```

## Localization (i18n)

This project uses [slang](https://pub.dev/packages/slang) for internationalization.

Translation files are located in `lib/i18n/`:

| File | Description |
|------|-------------|
| `fr.i18n.json` | Base locale (French) |
| `en.i18n.json` | English |

### Adding a new locale

1. Create a new file `lib/i18n/<locale>.i18n.json` (e.g. `es.i18n.json`).
2. Copy the structure from `fr.i18n.json` and translate the values.
3. Run the code generator:

```bash
dart run slang
```

### Using translations in code

```dart
import 'package:example/i18n/slang/translations.g.dart';

// Access translations
final text = t.home.welcome; // "Bienvenue !"

// Change locale at runtime
LocaleSettings.setLocale(AppLocale.en);
```

### iOS configuration

For iOS to recognize supported locales, add the following to `ios/Runner/Info.plist` inside the `<dict>` tag:

```xml
<key>CFBundleLocalizations</key>
<array>
  <string>fr</string>
  <string>en</string>
</array>
```

> If you add a new locale, remember to add it here as well.

## Code Generation

This project uses `build_runner` for code generation (slang translations via `build.yaml`, RelaxORM schemas).

After any change to `.i18n.json` files or `@RelaxTable` models, run:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Or use watch mode during development:

```bash
dart run build_runner watch --delete-conflicting-outputs
```

## Adding Features, Modules & Models

```bash
# Add a new feature (auto-detects architecture)
relax generate feature <name>

# Add a domain/data module (with RelaxORM)
relax generate module <name>

# Add a standalone ORM model
relax generate model <name>
```

## Testing

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run a specific test file
flutter test test/app/view/app_test.dart
```

## Environment Variables

Environment files are located at the project root:

| File | Purpose |
|------|---------|
| `.env.development` | Development settings |
| `.env.staging` | Staging settings |
| `.env.production` | Production settings |

After modifying `.env.*` files, regenerate the env package:

```bash
env_builder build -e .env.development,.env.production,.env.staging
```

## VS Code

Launch configurations are pre-configured in `.vscode/launch.json`. Use the **Run and Debug** panel to select a flavor.
