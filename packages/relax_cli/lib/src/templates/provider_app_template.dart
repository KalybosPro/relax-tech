import 'package:mason/mason.dart';

import 'shared_template.dart';

/// All template files for a Flutter app with Provider architecture.
abstract final class ProviderAppTemplate {
  static List<TemplateFile> get files => [
    ...SharedTemplate.coreFiles(),

    TemplateFile(SharedTemplate.p('pubspec.yaml'), _pubspec),
    TemplateFile(
      SharedTemplate.p('README.md'),
      SharedTemplate.readme('Provider', 'notifiers/ → ChangeNotifiers'),
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

    TemplateFile(SharedTemplate.p('lib/features/home/home.dart'), _homeBarrel),
    TemplateFile(
      SharedTemplate.p('lib/features/home/notifiers/home_notifier.dart'),
      _homeNotifier,
    ),
    TemplateFile(
      SharedTemplate.p('lib/features/home/models/home_state.dart'),
      _homeState,
    ),
    TemplateFile(
      SharedTemplate.p('lib/features/home/view/home_page.dart'),
      _homePage,
    ),
    TemplateFile(
      SharedTemplate.p('lib/features/home/view/home_view.dart'),
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
  
  provider: ^6.1.0
  get_it: ^8.0.3
  slang: ^4.14.0
  slang_flutter: ^4.14.0
  relax_orm: ^0.1.4
  relax_storage: ^1.0.1
  env:
    path: packages/env

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  build_runner: ^2.4.0
  relax_orm_generator: ^0.1.6

flutter:
  uses-material-design: true
''';

  static const _appView = '''
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../../core/core.dart';
import '../../features/home/home.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return TranslationProvider(
      child: Builder(
        builder: (context) => MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => HomeNotifier()..init()),
          ],
          child: MaterialApp(
            title: t.appName,
            debugShowCheckedModeBanner: false,
            locale: TranslationProvider.of(context).flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: const HomePage(),
          ),
        ),
      ),
    );
  }
}
''';

  static const _homeBarrel = '''
export 'notifiers/home_notifier.dart';
export 'models/home_state.dart';
export 'view/home_page.dart';
''';

  static const _homeNotifier = '''
import 'package:flutter/foundation.dart';

import '../models/home_state.dart';

class HomeNotifier extends ChangeNotifier {
  HomeState _state = const HomeState.initial();

  HomeState get state => _state;

  Future<void> init() async {
    _state = const HomeState.loaded();
    notifyListeners();
  }
}
''';

  static const _homeState = '''
sealed class HomeState {
  const HomeState();

  const factory HomeState.initial() = HomeInitial;
  const factory HomeState.loaded() = HomeLoaded;
}

final class HomeInitial extends HomeState {
  const HomeInitial();
}

final class HomeLoaded extends HomeState {
  const HomeLoaded();
}
''';

  static const _homePage = '''
import 'package:flutter/material.dart';

import 'home_view.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomeView();
  }
}
''';

  static final _homeView =
      '''
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/core.dart';
import '../models/home_state.dart';
import '../notifiers/home_notifier.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = context.watch<HomeNotifier>().state;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '{{project_name.titleCase()}}',
          style: theme.textTheme.titleLarge,
        ),
      ),
      body: switch (state) {
        HomeInitial() => const Center(
            child: CircularProgressIndicator(),
          ),
        HomeLoaded() => Center(
${SharedTemplate.welcomeViewBody('Provider')}
          ),
      },
    );
  }
}
''';
}
