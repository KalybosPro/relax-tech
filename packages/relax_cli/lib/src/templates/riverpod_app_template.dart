import 'package:mason/mason.dart';

import 'shared_template.dart';

/// All template files for a Flutter app with Riverpod architecture.
abstract final class RiverpodAppTemplate {
  static List<TemplateFile> get files => [
    ...SharedTemplate.coreFiles(serviceLocator: false),
    TemplateFile(
      SharedTemplate.p(
        'lib/core/dependency_injection/dependency_injection.dart',
      ),
      _diBarrel,
    ),
    TemplateFile(
      SharedTemplate.p('lib/core/dependency_injection/providers.dart'),
      _providers,
    ),

    TemplateFile(SharedTemplate.p('pubspec.yaml'), _pubspec),
    TemplateFile(
      SharedTemplate.p('README.md'),
      SharedTemplate.readme(
        'Riverpod',
        'controllers/ (Notifier)',
        di: 'Riverpod providers (no service locator)',
      ),
    ),

    TemplateFile(SharedTemplate.p('lib/bootstrap.dart'), _bootstrap),
    TemplateFile(
      SharedTemplate.p('lib/main_development.dart'),
      SharedTemplate.mainDevelopment,
    ),
    TemplateFile(
      SharedTemplate.p('lib/main_staging.dart'),
      SharedTemplate.mainStaging,
    ),
    TemplateFile(
      SharedTemplate.p('lib/main_production.dart'),
      SharedTemplate.mainProduction,
    ),
    TemplateFile(
      SharedTemplate.p('lib/app/app.dart'),
      SharedTemplate.appBarrel,
    ),
    TemplateFile(SharedTemplate.p('lib/app/view/app.dart'), _appView),
    TemplateFile(
      SharedTemplate.p('lib/core/routing/app_router.dart'),
      SharedTemplate.appRouter,
    ),

    TemplateFile(
      SharedTemplate.p('lib/features/features.dart'),
      SharedTemplate.featuresBarrel,
    ),
    ...SharedTemplate.homeSharedFiles(),
    TemplateFile(SharedTemplate.p('lib/features/home/home.dart'), _homeBarrel),
    TemplateFile(
      SharedTemplate.p(
        'lib/features/home/presentation/controllers/home_notifier.dart',
      ),
      _homeNotifier,
    ),
    TemplateFile(
      SharedTemplate.p('lib/features/home/presentation/pages/home_page.dart'),
      _homePage,
    ),
    TemplateFile(
      SharedTemplate.p('lib/features/home/presentation/pages/home_view.dart'),
      _homeView,
    ),

    TemplateFile(
      SharedTemplate.p('test/app/view/app_test.dart'),
      SharedTemplate.appTest,
    ),
  ];

  static const _pubspec = '''
name: {{project_name.snakeCase()}}
description: {{description}}
publish_to: 'none'
version: 1.0.0

environment:
  sdk: ">=3.11.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  cupertino_icons: ^1.0.8

  flutter_riverpod: ^3.4.2
  go_router: ^17.5.0
  slang: ^4.19.0
  slang_flutter: ^4.19.0
  relax_orm: ^1.2.0
  relax_storage: ^1.0.1
  dio: ^5.11.0
{{#socket_io}}  socket_io_client: ^3.1.6
{{/socket_io}}{{^socket_io}}  web_socket_channel: ^3.0.3
{{/socket_io}}  env:
    path: packages/env

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  # Capped: relax_orm_generator pins analyzer ^10, which build_runner >=2.15.2 rejects.
  build_runner: ^2.15.1
  relax_orm_generator: ^1.0.1

flutter:
  uses-material-design: true
''';

  static const _diBarrel = "export 'providers.dart';\n";

  /// Riverpod replaces the get_it service locator: every core dependency is a
  /// provider, so features resolve them with `ref.watch` / `ref.read` and tests
  /// swap them with `ProviderScope(overrides: [...])`.
  static const _providers = '''
import 'package:env/env.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

// ── Config & storage ────────────────────────────────────────

/// Flavor environment. Overridden in `bootstrap` with the real value.
final envProvider = Provider<EnvValue>(
  (ref) => throw UnimplementedError('envProvider is overridden in bootstrap'),
);

final appConfigProvider = Provider<AppConfig>(
  (ref) => AppConfig(ref.watch(envProvider)),
);

final cachedStorageProvider = Provider<CachedStorage>(
  (ref) => CachedStorage(ref.watch(envProvider)),
);

final appEncrypterProvider = Provider<AppEncrypter>(
  (ref) => AppEncrypter(ref.watch(envProvider)(Env.encryptionKey)),
);

final memoryCacheProvider = Provider<MemoryCache>((ref) => MemoryCache());

// ── Networking ──────────────────────────────────────────────

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(
    env: ref.watch(envProvider),
    storage: ref.watch(cachedStorageProvider),
  ),
);

final connectivityServiceProvider = Provider<ConnectivityService>(
  (ref) => const ConnectivityService(),
);

final networkInfoProvider = Provider<NetworkInfo>(
  (ref) => NetworkInfo(ref.watch(connectivityServiceProvider)),
);

// ── Services ────────────────────────────────────────────────

final loggerProvider = Provider<Logger>((ref) => const Logger());

final analyticsServiceProvider = Provider<AnalyticsService>(
  (ref) => const AnalyticsService(),
);

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => const NotificationService(),
);

final permissionServiceProvider = Provider<PermissionService>(
  (ref) => const PermissionService(),
);

/// Single app-wide realtime connection, closed when the scope is disposed.
final socketServiceProvider = Provider<SocketService>((ref) {
  final service = SocketService();
  ref.onDispose(service.disconnect);
  return service;
});

final uploadServiceProvider = Provider<UploadService>(
  (ref) => UploadService(ref.watch(apiClientProvider)),
);

final downloadServiceProvider = Provider<DownloadService>(
  (ref) => DownloadService(ref.watch(apiClientProvider)),
);

// ── Database (opens on first read) ──────────────────────────

final appDatabaseProvider = FutureProvider<AppDatabase>(
  (ref) => AppDatabase.open(ref.watch(envProvider)(Env.encryptionKey)),
);

// relax:providers
// Declare your feature repositories and use cases here, e.g.:
// final homeRepositoryProvider = Provider<HomeRepository>(
//   (ref) => HomeRepositoryImpl(
//     remote: HomeRemoteDatasource(ref.watch(apiClientProvider)),
//     local: HomeLocalDatasource(),
//   ),
// );
''';

  static const _bootstrap = '''
import 'dart:async';
import 'dart:developer';

import 'package:env/env.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:relax_storage/relax_storage.dart';

import 'core/dependency_injection/providers.dart';
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

    await RelaxStorage.init();

    runApp(
      ProviderScope(
        overrides: [envProvider.overrideWithValue(env)],
        child: builder(),
      ),
    );
  }, (error, stack) {
    log(error.toString(), stackTrace: stack);
  });
}
''';

  static const _appView = '''
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../../core/core.dart';
import '../../core/routing/app_router.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return TranslationProvider(
      child: Builder(
        builder: (context) => MaterialApp.router(
          title: t.appName,
          debugShowCheckedModeBanner: false,
          locale: TranslationProvider.of(context).flutterLocale,
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          routerConfig: appRouter,
        ),
      ),
    );
  }
}
''';

  static const _homeBarrel = '''
export 'domain/entities/home_entity.dart';
export 'presentation/controllers/home_notifier.dart';
export 'presentation/pages/home_page.dart';
export 'presentation/states/home_state.dart';
''';

  static const _homeNotifier = '''
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/home_local_datasource.dart';
import '../../data/repositories/home_repository_impl.dart';
import '../../domain/usecases/get_home_content_usecase.dart';
import '../states/home_state.dart';

final homeProvider =
    NotifierProvider<HomeNotifier, HomeState>(HomeNotifier.new);

class HomeNotifier extends Notifier<HomeState> {
  late GetHomeContentUseCase _getContent;

  @override
  HomeState build() {
    _getContent = const GetHomeContentUseCase(
      HomeRepositoryImpl(HomeLocalDatasource()),
    );
    Future.microtask(load);
    return const HomeLoading();
  }

  Future<void> load() async {
    state = const HomeLoading();
    final content = await _getContent();
    state = HomeLoaded(content);
  }
}
''';

  static const _homePage = '''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'home_view.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  /// Route name used with `context.goNamed(HomePage.routeName)`.
  static const routeName = 'home';

  /// URL path registered in the app router.
  static const routePath = '/';

  @override
  Widget build(BuildContext context, WidgetRef ref) => const HomeView();
}
''';

  static final _homeView =
      '''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/core.dart';
import '../controllers/home_notifier.dart';
import '../states/home_state.dart';

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(homeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.appName, style: theme.textTheme.titleLarge),
      ),
      body: switch (state) {
        HomeLoading() => const Loading(),
        HomeError(:final message) => ErrorView(message: message),
        HomeLoaded() => Center(
${SharedTemplate.welcomeViewBody('Riverpod')}
          ),
      },
    );
  }
}
''';
}
