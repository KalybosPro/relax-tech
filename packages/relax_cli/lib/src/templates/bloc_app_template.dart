import 'package:mason/mason.dart';

import 'shared_template.dart';

/// All template files for a Flutter app with Bloc architecture.
abstract final class BlocAppTemplate {
  static List<TemplateFile> get files => [
    // ── Shared core (analysis_options, theme) ───────────────────
    ...SharedTemplate.coreFiles(),

    // ── Root files ──────────────────────────────────────────────
    TemplateFile(SharedTemplate.p('pubspec.yaml'), _pubspec),
    TemplateFile(
      SharedTemplate.p('README.md'),
      SharedTemplate.readme('Bloc', 'bloc/     → Bloc, Events, States'),
    ),

    // ── lib/ (flavor entry points) ────────────────────────────────
    TemplateFile(
      SharedTemplate.p('lib/bootstrap.dart'),
      SharedTemplate.bootstrap,
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

    // ── lib/features/home/ ──────────────────────────────────────
    TemplateFile(SharedTemplate.p('lib/features/home/home.dart'), _homeBarrel),
    TemplateFile(
      SharedTemplate.p('lib/features/home/bloc/home_bloc.dart'),
      _homeBloc,
    ),
    TemplateFile(
      SharedTemplate.p('lib/features/home/bloc/home_event.dart'),
      _homeEvent,
    ),
    TemplateFile(
      SharedTemplate.p('lib/features/home/bloc/home_state.dart'),
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

    // ── test/ ───────────────────────────────────────────────────
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
  
  flutter_bloc: ^9.1.1
  bloc: ^9.2.0
  equatable: ^2.0.7
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
export 'bloc/home_bloc.dart';
export 'view/home_page.dart';
''';

  static const _homeBloc = '''
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc() : super(const HomeInitial()) {
    on<HomeStarted>(_onStarted);
  }

  Future<void> _onStarted(
    HomeStarted event,
    Emitter<HomeState> emit,
  ) async {
    emit(const HomeLoaded());
  }
}
''';

  static const _homeEvent = '''
part of 'home_bloc.dart';

sealed class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object> get props => [];
}

final class HomeStarted extends HomeEvent {
  const HomeStarted();
}
''';

  static const _homeState = '''
part of 'home_bloc.dart';

sealed class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object> get props => [];
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
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/home_bloc.dart';
import 'home_view.dart';

/// Wraps [HomeView] with its [HomeBloc] provider.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HomeBloc()..add(const HomeStarted()),
      child: const HomeView(),
    );
  }
}
''';

  static final _homeView =
      '''
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/core.dart';
import '../bloc/home_bloc.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '{{project_name.titleCase()}}',
          style: theme.textTheme.titleLarge,
        ),
      ),
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          return switch (state) {
            HomeInitial() => const Center(
                child: CircularProgressIndicator(),
              ),
            HomeLoaded() => Center(
${SharedTemplate.welcomeViewBody('Bloc')}
              ),
          };
        },
      ),
    );
  }
}
''';
}
