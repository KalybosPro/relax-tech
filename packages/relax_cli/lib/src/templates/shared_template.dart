import 'package:mason/mason.dart';

/// Shared template content reused across all architecture templates.
///
/// The generated app follows a Clean Architecture layout:
///
/// * `core/`     — infrastructure with no feature knowledge (network, database,
///                 storage, services, routing, theme, ui, errors, …).
/// * `features/` — vertical slices, each split into `data / domain /
///                 presentation` (+ optional `services`).
/// * `app/`      — the root widget that wires `core` routing + theme together.
abstract final class SharedTemplate {
  /// Prefixes a relative path with the mustache project directory.
  static String p(String path) => '{{project_name.snakeCase()}}/$path';

  /// Returns the common [TemplateFile] list shared by every architecture: the
  /// full `core/` infrastructure layer, env/flavor files, i18n and tooling.
  static List<TemplateFile> coreFiles() => [
    TemplateFile(p('analysis_options.yaml'), analysisOptions),
    // ── Core barrel ─────────────────────────────────────────
    TemplateFile(p('lib/core/core.dart'), coreBarrel),
    // ── Config ──────────────────────────────────────────────
    TemplateFile(p('lib/core/config/config.dart'), configBarrel),
    TemplateFile(p('lib/core/config/app_config.dart'), appConfig),
    TemplateFile(
      p('lib/core/config/constants/app_constants.dart'),
      appConstants,
    ),
    TemplateFile(p('lib/core/config/flavors/flavor.dart'), flavor),
    // ── Network ─────────────────────────────────────────────
    TemplateFile(p('lib/core/network/network.dart'), networkBarrel),
    TemplateFile(p('lib/core/network/dio_client.dart'), dioClient),
    TemplateFile(p('lib/core/network/api_client.dart'), apiClient),
    TemplateFile(p('lib/core/network/api_response.dart'), apiResponse),
    TemplateFile(p('lib/core/network/network_info.dart'), networkInfo),
    TemplateFile(
      p('lib/core/network/interceptors/auth_interceptor.dart'),
      authInterceptor,
    ),
    TemplateFile(
      p('lib/core/network/interceptors/logging_interceptor.dart'),
      loggingInterceptor,
    ),
    TemplateFile(
      p('lib/core/network/interceptors/retry_interceptor.dart'),
      retryInterceptor,
    ),
    // ── Database ────────────────────────────────────────────
    TemplateFile(p('lib/core/database/database.dart'), databaseBarrel),
    TemplateFile(p('lib/core/database/app_database.dart'), appDatabase),
    // ── WebSocket ───────────────────────────────────────────
    TemplateFile(p('lib/core/websocket/websocket.dart'), websocketBarrel),
    TemplateFile(p('lib/core/websocket/socket_client.dart'), socketClient),
    TemplateFile(p('lib/core/websocket/socket_service.dart'), socketService),
    // ── Cache ───────────────────────────────────────────────
    TemplateFile(p('lib/core/cache/cache.dart'), cacheBarrel),
    TemplateFile(p('lib/core/cache/cached_storage.dart'), cachedStorage),
    TemplateFile(p('lib/core/cache/memory_cache.dart'), memoryCache),
    // ── Encryption ──────────────────────────────────────────
    TemplateFile(p('lib/core/encryption/encryption.dart'), encryptionBarrel),
    TemplateFile(p('lib/core/encryption/app_encrypter.dart'), appEncrypter),
    // ── Storage ─────────────────────────────────────────────
    TemplateFile(p('lib/core/storage/storage.dart'), storageBarrel),
    TemplateFile(p('lib/core/storage/secure_storage.dart'), secureStorage),
    TemplateFile(p('lib/core/storage/preferences.dart'), preferences),
    TemplateFile(p('lib/core/storage/file_storage.dart'), fileStorage),
    // ── Services ────────────────────────────────────────────
    TemplateFile(p('lib/core/services/services.dart'), servicesBarrel),
    TemplateFile(
      p('lib/core/services/connectivity_service.dart'),
      connectivityService,
    ),
    TemplateFile(
      p('lib/core/services/notification_service.dart'),
      notificationService,
    ),
    TemplateFile(
      p('lib/core/services/permission_service.dart'),
      permissionService,
    ),
    TemplateFile(p('lib/core/services/upload_service.dart'), uploadService),
    TemplateFile(p('lib/core/services/download_service.dart'), downloadService),
    TemplateFile(
      p('lib/core/services/analytics_service.dart'),
      analyticsService,
    ),
    // ── Routing ─────────────────────────────────────────────
    // (app_router.dart / app_pages.dart are provided per architecture)
    TemplateFile(p('lib/core/routing/routing.dart'), routingBarrel),
    TemplateFile(p('lib/core/routing/routes.dart'), routes),
    TemplateFile(p('lib/core/routing/guards.dart'), guards),
    // ── Localization ────────────────────────────────────────
    TemplateFile(
      p('lib/core/localization/localization.dart'),
      localizationBarrel,
    ),
    // ── Theme ───────────────────────────────────────────────
    TemplateFile(p('lib/core/theme/theme.dart'), themeBarrel),
    TemplateFile(p('lib/core/theme/app_colors.dart'), appColors),
    TemplateFile(p('lib/core/theme/app_typography.dart'), appTypography),
    TemplateFile(p('lib/core/theme/app_theme.dart'), appTheme),
    TemplateFile(p('lib/core/theme/spacing.dart'), spacing),
    TemplateFile(p('lib/core/theme/radius.dart'), radius),
    // ── UI (generic widgets) ────────────────────────────────
    TemplateFile(p('lib/core/ui/ui.dart'), uiBarrel),
    TemplateFile(p('lib/core/ui/widgets/loading.dart'), loadingWidget),
    TemplateFile(p('lib/core/ui/widgets/error_view.dart'), errorView),
    TemplateFile(p('lib/core/ui/widgets/primary_button.dart'), primaryButton),
    TemplateFile(p('lib/core/ui/widgets/app_avatar.dart'), appAvatar),
    TemplateFile(p('lib/core/ui/widgets/app_card.dart'), appCard),
    // ── Errors ──────────────────────────────────────────────
    TemplateFile(p('lib/core/errors/errors.dart'), errorsBarrel),
    TemplateFile(p('lib/core/errors/failures.dart'), failures),
    TemplateFile(p('lib/core/errors/exceptions.dart'), exceptions),
    TemplateFile(p('lib/core/errors/error_mapper.dart'), errorMapper),
    TemplateFile(p('lib/core/errors/result.dart'), resultType),
    // ── Extensions ──────────────────────────────────────────
    TemplateFile(p('lib/core/extensions/extensions.dart'), extensionsBarrel),
    TemplateFile(
      p('lib/core/extensions/context_extensions.dart'),
      contextExtensions,
    ),
    TemplateFile(
      p('lib/core/extensions/string_extensions.dart'),
      stringExtensions,
    ),
    TemplateFile(p('lib/core/extensions/date_extensions.dart'), dateExtensions),
    // ── Mixins ──────────────────────────────────────────────
    TemplateFile(p('lib/core/mixins/mixins.dart'), mixinsBarrel),
    TemplateFile(p('lib/core/mixins/validation_mixin.dart'), validationMixin),
    // ── Utils ───────────────────────────────────────────────
    TemplateFile(p('lib/core/utils/utils.dart'), utilsBarrel),
    TemplateFile(p('lib/core/utils/validators.dart'), validators),
    TemplateFile(p('lib/core/utils/logger.dart'), logger),
    TemplateFile(p('lib/core/utils/debouncer.dart'), debouncer),
    TemplateFile(p('lib/core/utils/formatter.dart'), formatter),
    // ── Dependency injection ────────────────────────────────
    TemplateFile(
      p('lib/core/dependency_injection/dependency_injection.dart'),
      diBarrel,
    ),
    TemplateFile(p('lib/core/dependency_injection/injection.dart'), diSetup),
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

This project uses **$archName** for state management, organized as a Clean
Architecture: infrastructure lives in `core/`, each feature is a vertical slice
split into `data / domain / presentation`, and `app/` wires them together.

```
lib/
├── app/                 → Root widget (MaterialApp wired to core routing + theme)
├── core/                → Infrastructure shared by every feature
│   ├── config/          → App config, constants, flavors
│   ├── network/         → Dio client, ApiClient, interceptors
│   ├── database/        → RelaxORM local-first database
│   ├── websocket/       → Realtime socket client + service
│   ├── cache/           → Encrypted storage + in-memory cache
│   ├── encryption/      → AES encrypt/decrypt helper
│   ├── storage/         → Secure storage, preferences, files
│   ├── services/        → Connectivity, notifications, permissions, up/download
│   ├── routing/         → App router, routes, guards
│   ├── localization/    → slang re-export
│   ├── theme/           → Colors, typography, theme, spacing, radius
│   ├── ui/              → Generic widgets (loading, error, button, avatar, card)
│   ├── errors/          → Failures, exceptions, error mapper, Result
│   ├── extensions/      → BuildContext / String / DateTime helpers
│   ├── mixins/          → Reusable mixins
│   ├── utils/           → Validators, logger, debouncer, formatter
│   └── dependency_injection/ → get_it service locator
├── i18n/                → Localization (slang)
└── features/
    └── home/            → Sample vertical slice
        ├── data/        → datasources, models, repositories, mappers
        ├── domain/      → entities, repositories, usecases, failures
        ├── presentation/→ pages, widgets, $featureDir, states
        └── routes.dart
```

> The router lives in `core/routing/`, not `app/`. `core/` is reached through the
> `core/core.dart` barrel, so imports stay stable if the internals move.
> Add new features with `relax generate feature <name>` — it scaffolds the full
> `data / domain / presentation` slice and wires the route.

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
# Add a new feature (full data/domain/presentation slice)
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

  /// Single import for the whole infrastructure layer. Features reach network,
  /// storage, theme, DI, errors, etc. through `core/core.dart`, so the internal
  /// folder layout can change without touching feature code.
  static const coreBarrel = '''
export 'config/config.dart';
export 'network/network.dart';
export 'database/database.dart';
export 'websocket/websocket.dart';
export 'cache/cache.dart';
export 'encryption/encryption.dart';
export 'storage/storage.dart';
export 'services/services.dart';
export 'routing/routing.dart';
export 'localization/localization.dart';
export 'theme/theme.dart';
export 'ui/ui.dart';
export 'errors/errors.dart';
export 'extensions/extensions.dart';
export 'mixins/mixins.dart';
export 'utils/utils.dart';
export 'dependency_injection/dependency_injection.dart';
''';

  // ─── Config ────────────────────────────────────────────────────

  static const configBarrel = '''
export 'app_config.dart';
export 'constants/app_constants.dart';
export 'flavors/flavor.dart';
''';

  static const appConfig = '''
import 'package:env/env.dart';

/// Typed access to the active flavor's environment values.
///
/// Wraps the raw [EnvValue] callback so the rest of the app reads configuration
/// through named getters instead of `env(Env.someKey)` everywhere.
class AppConfig {
  const AppConfig(this._env);

  final EnvValue _env;

  String get appName => _env(Env.appName);
  String get baseUrl => _env(Env.baseUrl);
  String get encryptionKey => _env(Env.encryptionKey);
}
''';

  static const appConstants = '''
/// App-wide constant values that never change at runtime.
abstract final class AppConstants {
  /// Storage key for the persisted authentication token.
  static const tokenKey = 'TOKENDATASTORAGEKEY';

  /// Default page size for paginated endpoints.
  static const pageSize = 20;

  /// Default network timeout.
  static const requestTimeout = Duration(seconds: 15);
}
''';

  static const flavor = '''
/// The build environment the app is currently running in.
///
/// Mirrors the `--flavor` passed to `flutter run`. Named [AppEnvironment] (not
/// `Flavor`) to avoid clashing with the `Flavor` type exported by `package:env`.
/// The active value is set by the matching `lib/main_<flavor>.dart` entry point.
enum AppEnvironment {
  development,
  staging,
  production;

  bool get isProduction => this == AppEnvironment.production;
}

/// Holds the environment selected at startup.
abstract final class FlavorConfig {
  static AppEnvironment current = AppEnvironment.development;
}
''';

  // ─── Network ───────────────────────────────────────────────────

  static const networkBarrel = '''
export 'api_client.dart';
export 'api_response.dart';
export 'dio_client.dart';
export 'network_info.dart';
''';

  static const dioClient = '''
import 'package:dio/dio.dart';
import 'package:env/env.dart';

import '../cache/cached_storage.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import 'interceptors/retry_interceptor.dart';

/// Builds a fully configured [Dio] instance for the active flavor.
///
/// The base URL is read from `Env.baseUrl` and the standard interceptors
/// (auth, logging, retry) are attached in order.
abstract final class DioClient {
  static Dio create({required EnvValue env, required CachedStorage storage}) {
    final dio = Dio(
      BaseOptions(
        baseUrl: env(Env.baseUrl),
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );

    dio.interceptors.addAll([
      AuthInterceptor(storage),
      RetryInterceptor(dio),
      LoggingInterceptor(),
    ]);

    return dio;
  }
}
''';

  static const apiClient = '''
import 'package:dio/dio.dart';
import 'package:env/env.dart';

import '../cache/cached_storage.dart';
import 'dio_client.dart';

/// Thin, typed wrapper around [Dio] used by feature datasources.
///
/// Inject it via `getIt<ApiClient>()` and call the verb helpers, e.g.:
///
/// ```dart
/// final res = await getIt<ApiClient>().get<Map<String, dynamic>>('/me');
/// ```
class ApiClient {
  ApiClient({required EnvValue env, required CachedStorage storage})
      : dio = DioClient.create(env: env, storage: storage);

  /// The underlying Dio instance — use it directly for advanced needs.
  final Dio dio;

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

  static const apiResponse = '''
/// A minimal envelope describing a typed API response.
///
/// Datasources can wrap raw payloads in this to carry the HTTP status alongside
/// the decoded body.
class ApiResponse<T> {
  const ApiResponse({required this.data, required this.statusCode});

  final T data;
  final int statusCode;

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}
''';

  static const networkInfo = '''
import '../services/connectivity_service.dart';

/// Abstraction over "is the device online?" so repositories can decide between
/// remote and local datasources without depending on a connectivity package.
class NetworkInfo {
  const NetworkInfo(this._connectivity);

  final ConnectivityService _connectivity;

  Future<bool> get isConnected => _connectivity.isConnected;
}
''';

  static const authInterceptor = '''
import 'package:dio/dio.dart';

import '../../cache/cached_storage.dart';

/// Attaches the persisted bearer token to every outgoing request.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage);

  final CachedStorage _storage;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    final token = _storage.token;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer \$token';
    }
    handler.next(options);
  }
}
''';

  static const loggingInterceptor = '''
import 'dart:developer' as developer;

import 'package:dio/dio.dart';

/// Logs requests, responses and errors through `dart:developer`.
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    developer.log('--> \${options.method} \${options.uri}', name: 'network');
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    developer.log(
      '<-- \${response.statusCode} \${response.requestOptions.uri}',
      name: 'network',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    developer.log(
      'xxx \${err.requestOptions.uri}',
      name: 'network',
      error: err,
    );
    handler.next(err);
  }
}
''';

  static const retryInterceptor = '''
import 'package:dio/dio.dart';

/// Retries idempotent requests once on connection/timeout errors.
class RetryInterceptor extends Interceptor {
  RetryInterceptor(this._dio, {this.retries = 1});

  final Dio _dio;
  final int retries;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final attempt = (err.requestOptions.extra['retry_attempt'] as int?) ?? 0;
    final canRetry = attempt < retries &&
        (err.type == DioExceptionType.connectionTimeout ||
            err.type == DioExceptionType.receiveTimeout ||
            err.type == DioExceptionType.connectionError);

    if (!canRetry) {
      handler.next(err);
      return;
    }

    err.requestOptions.extra['retry_attempt'] = attempt + 1;
    try {
      final response = await _dio.fetch<dynamic>(err.requestOptions);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }
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

  // ─── WebSocket ─────────────────────────────────────────────────

  static const websocketBarrel = '''
export 'socket_client.dart';
export 'socket_service.dart';
''';

  static const socketClient = '''
import 'package:web_socket_channel/web_socket_channel.dart';

/// Low-level wrapper around a single [WebSocketChannel].
///
/// [SocketService] builds on top of this; most app code should depend on the
/// service, not this client.
class SocketClient {
  WebSocketChannel? _channel;

  bool get isConnected => _channel != null;

  Stream<dynamic> get stream =>
      _channel?.stream ?? const Stream<dynamic>.empty();

  void connect(Uri url) => _channel ??= WebSocketChannel.connect(url);

  void send(Object? message) => _channel?.sink.add(message);

  Future<void> close() async {
    await _channel?.sink.close();
    _channel = null;
  }
}
''';

  static const socketService = '''
import 'socket_client.dart';

/// App-facing realtime channel. Every feature that needs realtime data goes
/// through this service rather than opening its own socket.
///
/// ```dart
/// final socket = getIt<SocketService>()
///   ..connect(Uri.parse('wss://example.com/ws'));
/// socket.messages.listen(print);
/// socket.send('ping');
/// ```
class SocketService {
  SocketService([SocketClient? client]) : _client = client ?? SocketClient();

  final SocketClient _client;

  bool get isConnected => _client.isConnected;

  /// Incoming messages from the server.
  Stream<dynamic> get messages => _client.stream;

  /// Opens a connection to [url] (e.g. `wss://...`).
  void connect(Uri url) => _client.connect(url);

  /// Sends [message] to the server. No-op when disconnected.
  void send(Object? message) => _client.send(message);

  /// Closes the connection.
  Future<void> disconnect() => _client.close();
}
''';

  // ─── Cache ─────────────────────────────────────────────────────

  static const cacheBarrel = '''
export 'cached_storage.dart';
export 'memory_cache.dart';
''';

  static const cachedStorage = '''
import 'package:env/env.dart';
import 'package:relax_storage/relax_storage.dart';

import '../config/constants/app_constants.dart';

/// Small abstraction around local secure storage used by the app.
///
/// `CachedStorage` centralizes read/write access to cached values so the rest
/// of the codebase does not depend directly on the storage package. It is
/// currently used to persist the authentication token in encrypted storage.
///
/// ```dart
/// final storage = getIt<CachedStorage>();
/// await storage.setToken('eyJhbGciOiJIUzI1NiIs');
/// final token = storage.token;
/// ```
class CachedStorage {
  CachedStorage(EnvValue env) : box = RelaxStorage(env(Env.encryptionKey));

  final RelaxStorage box;

  Future<void> setToken(String token) =>
      box.save<String>(AppConstants.tokenKey, token);

  String? get token => box.read<String>(AppConstants.tokenKey);
}
''';

  static const memoryCache = '''
/// A tiny in-memory key/value cache with optional per-entry expiry.
///
/// Useful for short-lived data (e.g. an avatar, a decoded profile) so repeated
/// reads within a session avoid re-fetching.
///
/// ```dart
/// final cache = getIt<MemoryCache>();
/// cache.put('user_12', user, ttl: const Duration(minutes: 5));
/// final user = cache.get<User>('user_12');
/// ```
class MemoryCache {
  final Map<String, _Entry> _store = {};

  void put<T>(String key, T value, {Duration? ttl}) {
    _store[key] = _Entry(
      value,
      ttl == null ? null : DateTime.now().add(ttl),
    );
  }

  T? get<T>(String key) {
    final entry = _store[key];
    if (entry == null) return null;
    if (entry.isExpired) {
      _store.remove(key);
      return null;
    }
    return entry.value as T;
  }

  void remove(String key) => _store.remove(key);

  void clear() => _store.clear();
}

class _Entry {
  _Entry(this.value, this.expiresAt);

  final Object? value;
  final DateTime? expiresAt;

  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);
}
''';

  // ─── Encryption ────────────────────────────────────────────────

  static const encryptionBarrel = "export 'app_encrypter.dart';\n";

  static const appEncrypter = '''
import 'package:relax_storage/relax_storage.dart';

/// AES-CBC encrypt/decrypt helper reusing the flavor's `ENCRYPTION_KEY`.
///
/// Wraps the [Encrypter] from `relax_storage` so the rest of the app depends on
/// a small, stable surface instead of the crypto package directly.
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

  // ─── Storage ───────────────────────────────────────────────────

  static const storageBarrel = '''
export 'file_storage.dart';
export 'preferences.dart';
export 'secure_storage.dart';
''';

  static const secureStorage = '''
import 'package:env/env.dart';
import 'package:relax_storage/relax_storage.dart';

/// Encrypted key/value storage for sensitive values (tokens, keys, secrets).
///
/// Backed by `relax_storage` (AES-CBC). For non-sensitive settings prefer
/// [Preferences].
class SecureStorage {
  SecureStorage(EnvValue env) : _box = RelaxStorage(env(Env.encryptionKey));

  final RelaxStorage _box;

  Future<void> write(String key, String value) =>
      _box.save<String>(key, value);

  String? read(String key) => _box.read<String>(key);

  Future<void> delete(String key) => _box.delete(key);
}
''';

  static const preferences = '''
import 'package:relax_storage/relax_storage.dart';

/// Lightweight app preferences (theme mode, onboarding seen, …).
///
/// Backed by the same storage engine as the rest of the app. Values are not
/// meant to be secret — use [SecureStorage] for those.
class Preferences {
  Preferences(this._box);

  final RelaxStorage _box;

  bool getBool(String key, {bool defaultValue = false}) =>
      _box.read<bool>(key) ?? defaultValue;

  Future<void> setBool(String key, {required bool value}) =>
      _box.save<bool>(key, value);

  String? getString(String key) => _box.read<String>(key);

  Future<void> setString(String key, String value) =>
      _box.save<String>(key, value);
}
''';

  static const fileStorage = '''
import 'dart:io';

/// Reads and writes app files on disk.
///
/// Note: pass an absolute [directory] (e.g. from `path_provider`'s
/// `getApplicationDocumentsDirectory()`), which you can add when you need it.
class FileStorage {
  const FileStorage(this.directory);

  /// Base directory used to resolve relative file names.
  final Directory directory;

  File _fileFor(String name) => File('\${directory.path}/\$name');

  Future<File> writeString(String name, String contents) =>
      _fileFor(name).writeAsString(contents);

  Future<String?> readString(String name) async {
    final file = _fileFor(name);
    if (!file.existsSync()) return null;
    return file.readAsString();
  }

  Future<void> delete(String name) async {
    final file = _fileFor(name);
    if (file.existsSync()) await file.delete();
  }
}
''';

  // ─── Services ──────────────────────────────────────────────────

  static const servicesBarrel = '''
export 'analytics_service.dart';
export 'connectivity_service.dart';
export 'download_service.dart';
export 'notification_service.dart';
export 'permission_service.dart';
export 'upload_service.dart';
''';

  static const connectivityService = '''
/// Reports whether the device currently has network access.
///
/// The default implementation optimistically returns `true`. Wire it to a real
/// package (e.g. `connectivity_plus`) by replacing [isConnected] / [onChange].
class ConnectivityService {
  const ConnectivityService();

  /// Whether the device is currently online.
  Future<bool> get isConnected async => true;

  /// Emits connectivity changes. Replace with a real stream when wiring a
  /// connectivity package.
  Stream<bool> get onChange => const Stream<bool>.empty();
}
''';

  static const notificationService = '''
/// Local/push notification facade.
///
/// The default implementation is a no-op so the app compiles out of the box.
/// Wire it to `flutter_local_notifications` / FCM by implementing the methods.
class NotificationService {
  const NotificationService();

  Future<void> init() async {}

  Future<void> show({required String title, required String body}) async {}

  Future<void> cancelAll() async {}
}
''';

  static const permissionService = '''
/// Runtime permission facade (camera, storage, notifications, …).
///
/// The default implementation grants everything so the app compiles out of the
/// box. Wire it to `permission_handler` when you need real prompts.
enum AppPermission { camera, microphone, storage, notifications }

class PermissionService {
  const PermissionService();

  Future<bool> request(AppPermission permission) async => true;

  Future<bool> isGranted(AppPermission permission) async => true;
}
''';

  static const uploadService = '''
import 'package:dio/dio.dart';

import '../network/api_client.dart';

/// Uploads files to the backend through the shared [ApiClient].
class UploadService {
  const UploadService(this._api);

  final ApiClient _api;

  Future<Response<dynamic>> uploadFile(
    String path, {
    required String filePath,
    String field = 'file',
  }) async {
    final form = FormData.fromMap({
      field: await MultipartFile.fromFile(filePath),
    });
    return _api.post<dynamic>(path, data: form);
  }
}
''';

  static const downloadService = '''
import '../network/api_client.dart';

/// Downloads files from the backend to a local [savePath].
class DownloadService {
  const DownloadService(this._api);

  final ApiClient _api;

  Future<void> download(String url, String savePath) =>
      _api.dio.download(url, savePath);
}
''';

  static const analyticsService = '''
import 'dart:developer' as developer;

/// Product analytics facade.
///
/// The default implementation logs events through `dart:developer`. Swap it for
/// a real backend (Firebase, PostHog, …) without touching call sites.
class AnalyticsService {
  const AnalyticsService();

  void logEvent(String name, {Map<String, Object?> parameters = const {}}) {
    developer.log('event: \$name \$parameters', name: 'analytics');
  }

  void setUserId(String? id) {
    developer.log('userId: \$id', name: 'analytics');
  }
}
''';

  // ─── Routing ───────────────────────────────────────────────────

  static const routingBarrel = '''
export 'guards.dart';
export 'routes.dart';
''';

  static const routes = '''
/// Central registry of top-level route names/paths.
///
/// Each feature also declares its own `<Feature>Page.routePath`; this holds the
/// app-level entry points and any shared constants.
abstract final class AppRoutes {
  static const home = '/';
}
''';

  static const guards = '''
/// Pure, router-agnostic navigation guards.
///
/// These return a redirect location (or `null` to allow) so they can be used
/// from go_router's `redirect` or GetX middleware without depending on either
/// package.
abstract final class Guards {
  /// Redirects unauthenticated users to [loginPath]; `null` allows navigation.
  static String? requireAuth({
    required bool isLoggedIn,
    required String loginPath,
  }) =>
      isLoggedIn ? null : loginPath;
}
''';

  // ─── Localization ──────────────────────────────────────────────

  static const localizationBarrel = '''
export '../../i18n/slang/translations.g.dart';
''';

  // ─── Theme ─────────────────────────────────────────────────────

  static const themeBarrel = '''
export 'app_colors.dart';
export 'app_theme.dart';
export 'app_typography.dart';
export 'radius.dart';
export 'spacing.dart';
''';

  static const appColors = '''
import 'package:flutter/material.dart';

/// Central color palette for the application.
///
/// Change [seed] to update the entire Material 3 color scheme.
abstract final class AppColors {
  /// Primary seed color — the entire M3 palette derives from this.
  static const seed = Color(0xFF{{primary_color}});

  // ── Custom overrides (optional) ──────────────────────────────
  // static const success = Color(0xFF4CAF50);
  // static const warning = Color(0xFFFFC107);
}
''';

  static const spacing = '''
/// Consistent spacing scale (4-pt grid). Use instead of magic numbers.
abstract final class Spacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}
''';

  static const radius = '''
import 'package:flutter/widgets.dart';

/// Consistent corner-radius scale.
abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 20;
  static const double pill = 999;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
}
''';

  static const appTheme = '''
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// Application theme data (light & dark).
///
/// Uses [ColorScheme.fromSeed] so the entire palette is derived from a single
/// seed color defined in [AppColors.seed].
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

/// Application text styles, based on the Material 3 type scale.
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

  // ─── UI (generic widgets) ──────────────────────────────────────

  static const uiBarrel = '''
export 'widgets/app_avatar.dart';
export 'widgets/app_card.dart';
export 'widgets/error_view.dart';
export 'widgets/loading.dart';
export 'widgets/primary_button.dart';
''';

  static const loadingWidget = '''
import 'package:flutter/material.dart';

/// Centered, theme-aware progress indicator used across features.
class Loading extends StatelessWidget {
  const Loading({super.key, this.size = 28});

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

  static const errorView = '''
import 'package:flutter/material.dart';

/// Full-screen error state with an optional retry action.
class ErrorView extends StatelessWidget {
  const ErrorView({required this.message, super.key, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
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

  static const appAvatar = '''
import 'package:flutter/material.dart';

/// Circular avatar that falls back to the initials when [imageUrl] is null.
class AppAvatar extends StatelessWidget {
  const AppAvatar({required this.label, super.key, this.imageUrl, this.radius = 20});

  final String label;
  final String? imageUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final initials = label.trim().isEmpty
        ? '?'
        : label.trim()[0].toUpperCase();
    return CircleAvatar(
      radius: radius,
      backgroundImage: imageUrl == null ? null : NetworkImage(imageUrl!),
      child: imageUrl == null ? Text(initials) : null,
    );
  }
}
''';

  static const appCard = '''
import 'package:flutter/material.dart';

import '../../theme/radius.dart';

/// Rounded, tappable surface used to group content.
class AppCard extends StatelessWidget {
  const AppCard({required this.child, super.key, this.onTap, this.padding});

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}
''';

  // ─── Errors ────────────────────────────────────────────────────

  static const errorsBarrel = '''
export 'error_mapper.dart';
export 'exceptions.dart';
export 'failures.dart';
export 'result.dart';
''';

  static const failures = '''
/// Domain-level errors returned by repositories and use cases.
///
/// Unlike [Exception]s (thrown by datasources), failures are values you can
/// carry through the layers. Kept `abstract` (not `sealed`) so individual
/// features can declare their own `<Feature>Failure extends Failure`.
abstract class Failure {
  const Failure(this.message);
  final String message;
}

final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection']);
}

final class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Something went wrong']);
}

final class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache error']);
}

final class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Unexpected error']);
}
''';

  static const exceptions = '''
/// Low-level errors thrown by datasources; mapped to [Failure]s in repositories.
class ServerException implements Exception {
  const ServerException([this.message = 'Server error']);
  final String message;
}

class CacheException implements Exception {
  const CacheException([this.message = 'Cache error']);
  final String message;
}

class NetworkException implements Exception {
  const NetworkException([this.message = 'Network error']);
  final String message;
}
''';

  static const errorMapper = '''
import 'package:dio/dio.dart';

import 'exceptions.dart';
import 'failures.dart';

/// Translates thrown [Exception]s (incl. [DioException]) into domain [Failure]s.
abstract final class ErrorMapper {
  static Failure map(Object error) {
    if (error is DioException) {
      return switch (error.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.connectionError =>
          const NetworkFailure(),
        _ => ServerFailure(error.message ?? 'Server error'),
      };
    }
    if (error is NetworkException) return NetworkFailure(error.message);
    if (error is ServerException) return ServerFailure(error.message);
    if (error is CacheException) return CacheFailure(error.message);
    return const UnknownFailure();
  }
}
''';

  static const resultType = '''
import 'failures.dart';

/// A success/failure wrapper for operations that can fail without throwing.
///
/// Repositories and use cases return `Result<T>`; the presentation layer
/// pattern-matches on it:
///
/// ```dart
/// switch (result) {
///   case Success(:final value): // use value
///   case Failed(:final failure): // show failure.message
/// }
/// ```
sealed class Result<T> {
  const Result();

  const factory Result.success(T value) = Success<T>;
  const factory Result.failed(Failure failure) = Failed<T>;

  bool get isSuccess => this is Success<T>;
}

final class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;
}

final class Failed<T> extends Result<T> {
  const Failed(this.failure);
  final Failure failure;
}
''';

  // ─── Extensions ────────────────────────────────────────────────

  static const extensionsBarrel = '''
export 'context_extensions.dart';
export 'date_extensions.dart';
export 'string_extensions.dart';
''';

  static const contextExtensions = '''
import 'package:flutter/material.dart';

/// Ergonomic shortcuts on [BuildContext].
extension BuildContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colors => Theme.of(this).colorScheme;
  Size get screenSize => MediaQuery.sizeOf(this);

  void showSnack(String message) => ScaffoldMessenger.of(this)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
''';

  static const stringExtensions = '''
/// Small [String] helpers.
extension StringX on String {
  /// Uppercases the first character, leaving the rest untouched.
  String get capitalized =>
      isEmpty ? this : '\${this[0].toUpperCase()}\${substring(1)}';

  /// Whether the string is a syntactically valid email.
  bool get isEmail =>
      RegExp(r'^[\\w.+-]+@[\\w-]+\\.[\\w.-]+\$').hasMatch(trim());

  /// Returns null when the string is blank — handy for optional fields.
  String? get nullIfBlank => trim().isEmpty ? null : this;
}
''';

  static const dateExtensions = '''
/// Small [DateTime] helpers.
extension DateTimeX on DateTime {
  bool get isToday {
    final now = DateTime.now();
    return now.year == year && now.month == month && now.day == day;
  }

  /// `2026-07-24` style ISO date (no time component).
  String get isoDate =>
      '\${year.toString().padLeft(4, '0')}-'
      '\${month.toString().padLeft(2, '0')}-'
      '\${day.toString().padLeft(2, '0')}';
}
''';

  // ─── Mixins ────────────────────────────────────────────────────

  static const mixinsBarrel = "export 'validation_mixin.dart';\n";

  static const validationMixin = '''
/// Reusable validation helpers for forms and controllers.
mixin ValidationMixin {
  String? validateEmail(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Email is required';
    if (!RegExp(r'^[\\w.+-]+@[\\w-]+\\.[\\w.-]+\$').hasMatch(v)) {
      return 'Enter a valid email';
    }
    return null;
  }

  String? validateRequired(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '\$field is required';
    return null;
  }

  String? validateMinLength(String? value, int length) {
    if ((value ?? '').length < length) {
      return 'Must be at least \$length characters';
    }
    return null;
  }
}
''';

  // ─── Utils ─────────────────────────────────────────────────────

  static const utilsBarrel = '''
export 'debouncer.dart';
export 'formatter.dart';
export 'logger.dart';
export 'validators.dart';
''';

  static const validators = '''
/// Reusable, framework-agnostic form validators.
///
/// Each returns `null` when the input is valid, or an error message otherwise —
/// the shape expected by [FormFieldValidator].
abstract final class Validators {
  static final _emailRegExp = RegExp(r'^[\\w.+-]+@[\\w-]+\\.[\\w.-]+\$');

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Email is required';
    if (!_emailRegExp.hasMatch(v)) return 'Enter a valid email';
    return null;
  }

  static String? notEmpty(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '\$field is required';
    return null;
  }

  static String? minLength(String? value, int length) {
    if ((value ?? '').length < length) {
      return 'Must be at least \$length characters';
    }
    return null;
  }
}
''';

  static const logger = '''
import 'dart:developer' as developer;

/// Dependency-free logging facade over `dart:developer`.
///
/// Registered in DI so features log through a single seam that can later be
/// swapped for Crashlytics, Sentry, etc. without touching call sites.
class Logger {
  const Logger({this.name = 'app'});

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

  static const debouncer = '''
import 'dart:async';

/// Delays an action until [duration] has elapsed without another call.
///
/// ```dart
/// final debouncer = Debouncer(duration: const Duration(milliseconds: 300));
/// onChanged: (q) => debouncer.run(() => search(q));
/// ```
class Debouncer {
  Debouncer({this.duration = const Duration(milliseconds: 300)});

  final Duration duration;
  Timer? _timer;

  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(duration, action);
  }

  void dispose() => _timer?.cancel();
}
''';

  static const formatter = '''
/// Small formatting helpers (dates, sizes, …).
abstract final class Formatter {
  /// `1536` -> `"1.5 KB"`.
  static String fileSize(int bytes) {
    if (bytes < 1024) return '\$bytes B';
    const units = ['KB', 'MB', 'GB', 'TB'];
    var size = bytes / 1024;
    var unit = 0;
    while (size >= 1024 && unit < units.length - 1) {
      size /= 1024;
      unit++;
    }
    return '\${size.toStringAsFixed(1)} \${units[unit]}';
  }

  /// `08:05` clock time from a [DateTime].
  static String clock(DateTime time) =>
      '\${time.hour.toString().padLeft(2, '0')}:'
      '\${time.minute.toString().padLeft(2, '0')}';
}
''';

  // ─── Dependency injection (get_it) ─────────────────────────────

  static const diBarrel = "export 'injection.dart';\n";

  static const diSetup = '''
import 'package:env/env.dart';
import 'package:get_it/get_it.dart';
import 'package:relax_storage/relax_storage.dart';
import 'package:{{project_name.snakeCase()}}/core/cache/cached_storage.dart';
import 'package:{{project_name.snakeCase()}}/core/cache/memory_cache.dart';
import 'package:{{project_name.snakeCase()}}/core/config/app_config.dart';
import 'package:{{project_name.snakeCase()}}/core/database/app_database.dart';
import 'package:{{project_name.snakeCase()}}/core/encryption/app_encrypter.dart';
import 'package:{{project_name.snakeCase()}}/core/network/api_client.dart';
import 'package:{{project_name.snakeCase()}}/core/network/network_info.dart';
import 'package:{{project_name.snakeCase()}}/core/services/analytics_service.dart';
import 'package:{{project_name.snakeCase()}}/core/services/connectivity_service.dart';
import 'package:{{project_name.snakeCase()}}/core/services/download_service.dart';
import 'package:{{project_name.snakeCase()}}/core/services/notification_service.dart';
import 'package:{{project_name.snakeCase()}}/core/services/permission_service.dart';
import 'package:{{project_name.snakeCase()}}/core/services/upload_service.dart';
import 'package:{{project_name.snakeCase()}}/core/utils/logger.dart';
import 'package:{{project_name.snakeCase()}}/core/websocket/socket_service.dart';

final getIt = GetIt.instance;

/// Wires the core infrastructure into the service locator.
///
/// Called once from `bootstrap` before `runApp`. The database is registered
/// lazily (`getAsync`) so it only opens the first time it is requested. Register
/// your feature repositories and use cases below the marked section.
Future<void> setUpRegister(EnvValue env) async {
  await RelaxStorage.init();

  final cachedStorage = CachedStorage(env);
  final encryptionKey = env(Env.encryptionKey);

  getIt
    // ── Config & storage ──────────────────────────────────────
    ..registerSingleton<EnvValue>(env)
    ..registerSingleton<AppConfig>(AppConfig(env))
    ..registerSingleton<CachedStorage>(cachedStorage)
    ..registerSingleton<AppEncrypter>(AppEncrypter(encryptionKey))
    ..registerLazySingleton<MemoryCache>(MemoryCache.new)
    // ── Networking ────────────────────────────────────────────
    ..registerLazySingleton<ApiClient>(
      () => ApiClient(env: env, storage: cachedStorage),
    )
    ..registerLazySingleton<ConnectivityService>(ConnectivityService.new)
    ..registerLazySingleton<NetworkInfo>(
      () => NetworkInfo(getIt<ConnectivityService>()),
    )
    // ── Services ──────────────────────────────────────────────
    ..registerLazySingleton<Logger>(Logger.new)
    ..registerLazySingleton<AnalyticsService>(AnalyticsService.new)
    ..registerLazySingleton<NotificationService>(NotificationService.new)
    ..registerLazySingleton<PermissionService>(PermissionService.new)
    ..registerLazySingleton<SocketService>(SocketService.new)
    ..registerLazySingleton<UploadService>(
      () => UploadService(getIt<ApiClient>()),
    )
    ..registerLazySingleton<DownloadService>(
      () => DownloadService(getIt<ApiClient>()),
    )
    // ── Database (opens on first use) ─────────────────────────
    ..registerLazySingletonAsync<AppDatabase>(
      () => AppDatabase.open(encryptionKey),
    );

  // relax:di-register
  // Register your feature repositories and use cases here, e.g.:
  // getIt.registerLazySingleton<HomeRepository>(
  //   () => HomeRepositoryImpl(
  //     remote: HomeRemoteDatasource(getIt<ApiClient>()),
  //     local: HomeLocalDatasource(),
  //   ),
  // );
}
''';

  // ─── Features barrel ───────────────────────────────────────────

  /// Aggregate barrel re-exporting every feature. This is the single import the
  /// router (and anything else) uses to reach feature pages. The `relax:features`
  /// anchor is the insertion point for `relax generate feature`.
  static const featuresBarrel = '''
export 'home/home.dart';
// relax:features
''';

  // ─── Router (go_router) ────────────────────────────────────────

  /// App router. Lives in `core/routing/` (not `app/`) per the project's Clean
  /// Architecture. Feature pages are reached through the aggregate
  /// `features/features.dart` barrel. The `relax:router-routes` anchor is the
  /// insertion point for `relax generate feature`; do not remove it.
  static const appRouter = '''
import 'package:go_router/go_router.dart';

import '../../features/features.dart';
import 'routes.dart';

/// The application router.
///
/// Each feature owns its own `<Feature>Page.routeName` / `.routePath`; this file
/// aggregates them into a single [GoRouter].
final appRouter = GoRouter(
  initialLocation: AppRoutes.home,
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

  /// GetX variant of the router: a list of [GetPage] entries. Uses the same
  /// `relax:router-routes` anchor as the go_router variant.
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
import 'package:{{project_name.snakeCase()}}/core/config/flavors/flavor.dart';
import 'package:env/env.dart';

void main() {
  FlavorConfig.current = AppEnvironment.development;
  bootstrap(() => const App(), env: AppFlavor.development().getEnv);
}
''';

  static const mainStaging = '''
import 'package:{{project_name.snakeCase()}}/app/app.dart';
import 'package:{{project_name.snakeCase()}}/bootstrap.dart';
import 'package:{{project_name.snakeCase()}}/core/config/flavors/flavor.dart';
import 'package:env/env.dart';

void main() {
  FlavorConfig.current = AppEnvironment.staging;
  bootstrap(() => const App(), env: AppFlavor.staging().getEnv);
}
''';

  static const mainProduction = '''
import 'package:{{project_name.snakeCase()}}/app/app.dart';
import 'package:{{project_name.snakeCase()}}/bootstrap.dart';
import 'package:{{project_name.snakeCase()}}/core/config/flavors/flavor.dart';
import 'package:env/env.dart';

void main() {
  FlavorConfig.current = AppEnvironment.production;
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

import 'core/dependency_injection/injection.dart' as di;
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

import 'core/dependency_injection/injection.dart' as di;
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

import 'core/dependency_injection/injection.dart' as di;
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

import 'core/dependency_injection/injection.dart' as di;
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

  // ─── Home feature: shared data / domain (arch-agnostic) ────────

  /// The home feature's `data` + `domain` + `state` files, identical for every
  /// architecture. Only its `presentation/` layer differs per state manager and
  /// is provided by each app template. Home is intentionally **local-only** (no
  /// network) so the freshly generated app runs cleanly offline.
  static List<TemplateFile> homeSharedFiles() => [
    TemplateFile(
      p('lib/features/home/domain/entities/home_entity.dart'),
      homeEntity,
    ),
    TemplateFile(
      p('lib/features/home/domain/repositories/home_repository.dart'),
      homeRepository,
    ),
    TemplateFile(
      p('lib/features/home/domain/usecases/get_home_content_usecase.dart'),
      homeUseCase,
    ),
    TemplateFile(p('lib/features/home/data/models/home_model.dart'), homeModel),
    TemplateFile(
      p('lib/features/home/data/mappers/home_mapper.dart'),
      homeMapper,
    ),
    TemplateFile(
      p('lib/features/home/data/datasources/home_local_datasource.dart'),
      homeLocalDatasource,
    ),
    TemplateFile(
      p('lib/features/home/data/repositories/home_repository_impl.dart'),
      homeRepositoryImpl,
    ),
    TemplateFile(
      p('lib/features/home/presentation/states/home_state.dart'),
      homeState,
    ),
  ];

  static const homeEntity = '''
/// Domain entity for the home screen.
class HomeEntity {
  const HomeEntity({required this.title, required this.subtitle});

  final String title;
  final String subtitle;
}
''';

  static const homeRepository = '''
import '../entities/home_entity.dart';

/// Contract for reading the home screen content.
abstract class HomeRepository {
  Future<HomeEntity> getContent();
}
''';

  static const homeUseCase = '''
import '../entities/home_entity.dart';
import '../repositories/home_repository.dart';

/// Loads the home screen content.
class GetHomeContentUseCase {
  const GetHomeContentUseCase(this._repository);

  final HomeRepository _repository;

  Future<HomeEntity> call() => _repository.getContent();
}
''';

  static const homeModel = '''
/// Data model mirroring the home content payload.
class HomeModel {
  const HomeModel({required this.title, required this.subtitle});

  factory HomeModel.fromJson(Map<String, dynamic> json) => HomeModel(
        title: (json['title'] ?? '').toString(),
        subtitle: (json['subtitle'] ?? '').toString(),
      );

  final String title;
  final String subtitle;

  Map<String, dynamic> toJson() => {'title': title, 'subtitle': subtitle};
}
''';

  static const homeMapper = '''
import '../../domain/entities/home_entity.dart';
import '../models/home_model.dart';

extension HomeModelMapper on HomeModel {
  HomeEntity toEntity() => HomeEntity(title: title, subtitle: subtitle);
}
''';

  static const homeLocalDatasource = '''
import '../models/home_model.dart';

/// Serves the home content locally so the app runs offline out of the box.
class HomeLocalDatasource {
  const HomeLocalDatasource();

  Future<HomeModel> getContent() async => const HomeModel(
        title: 'Welcome',
        subtitle: 'Your project is ready.',
      );
}
''';

  static const homeRepositoryImpl = '''
import '../../domain/entities/home_entity.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_local_datasource.dart';
import '../mappers/home_mapper.dart';

class HomeRepositoryImpl implements HomeRepository {
  const HomeRepositoryImpl(this._local);

  final HomeLocalDatasource _local;

  @override
  Future<HomeEntity> getContent() async {
    final model = await _local.getContent();
    return model.toEntity();
  }
}
''';

  static const homeState = '''
import '../../domain/entities/home_entity.dart';

sealed class HomeState {
  const HomeState();
}

final class HomeLoading extends HomeState {
  const HomeLoading();
}

final class HomeLoaded extends HomeState {
  const HomeLoaded(this.content);
  final HomeEntity content;
}

final class HomeError extends HomeState {
  const HomeError(this.message);
  final String message;
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
