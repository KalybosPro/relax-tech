import 'package:mason/mason.dart';

/// Shared template content reused across all architecture templates.
abstract final class SharedTemplate {
  /// Prefixes a relative path with the mustache project directory.
  static String p(String path) => '{{project_name.snakeCase()}}/$path';

  /// Returns the common [TemplateFile] list shared by every architecture:
  /// the `core/` infrastructure layer, the `shared/` cross-feature layer,
  /// reserved feature placeholders, env/flavor files, i18n and tooling.
  static List<TemplateFile> coreFiles() => [
    TemplateFile(p('analysis_options.yaml'), analysisOptions),
    // ── Core barrel ─────────────────────────────────────────
    TemplateFile(p('lib/core/core.dart'), coreBarrel),
    // ── Network ─────────────────────────────────────────────
    TemplateFile(p('lib/core/network/network.dart'), networkBarrel),
    TemplateFile(p('lib/core/network/api_client.dart'), apiClient),
    // ── Database ────────────────────────────────────────────
    TemplateFile(p('lib/core/database/database.dart'), databaseBarrel),
    TemplateFile(p('lib/core/database/app_database.dart'), appDatabase),
    // ── Encryption ──────────────────────────────────────────
    TemplateFile(p('lib/core/encryption/encryption.dart'), encryptionBarrel),
    TemplateFile(p('lib/core/encryption/app_encrypter.dart'), appEncrypter),
    // ── Cache ───────────────────────────────────────────────
    TemplateFile(p('lib/core/cache/cache.dart'), cacheBarrel),
    TemplateFile(p('lib/core/cache/cached_storage.dart'), cachedStorage),
    // ── WebSocket ───────────────────────────────────────────
    TemplateFile(p('lib/core/websocket/websocket.dart'), websocketBarrel),
    TemplateFile(p('lib/core/websocket/socket_service.dart'), socketService),
    // ── UI (theme) ──────────────────────────────────────────
    TemplateFile(p('lib/core/ui/ui.dart'), uiBarrel),
    TemplateFile(p('lib/core/ui/theme/app_theme.dart'), appTheme),
    TemplateFile(p('lib/core/ui/theme/app_colors.dart'), appColors),
    TemplateFile(p('lib/core/ui/theme/app_typography.dart'), appTypography),
    // ── Utils ───────────────────────────────────────────────
    TemplateFile(p('lib/core/utils/utils.dart'), utilsBarrel),
    TemplateFile(p('lib/core/utils/validators.dart'), validators),
    TemplateFile(p('lib/core/utils/extensions.dart'), extensions),
    // ── DI ──────────────────────────────────────────────────
    TemplateFile(p('lib/core/di/di.dart'), diSetup),
    // ── Shared (cross-feature) ──────────────────────────────
    TemplateFile(p('lib/shared/shared.dart'), sharedBarrel),
    TemplateFile(p('lib/shared/widgets/widgets.dart'), widgetsBarrel),
    TemplateFile(p('lib/shared/widgets/app_loader.dart'), appLoader),
    TemplateFile(p('lib/shared/widgets/primary_button.dart'), primaryButton),
    TemplateFile(p('lib/shared/models/models.dart'), modelsBarrel),
    TemplateFile(p('lib/shared/models/result.dart'), resultModel),
    TemplateFile(p('lib/shared/services/services.dart'), servicesBarrel),
    TemplateFile(p('lib/shared/services/logger_service.dart'), loggerService),
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

This project uses **$archName** for state management, organized in three layers:
`core/` (infrastructure), `shared/` (cross-feature), and `features/` (screens),
composed together in `app/`.

```
lib/
\u251c\u2500\u2500 app/              \u2192 Composition root: MaterialApp + router + DI wiring
\u251c\u2500\u2500 core/             \u2192 Infrastructure (no feature knowledge)
\u2502   \u251c\u2500\u2500 network/      \u2192 Dio ApiClient (base URL + auth interceptor)
\u2502   \u251c\u2500\u2500 database/     \u2192 RelaxORM local-first database
\u2502   \u251c\u2500\u2500 encryption/   \u2192 AES encrypt/decrypt helper
\u2502   \u251c\u2500\u2500 cache/        \u2192 Encrypted key-value storage
\u2502   \u251c\u2500\u2500 websocket/    \u2192 Realtime socket service
\u2502   \u251c\u2500\u2500 ui/           \u2192 Theme, colors, typography
\u2502   \u251c\u2500\u2500 utils/        \u2192 Validators & extensions
\u2502   \u2514\u2500\u2500 di/           \u2192 get_it service locator
\u251c\u2500\u2500 shared/           \u2192 Reused across features
\u2502   \u251c\u2500\u2500 widgets/      \u2192 Shared widgets (AppLoader, PrimaryButton)
\u2502   \u251c\u2500\u2500 models/       \u2192 Shared models (Result<T>)
\u2502   \u2514\u2500\u2500 services/     \u2192 Shared services (LoggerService)
\u251c\u2500\u2500 i18n/             \u2192 Localization (slang)
\u2514\u2500\u2500 features/         \u2192 Feature modules
    \u2514\u2500\u2500 home/         \u2192 Working sample ($featureDir + view/)
```

> `core/` and `shared/` are reached through the `core/core.dart` and
> `shared/shared.dart` barrels, so imports stay stable if the internals move.
> Add new features with `relax generate feature <name>`.

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

  /// Single import for the whole infrastructure layer. Views and features
  /// reach theme, DI, storage, networking, etc. through `core/core.dart`, so
  /// the internal folder layout can change without touching feature code.
  static const coreBarrel = '''
export 'cache/cache.dart';
export 'database/database.dart';
export 'di/di.dart';
export 'encryption/encryption.dart';
export 'network/network.dart';
export 'ui/ui.dart';
export 'utils/utils.dart';
export 'websocket/websocket.dart';
export '../i18n/slang/translations.g.dart';
''';

  // ─── Network ───────────────────────────────────────────────────

  static const networkBarrel = "export 'api_client.dart';\n";

  static const apiClient = '''
import 'package:dio/dio.dart';
import 'package:env/env.dart';

import '../cache/cached_storage.dart';

/// Thin wrapper around [Dio] configured from the active flavor.
///
/// The base URL is read from `Env.baseUrl`, and a request interceptor attaches
/// the bearer token persisted by [CachedStorage] (when present). Inject it via
/// `getIt<ApiClient>()` and call the verb helpers, e.g.:
///
/// ```dart
/// final res = await getIt<ApiClient>().get<Map<String, dynamic>>('/me');
/// ```
class ApiClient {
  ApiClient({required EnvValue env, required CachedStorage storage})
      : _storage = storage,
        dio = Dio(
          BaseOptions(
            baseUrl: env(Env.baseUrl),
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
          ),
        ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _storage.token;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer \$token';
          }
          handler.next(options);
        },
      ),
    );
  }

  /// The underlying Dio instance — use it directly for advanced needs.
  final Dio dio;

  final CachedStorage _storage;

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? query}) =>
      dio.get<T>(path, queryParameters: query);

  Future<Response<T>> post<T>(String path, {Object? data}) =>
      dio.post<T>(path, data: data);

  Future<Response<T>> put<T>(String path, {Object? data}) =>
      dio.put<T>(path, data: data);

  Future<Response<T>> delete<T>(String path, {Object? data}) =>
      dio.delete<T>(path, data: data);
}
''';

  // ─── Database (RelaxORM) ───────────────────────────────────────

  static const databaseBarrel = "export 'app_database.dart';\n";

  static const appDatabase = '''
import 'package:relax_orm/relax_orm.dart';

/// Local-first database backed by [RelaxORM].
///
/// Opens (or creates) an encrypted SQLite database. Register generated
/// `TableSchema`s (produced by `relax generate model`) in [_schemas], then
/// read/write through typed collections:
///
/// ```dart
/// final db = await getIt.getAsync<AppDatabase>();
/// final users = db.raw.collection<User>();
/// await users.add(user);
/// ```
class AppDatabase {
  AppDatabase._(this.raw);

  /// The underlying [RelaxDB] handle.
  final RelaxDB raw;

  /// Schemas registered with the database. Add generated schemas here, e.g.
  /// `[userSchema, postSchema]`.
  static const List<TableSchema> _schemas = <TableSchema>[];

  /// Opens the database using the flavor's encryption key.
  static Future<AppDatabase> open(String encryptionKey) async {
    final db = await RelaxDB.open(
      name: 'app',
      schemas: _schemas,
      encryptionKey: encryptionKey,
    );
    return AppDatabase._(db);
  }
}
''';

  // ─── Encryption ────────────────────────────────────────────────

  static const encryptionBarrel = "export 'app_encrypter.dart';\n";

  static const appEncrypter = '''
import 'package:relax_storage/relax_storage.dart';

/// AES-CBC encrypt/decrypt helper reusing the flavor's `ENCRYPTION_KEY`.
///
/// Wraps the [Encrypter] from `relax_storage` so the rest of the app depends
/// on a small, stable surface instead of the crypto package directly.
///
/// ```dart
/// final enc = getIt<AppEncrypter>();
/// final payload = enc.encrypt('secret');
/// final clear = enc.decrypt(payload);
/// ```
class AppEncrypter {
  AppEncrypter(this._key) : _encrypter = Encrypter();

  final String _key;
  final IEncrypter _encrypter;

  /// Returns `"IV_BASE64:CIPHER_BASE64"` for [data].
  String encrypt(String data) => _encrypter.encrypt<String>(data, _key);

  /// Reverses [encrypt] for a `"IV_BASE64:CIPHER_BASE64"` [payload].
  String decrypt(String payload) => _encrypter.decrypt(payload, _key);
}
''';

  // ─── Cache barrel ──────────────────────────────────────────────

  static const cacheBarrel = "export 'cached_storage.dart';\n";

  // ─── WebSocket ─────────────────────────────────────────────────

  static const websocketBarrel = "export 'socket_service.dart';\n";

  static const socketService = '''
import 'package:web_socket_channel/web_socket_channel.dart';

/// Lightweight realtime channel over [WebSocketChannel].
///
/// Connect, listen to [stream], [send] messages and [disconnect]. A single
/// instance is registered in DI; open one connection per app session:
///
/// ```dart
/// final socket = getIt<SocketService>()
///   ..connect(Uri.parse('wss://example.com/ws'));
/// socket.stream.listen(print);
/// socket.send('ping');
/// ```
class SocketService {
  WebSocketChannel? _channel;

  /// Whether a channel is currently open.
  bool get isConnected => _channel != null;

  /// Incoming messages from the server.
  Stream<dynamic> get stream =>
      _channel?.stream ?? const Stream<dynamic>.empty();

  /// Opens a connection to [url] (e.g. `wss://...`).
  void connect(Uri url) => _channel ??= WebSocketChannel.connect(url);

  /// Sends [message] to the server. No-op when disconnected.
  void send(Object? message) => _channel?.sink.add(message);

  /// Closes the connection.
  Future<void> disconnect() async {
    await _channel?.sink.close();
    _channel = null;
  }
}
''';

  // ─── UI barrel ─────────────────────────────────────────────────

  static const uiBarrel = '''
export 'theme/app_colors.dart';
export 'theme/app_theme.dart';
export 'theme/app_typography.dart';
''';

  // ─── Utils ─────────────────────────────────────────────────────

  static const utilsBarrel = '''
export 'extensions.dart';
export 'validators.dart';
''';

  static const validators = '''
/// Reusable, framework-agnostic form validators.
///
/// Each returns `null` when the input is valid, or an error message otherwise —
/// the shape expected by [FormFieldValidator].
abstract final class Validators {
  static final _emailRegExp = RegExp(r'^[\\w.+-]+@[\\w-]+\\.[\\w.-]+\$');

  /// Requires a non-empty, well-formed email address.
  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Email is required';
    if (!_emailRegExp.hasMatch(v)) return 'Enter a valid email';
    return null;
  }

  /// Requires a non-empty value. Pass [field] to name it in the message.
  static String? notEmpty(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '\$field is required';
    return null;
  }

  /// Requires at least [length] characters.
  static String? minLength(String? value, int length) {
    if ((value ?? '').length < length) {
      return 'Must be at least \$length characters';
    }
    return null;
  }
}
''';

  static const extensions = '''
import 'package:flutter/material.dart';

/// Ergonomic shortcuts on [BuildContext].
extension BuildContextX on BuildContext {
  /// The active [ThemeData].
  ThemeData get theme => Theme.of(this);

  /// The active [TextTheme].
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// The active [ColorScheme].
  ColorScheme get colors => Theme.of(this).colorScheme;

  /// The [MediaQueryData.size] of the current view.
  Size get screenSize => MediaQuery.sizeOf(this);
}

/// Small [String] helpers.
extension StringX on String {
  /// Uppercases the first character, leaving the rest untouched.
  String get capitalized =>
      isEmpty ? this : '\${this[0].toUpperCase()}\${substring(1)}';

  /// Whether the string is a syntactically valid email.
  bool get isEmail =>
      RegExp(r'^[\\w.+-]+@[\\w-]+\\.[\\w.-]+\$').hasMatch(trim());
}
''';

  // ─── Shared (cross-feature) layer ──────────────────────────────

  /// Single import for the cross-feature layer: widgets, models and services
  /// reused by more than one feature but not part of core infrastructure.
  static const sharedBarrel = '''
export 'models/models.dart';
export 'services/services.dart';
export 'widgets/widgets.dart';
''';

  static const widgetsBarrel = '''
export 'app_loader.dart';
export 'primary_button.dart';
''';

  static const appLoader = '''
import 'package:flutter/material.dart';

/// Centered, theme-aware progress indicator used across features.
class AppLoader extends StatelessWidget {
  const AppLoader({super.key, this.size = 28});

  /// Diameter of the spinner.
  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox.square(
        dimension: size,
        child: const CircularProgressIndicator(strokeWidth: 3),
      ),
    );
  }
}
''';

  static const primaryButton = '''
import 'package:flutter/material.dart';

/// Full-width primary action button with a built-in loading state.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    super.key,
    this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(label),
      ),
    );
  }
}
''';

  static const modelsBarrel = "export 'result.dart';\n";

  static const resultModel = '''
/// A minimal success/failure wrapper for operations that can fail without
/// throwing — handy for repository and service return types.
///
/// ```dart
/// final result = await repo.login(email, password);
/// switch (result) {
///   case Success(:final value):
///     // use value
///   case Failure(:final error):
///     // show error
/// }
/// ```
sealed class Result<T> {
  const Result();

  const factory Result.success(T value) = Success<T>;
  const factory Result.failure(Object error) = Failure<T>;

  /// Whether this is a [Success].
  bool get isSuccess => this is Success<T>;
}

final class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;
}

final class Failure<T> extends Result<T> {
  const Failure(this.error);
  final Object error;
}
''';

  static const servicesBarrel = "export 'logger_service.dart';\n";

  static const loggerService = '''
import 'dart:developer' as developer;

/// Dependency-free logging facade over `dart:developer`.
///
/// Registered in DI so features log through a single seam that can later be
/// swapped for Crashlytics, Sentry, etc. without touching call sites.
class LoggerService {
  const LoggerService({this.name = 'app'});

  /// Logical channel name shown alongside each entry.
  final String name;

  void info(String message) => developer.log(message, name: name);

  void error(String message, [Object? error, StackTrace? stackTrace]) =>
      developer.log(
        message,
        name: name,
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
}
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
import 'package:relax_storage/relax_storage.dart';
import 'package:{{project_name.snakeCase()}}/core/cache/cached_storage.dart';
import 'package:{{project_name.snakeCase()}}/core/database/app_database.dart';
import 'package:{{project_name.snakeCase()}}/core/encryption/app_encrypter.dart';
import 'package:{{project_name.snakeCase()}}/core/network/api_client.dart';
import 'package:{{project_name.snakeCase()}}/core/websocket/socket_service.dart';
import 'package:{{project_name.snakeCase()}}/shared/services/logger_service.dart';

final getIt = GetIt.instance;

/// Wires the core infrastructure into the service locator.
///
/// Called once from `bootstrap` before `runApp`. The database is registered
/// lazily (`getAsync`) so it only opens the first time it is requested.
Future<void> setUpRegister(EnvValue env) async {
  await RelaxStorage.init();

  final cachedStorage = CachedStorage(env);
  final encryptionKey = env(Env.encryptionKey);

  getIt
    ..registerSingleton<EnvValue>(env)
    ..registerSingleton<CachedStorage>(cachedStorage)
    ..registerSingleton<AppEncrypter>(AppEncrypter(encryptionKey))
    ..registerLazySingleton<LoggerService>(LoggerService.new)
    ..registerLazySingleton<SocketService>(SocketService.new)
    ..registerLazySingleton<ApiClient>(
      () => ApiClient(env: env, storage: cachedStorage),
    )
    ..registerLazySingletonAsync<AppDatabase>(
      () => AppDatabase.open(encryptionKey),
    );

  // Register your repositories and services here, for example:
  // getIt.registerLazySingleton<AuthRepository>(
  //   () => AuthRepositoryImpl(api: getIt<ApiClient>()),
  // );
}
''';

  // ─── Features barrel ───────────────────────────────────────────

  /// Aggregate barrel re-exporting every feature. This is the single import
  /// the router (and anything else) uses to reach feature pages. The
  /// `relax:features` anchor is the insertion point for `relax generate
  /// feature`; do not remove it.
  static const featuresBarrel = '''
export 'home/home.dart';
// relax:features
''';

  // ─── Router (go_router) ────────────────────────────────────────

  /// App-level router. Lives in the composition root (`lib/app/`), so it is
  /// allowed to depend on features — the Clean Architecture dependency rule
  /// points inward, and features never depend on this file.
  ///
  /// Feature pages are reached through the aggregate `features/features.dart`
  /// barrel. The `relax:router-routes` anchor is the insertion point for
  /// `relax generate feature`; do not remove it.
  static const appRouter = '''
import 'package:go_router/go_router.dart';

import '../../features/features.dart';

/// The application router.
///
/// Each feature owns its own [HomePage.routeName] / [HomePage.routePath]; this
/// file only aggregates them into a single [GoRouter].
final appRouter = GoRouter(
  initialLocation: HomePage.routePath,
  routes: [
    GoRoute(
      path: HomePage.routePath,
      name: HomePage.routeName,
      builder: (context, state) => const HomePage(),
      routes: [
        // relax:routes-home
      ],
    ),
    // relax:router-routes
  ],
);
''';

  /// GetX variant of the app router: a list of [GetPage] entries. Each feature
  /// carries its own binding, so navigation is `Get.toNamed(<Page>.routePath)`.
  ///
  /// Uses the same `relax:router-routes` anchor as the go_router variant so the
  /// generator can insert into either file uniformly.
  static const appPagesGetx = '''
import 'package:get/get.dart';

import '../../features/features.dart';

/// The application routes (GetX).
final appPages = <GetPage<dynamic>>[
  GetPage(
    name: HomePage.routePath,
    page: () => const HomePage(),
    binding: HomeBinding(),
  ),
  // relax:router-routes
];
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
