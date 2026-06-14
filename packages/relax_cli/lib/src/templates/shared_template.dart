import 'package:mason/mason.dart';

/// Shared template content reused across all architecture templates.
abstract final class SharedTemplate {
  /// Prefixes a relative path with the mustache project directory.
  static String p(String path) => '{{project_name.snakeCase()}}/$path';

  /// Returns the common [TemplateFile] list (analysis_options, core/theme, env, i18n).
  static List<TemplateFile> coreFiles() => [
    TemplateFile(p('analysis_options.yaml'), analysisOptions),
    TemplateFile(p('lib/core/core.dart'), coreBarrel),
    TemplateFile(p('lib/core/theme/app_theme.dart'), appTheme),
    TemplateFile(p('lib/core/theme/app_colors.dart'), appColors),
    TemplateFile(p('lib/core/theme/app_typography.dart'), appTypography),
    TemplateFile(p('lib/core/cache/cached_storage.dart'), cachedStorage),
    // ── DI ──────────────────────────────────────────────────
    TemplateFile(p('lib/core/di/di.dart'), diSetup),
    // ── Env / Flavor ────────────────────────────────────────
    TemplateFile(p('.env.development'), envDevelopment),
    TemplateFile(p('.env.staging'), envStaging),
    TemplateFile(p('.env.production'), envProduction),
    // ── i18n (slang) ────────────────────────────────────────
    TemplateFile(p('lib/i18n/fr.i18n.json'), i18nStringsFr),
    TemplateFile(p('lib/i18n/en.i18n.json'), i18nStringsEn),
    TemplateFile(p('build.yaml'), buildYaml),
    // ── VS Code ─────────────────────────────────────────────
    TemplateFile(p('.vscode/launch.json'), vscodeLaunchJson),
  ];

  // ─── Analysis options ──────────────────────────────────────────

  static const analysisOptions = '''
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    prefer_const_constructors: true
    prefer_const_declarations: true
    avoid_print: true
''';

  // ─── i18n (slang) ───────────────────────────────────────────────

  static const i18nStringsEn = '''
{
  "appName": "{{project_name.titleCase()}}",
  "home": {
    "welcome": "Welcome!",
    "subtitle": "Your project is ready."
  }
}
''';

  static const i18nStringsFr = '''
{
  "appName": "{{project_name.titleCase()}}",
  "home": {
    "welcome": "Bienvenue !",
    "subtitle": "Votre projet est pr\\u00eat."
  }
}
''';

  static const buildYaml = '''
targets:
  \$default:
    builders:
      slang_build_runner:
        options:
          base_locale: fr
          fallback_strategy: base_locale
          input_directory: lib/i18n
          input_file_pattern: .i18n.json
          output_directory: lib/i18n/slang
          output_file_name: translations.g.dart
          string_interpolation: dart
          locale_handling: true
          flutter_integration: true
          flat_map: false
''';

  // ─── README helper ─────────────────────────────────────────────

  static String readme(String archName, String featureDir) =>
      '''
# {{project_name.titleCase()}}

A Flutter project generated with [Relax CLI](https://pub.dev/packages/relax_cli).

## Getting Started

```bash
cd {{project_name.snakeCase()}}
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

This project uses **$archName** for state management.

```
lib/
\u251c\u2500\u2500 app/              \u2192 Application root (MaterialApp)
\u251c\u2500\u2500 core/             \u2192 Theme, colors, typography, DI
\u251c\u2500\u2500 i18n/             \u2192 Localization (slang)
\u2514\u2500\u2500 features/         \u2192 Feature modules (home, ...)
    \u2514\u2500\u2500 <feature>/
        \u251c\u2500\u2500 $featureDir
        \u2514\u2500\u2500 view/     \u2192 Pages & Widgets
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
import 'package:{{project_name.snakeCase()}}/i18n/slang/translations.g.dart';

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
''';

  // ─── App barrel ────────────────────────────────────────────────

  static const appBarrel = '''
export 'view/app.dart';
''';

  // ─── App test ──────────────────────────────────────────────────

  static const appTest = '''
import 'package:flutter_test/flutter_test.dart';

import 'package:{{project_name.snakeCase()}}/app/app.dart';
import 'package:{{project_name.snakeCase()}}/i18n/slang/translations.g.dart';

void main() {
  testWidgets('App renders HomePage', (tester) async {
    LocaleSettings.setLocale(AppLocale.en);
    await tester.pumpWidget(TranslationProvider(child: const App()));
    expect(find.text(t.appName), findsOneWidget);
  });
}
''';

  // ─── Core barrel ───────────────────────────────────────────────

  static const coreBarrel = '''
export 'di/di.dart';
export 'theme/app_colors.dart';
export 'theme/app_theme.dart';
export 'theme/app_typography.dart';
export 'cache/cached_storage.dart';
export '../i18n/slang/translations.g.dart';
''';

  // ─── Cache ─────────────────────────────────────────────────────

  static const cachedStorage = '''
import 'package:env/env.dart';
import 'package:relax_storage/relax_storage.dart';

/// Small abstraction around local secure storage used by the app.
///
/// `CachedStorage` centralizes read/write access to cached values so the rest
/// of the codebase does not depend directly on the storage package. It is
/// currently used to persist the authentication token in encrypted storage.
///
/// Example:
///
/// ```dart
/// final storage = getIt<CachedStorage>();
///
/// // Save the token
/// await storage.setToken('eyJhbGciOiJIUzI1NiIs');
///
/// // Read the token
/// final token = storage.token;
/// ```
class CachedStorage {

  CachedStorage(EnvValue env) : box = RelaxStorage(env(Env.encryptionKey));

  final RelaxStorage box;

  Future<void> setToken(String token) =>
      box.save<String>('TOKENDATASTORAGEKEY', token);

  String? get token => box.read<String>('TOKENDATASTORAGEKEY');
}
''';

  // ─── Theme ─────────────────────────────────────────────────────

  static const appColors = '''
import 'package:flutter/material.dart';

/// Central color palette for the application.
///
/// Change [seed] to update the entire Material 3 color scheme.
/// Add custom overrides below as needed.
abstract final class AppColors {
  /// Primary seed color — the entire M3 palette derives from this.
  static const seed = Color(0xFF{{primary_color}});

  // ── Custom overrides (optional) ──────────────────────────────
  // Add project-specific colors here, for example:
  // static const success = Color(0xFF4CAF50);
  // static const warning = Color(0xFFFFC107);
}
''';

  static const appTheme = '''
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// Application theme data (light & dark).
///
/// Uses [ColorScheme.fromSeed] so the entire palette is derived
/// from a single seed color defined in [AppColors.seed].
abstract final class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.seed,
        ),
        textTheme: AppTypography.textTheme,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.seed,
          brightness: Brightness.dark,
        ),
        textTheme: AppTypography.textTheme,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      );
}
''';

  static const appTypography = '''
import 'package:flutter/material.dart';

/// Application text styles.
///
/// Based on Material 3 type scale.
/// To use a Google Font, add `google_fonts` to pubspec.yaml
/// and replace the fontFamily references.
abstract final class AppTypography {
  static const _fontFamily = '{{font_family}}';

  static const textTheme = TextTheme(
    displayLarge: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 57,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.25,
      height: 1.12,
    ),
    displayMedium: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 45,
      fontWeight: FontWeight.w400,
      height: 1.16,
    ),
    displaySmall: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 36,
      fontWeight: FontWeight.w400,
      height: 1.22,
    ),
    headlineLarge: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 32,
      fontWeight: FontWeight.w400,
      height: 1.25,
    ),
    headlineMedium: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 28,
      fontWeight: FontWeight.w400,
      height: 1.29,
    ),
    headlineSmall: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 24,
      fontWeight: FontWeight.w400,
      height: 1.33,
    ),
    titleLarge: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 22,
      fontWeight: FontWeight.w500,
      height: 1.27,
    ),
    titleMedium: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 16,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.15,
      height: 1.50,
    ),
    titleSmall: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      height: 1.43,
    ),
    bodyLarge: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.5,
      height: 1.50,
    ),
    bodyMedium: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
      height: 1.43,
    ),
    bodySmall: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
      height: 1.33,
    ),
    labelLarge: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      height: 1.43,
    ),
    labelMedium: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      height: 1.33,
    ),
    labelSmall: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      height: 1.45,
    ),
  );
}
''';

  // ─── Env files ─────────────────────────────────────────────────

  static const envDevelopment = '''
APP_NAME={{project_name.titleCase()}} Dev
APP_SUFFIX=.dev
BASE_URL=http://localhost:8080
ENCRYPTION_KEY=encry1234567890ABCDEF12GHIJK34LMNOP098QRSTUVWXYZabcdefghe567ijklmnAoOpqrstuRTDvwxyz0987654321
''';

  static const envStaging = '''
APP_NAME={{project_name.titleCase()}} Stg
APP_SUFFIX=.stg
BASE_URL=https://staging.api.example.com
ENCRYPTION_KEY=encry1234567890ABCDEF12GHIJK34LMNOP098QRSTUVWXYZabcdefghe567ijklmnAoOpqrstuRTDvwxyz0987654321
''';

  static const envProduction = '''
APP_NAME={{project_name.titleCase()}}
APP_SUFFIX=
BASE_URL=https://api.example.com
ENCRYPTION_KEY=encry1234567890ABCDEF12GHIJK34LMNOP098QRSTUVWXYZabcdefghe567ijklmnAoOpqrstuRTDvwxyz0987654321
''';

  // ─── DI setup (get_it) ─────────────────────────────────────────

  static const diSetup = '''
import 'package:env/env.dart';
import 'package:get_it/get_it.dart';
import 'package:{{project_name.snakeCase()}}/core/cache/cached_storage.dart';
import 'package:relax_storage/relax_storage.dart';

final getIt = GetIt.instance;

Future<void> setUpRegister(EnvValue env) async {
  await RelaxStorage.init();
  final cachedStorage = CachedStorage(env);

  getIt.registerSingleton<EnvValue>(env);
  getIt.registerSingleton<CachedStorage>(cachedStorage);

  // Register your repositories and services here, for example:
  // getIt.registerLazySingleton<AuthRepository>(
  //   () => AuthRepositoryImpl(env: env),
  // );
}
''';

  // ─── Flavor entry points ──────────────────────────────────────

  static const mainDevelopment = '''
import 'package:{{project_name.snakeCase()}}/app/app.dart';
import 'package:{{project_name.snakeCase()}}/bootstrap.dart';
import 'package:env/env.dart';

void main() {
  bootstrap(() => const App(), env: AppFlavor.development().getEnv);
}
''';

  static const mainStaging = '''
import 'package:{{project_name.snakeCase()}}/app/app.dart';
import 'package:{{project_name.snakeCase()}}/bootstrap.dart';
import 'package:env/env.dart';

void main() {
  bootstrap(() => const App(), env: AppFlavor.staging().getEnv);
}
''';

  static const mainProduction = '''
import 'package:{{project_name.snakeCase()}}/app/app.dart';
import 'package:{{project_name.snakeCase()}}/bootstrap.dart';
import 'package:env/env.dart';

void main() {
  bootstrap(() => const App(), env: AppFlavor.production().getEnv);
}
''';

  // ─── Bootstrap (Bloc — default) ───────────────────────────────

  static const bootstrap = '''
import 'dart:async';
import 'dart:developer';

import 'package:env/env.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/di.dart' as di;
import 'i18n/slang/translations.g.dart';

class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    log('onChange(\${bloc.runtimeType}, \$change)');
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    log('onError(\${bloc.runtimeType}, \$error, \$stackTrace)');
    super.onError(bloc, error, stackTrace);
  }
}

Future<void> bootstrap(
  Widget Function() builder, {
  required EnvValue env,
}) async {
  FlutterError.onError = (details) {
    log(details.exceptionAsString(), stackTrace: details.stack);
  };

  Bloc.observer = const AppBlocObserver();

  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    LocaleSettings.useDeviceLocale();

    await di.setUpRegister(env);

    runApp(builder());
  }, (error, stack) {
    log(error.toString(), stackTrace: stack);
  });
}
''';

  // ─── Bootstrap (Provider) ─────────────────────────────────────

  static const bootstrapProvider = '''
import 'dart:async';
import 'dart:developer';

import 'package:env/env.dart';
import 'package:flutter/material.dart';

import 'core/di/di.dart' as di;
import 'i18n/slang/translations.g.dart';

Future<void> bootstrap(
  Widget Function() builder, {
  required EnvValue env,
}) async {
  FlutterError.onError = (details) {
    log(details.exceptionAsString(), stackTrace: details.stack);
  };

  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    LocaleSettings.useDeviceLocale();

    await di.setUpRegister(env);

    runApp(builder());
  }, (error, stack) {
    log(error.toString(), stackTrace: stack);
  });
}
''';

  // ─── Bootstrap (Riverpod) ─────────────────────────────────────

  static const bootstrapRiverpod = '''
import 'dart:async';
import 'dart:developer';

import 'package:env/env.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/di/di.dart' as di;
import 'i18n/slang/translations.g.dart';

Future<void> bootstrap(
  Widget Function() builder, {
  required EnvValue env,
}) async {
  FlutterError.onError = (details) {
    log(details.exceptionAsString(), stackTrace: details.stack);
  };

  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    LocaleSettings.useDeviceLocale();

    await di.setUpRegister(env);

    runApp(ProviderScope(child: builder()));
  }, (error, stack) {
    log(error.toString(), stackTrace: stack);
  });
}
''';

  // ─── Bootstrap (GetX) ─────────────────────────────────────────

  static const bootstrapGetx = '''
import 'dart:async';
import 'dart:developer';

import 'package:env/env.dart';
import 'package:flutter/material.dart';

import 'core/di/di.dart' as di;
import 'i18n/slang/translations.g.dart';

Future<void> bootstrap(
  Widget Function() builder, {
  required EnvValue env,
}) async {
  FlutterError.onError = (details) {
    log(details.exceptionAsString(), stackTrace: details.stack);
  };

  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    LocaleSettings.useDeviceLocale();

    await di.setUpRegister(env);

    runApp(builder());
  }, (error, stack) {
    log(error.toString(), stackTrace: stack);
  });
}
''';

  // ─── VS Code launch.json ──────────────────────────────────────

  static const vscodeLaunchJson = '''
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "development",
      "request": "launch",
      "type": "dart",
      "program": "lib/main_development.dart",
      "args": ["--flavor", "development"]
    },
    {
      "name": "staging",
      "request": "launch",
      "type": "dart",
      "program": "lib/main_staging.dart",
      "args": ["--flavor", "staging"]
    },
    {
      "name": "production",
      "request": "launch",
      "type": "dart",
      "program": "lib/main_production.dart",
      "args": ["--flavor", "production"]
    }
  ]
}
''';

  // ─── Welcome view body (shared across all architectures) ───────

  static String welcomeViewBody(String archName) => '''
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 64,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      t.home.welcome,
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      t.home.subtitle,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),''';
}
