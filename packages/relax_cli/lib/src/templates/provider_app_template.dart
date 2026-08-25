import 'package:mason/mason.dart';

import 'shared_template.dart';

/// All template files for a Flutter app with Provider architecture.
abstract final class ProviderAppTemplate {
  static List<TemplateFile> get files => [
    ...SharedTemplate.coreFiles(),

    TemplateFile(SharedTemplate.p('pubspec.yaml'), _pubspec),
    TemplateFile(
      SharedTemplate.p('README.md'),
      SharedTemplate.readme('Provider', 'controllers/ (ChangeNotifier)'),
    ),

    TemplateFile(
      SharedTemplate.p('lib/bootstrap.dart'),
      SharedTemplate.bootstrapProvider,
    ),
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

  provider: ^6.1.5+1
  get_it: ^9.2.1
  go_router: ^17.5.0
  slang: ^4.19.0
  slang_flutter: ^4.19.0
  relax_orm: ^1.2.0
  relax_storage: ^1.0.1
  dio: ^5.11.0
  web_socket_channel: ^3.0.3
  env:
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
import 'package:flutter/foundation.dart';

import '../../data/datasources/home_local_datasource.dart';
import '../../data/repositories/home_repository_impl.dart';
import '../../domain/usecases/get_home_content_usecase.dart';
import '../states/home_state.dart';

class HomeNotifier extends ChangeNotifier {
  HomeNotifier({GetHomeContentUseCase? getContent})
      : _getContent = getContent ??
            const GetHomeContentUseCase(
              HomeRepositoryImpl(HomeLocalDatasource()),
            );

  final GetHomeContentUseCase _getContent;

  HomeState _state = const HomeLoading();
  HomeState get state => _state;

  Future<void> load() async {
    _state = const HomeLoading();
    notifyListeners();
    final content = await _getContent();
    _state = HomeLoaded(content);
    notifyListeners();
  }
}
''';

  static const _homePage = '''
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/home_notifier.dart';
import 'home_view.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  /// Route name used with `context.goNamed(HomePage.routeName)`.
  static const routeName = 'home';

  /// URL path registered in the app router.
  static const routePath = '/';

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomeNotifier()..load(),
      child: const HomeView(),
    );
  }
}
''';

  static final _homeView =
      '''
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/core.dart';
import '../controllers/home_notifier.dart';
import '../states/home_state.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = context.watch<HomeNotifier>().state;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.appName, style: theme.textTheme.titleLarge),
      ),
      body: switch (state) {
        HomeLoading() => const Loading(),
        HomeError(:final message) => ErrorView(message: message),
        HomeLoaded() => Center(
${SharedTemplate.welcomeViewBody('Provider')}
          ),
      },
    );
  }
}
''';
}
