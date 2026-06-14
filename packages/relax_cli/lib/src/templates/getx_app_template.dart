import 'package:mason/mason.dart';

import 'shared_template.dart';

/// All template files for a Flutter app with GetX architecture.
abstract final class GetxAppTemplate {
  static List<TemplateFile> get files => [
    ...SharedTemplate.coreFiles(),

    TemplateFile(SharedTemplate.p('pubspec.yaml'), _pubspec),
    TemplateFile(
      SharedTemplate.p('README.md'),
      SharedTemplate.readme('GetX', 'controllers/ → GetxControllers'),
    ),

    TemplateFile(
      SharedTemplate.p('lib/bootstrap.dart'),
      SharedTemplate.bootstrapGetx,
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
      SharedTemplate.p('lib/features/home/controllers/home_controller.dart'),
      _homeController,
    ),
    TemplateFile(
      SharedTemplate.p('lib/features/home/bindings/home_binding.dart'),
      _homeBinding,
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
  get: ^4.7.2
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
  flutter_localizations:
    sdk: flutter
  
  flutter_lints: ^5.0.0
  build_runner: ^2.4.0
  relax_orm_generator: ^0.1.6

flutter:
  uses-material-design: true
''';

  static const _appView = '''
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../../core/core.dart';
import '../../features/home/home.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return TranslationProvider(
      child: Builder(
        builder: (context) => GetMaterialApp(
          title: t.appName,
          debugShowCheckedModeBanner: false,
          locale: TranslationProvider.of(context).flutterLocale,
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          initialBinding: HomeBinding(),
          home: const HomePage(),
        ),
      ),
    );
  }
}
''';

  static const _homeBarrel = '''
export 'controllers/home_controller.dart';
export 'bindings/home_binding.dart';
export 'view/home_page.dart';
''';

  static const _homeController = '''
import 'package:get/get.dart';

class HomeController extends GetxController {
  final isLoaded = false.obs;

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    isLoaded.value = true;
  }
}
''';

  static const _homeBinding = '''
import 'package:get/get.dart';

import '../controllers/home_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeController>(HomeController.new);
  }
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
import 'package:get/get.dart';

import '../../../core/core.dart';
import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
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
      body: Obx(() {
        if (!controller.isLoaded.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return Center(
${SharedTemplate.welcomeViewBody('GetX')}
        );
      }),
    );
  }
}
''';
}
