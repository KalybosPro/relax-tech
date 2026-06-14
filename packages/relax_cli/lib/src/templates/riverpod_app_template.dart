import 'package:mason/mason.dart';

import 'shared_template.dart';

/// All template files for a Flutter app with Riverpod architecture.
abstract final class RiverpodAppTemplate {
  static List<TemplateFile> get files => [
    ...SharedTemplate.coreFiles(),

    TemplateFile(SharedTemplate.p('pubspec.yaml'), _pubspec),
    TemplateFile(
      SharedTemplate.p('README.md'),
      SharedTemplate.readme('Riverpod', 'providers/ → Notifiers & Providers'),
    ),

    TemplateFile(
      SharedTemplate.p('lib/bootstrap.dart'),
      SharedTemplate.bootstrapRiverpod,
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
      SharedTemplate.p('lib/features/home/providers/home_provider.dart'),
      _homeProvider,
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
  
  flutter_riverpod: ^2.6.0
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
import 'package:flutter_localizations/flutter_localizations.dart';

import '../../core/core.dart';
import '../../features/home/home.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return TranslationProvider(
      child: Builder(
        builder: (context) => MaterialApp(
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
    );
  }
}
''';

  static const _homeBarrel = '''
export 'providers/home_provider.dart';
export 'models/home_state.dart';
export 'view/home_page.dart';
''';

  static const _homeProvider = '''
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/home_state.dart';

final homeProvider =
    NotifierProvider<HomeNotifier, HomeState>(HomeNotifier.new);

class HomeNotifier extends Notifier<HomeState> {
  @override
  HomeState build() => const HomeState.initial();

  void init() {
    state = const HomeState.loaded();
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
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/home_provider.dart';
import 'home_view.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(homeProvider.notifier).init());
  }

  @override
  Widget build(BuildContext context) {
    return const HomeView();
  }
}
''';

  static final _homeView =
      '''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/core.dart';
import '../models/home_state.dart';
import '../providers/home_provider.dart';

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(homeProvider);

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
${SharedTemplate.welcomeViewBody('Riverpod')}
          ),
      },
    );
  }
}
''';
}
