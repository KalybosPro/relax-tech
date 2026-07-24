import 'package:mason/mason.dart';

/// Page + View templates for all architectures, matching the Clean-Architecture
/// feature layout.
///
/// A page is added to an existing feature and reuses that feature's controller
/// and state. Files are written under
/// `lib/features/<feature_name>/presentation/pages/`.
///
/// Variables: `feature_name` (snake_case folder), `page_name` (snake_case).
abstract final class PageTemplate {
  // ═══════════════════════════════════════════════════════════════
  //  BLOC (Cubit)
  // ═══════════════════════════════════════════════════════════════

  static List<TemplateFile> get bloc => [
    TemplateFile(
      'presentation/pages/{{page_name.snakeCase()}}_page.dart',
      _blocPage,
    ),
    TemplateFile(
      'presentation/pages/{{page_name.snakeCase()}}_view.dart',
      _blocView,
    ),
  ];

  static const _blocPage = '''
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../controllers/{{feature_name.snakeCase()}}_cubit.dart';
import '{{page_name.snakeCase()}}_view.dart';

class {{page_name.pascalCase()}}Page extends StatelessWidget {
  const {{page_name.pascalCase()}}Page({super.key});

  /// Route name used with `context.goNamed({{page_name.pascalCase()}}Page.routeName)`.
  static const routeName = '{{route_name}}';

  /// Path registered as a child route under the feature.
  static const routePath = '{{{route_path}}}';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => {{feature_name.pascalCase()}}Cubit()..load(),
      child: const {{page_name.pascalCase()}}View(),
    );
  }
}
''';

  static const _blocView = '''
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/core.dart';
import '../controllers/{{feature_name.snakeCase()}}_cubit.dart';
import '../states/{{feature_name.snakeCase()}}_state.dart';

class {{page_name.pascalCase()}}View extends StatelessWidget {
  const {{page_name.pascalCase()}}View({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('{{page_name.titleCase()}}')),
      body: BlocBuilder<{{feature_name.pascalCase()}}Cubit, {{feature_name.pascalCase()}}State>(
        builder: (context, state) => switch (state) {
          {{feature_name.pascalCase()}}Loading() => const Loading(),
          {{feature_name.pascalCase()}}Error(:final message) => ErrorView(message: message),
          {{feature_name.pascalCase()}}Loaded() => const Center(
              child: Text('{{page_name.titleCase()}}'),
            ),
        },
      ),
    );
  }
}
''';

  // ═══════════════════════════════════════════════════════════════
  //  PROVIDER
  // ═══════════════════════════════════════════════════════════════

  static List<TemplateFile> get provider => [
    TemplateFile(
      'presentation/pages/{{page_name.snakeCase()}}_page.dart',
      _providerPage,
    ),
    TemplateFile(
      'presentation/pages/{{page_name.snakeCase()}}_view.dart',
      _providerView,
    ),
  ];

  static const _providerPage = '''
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/{{feature_name.snakeCase()}}_notifier.dart';
import '{{page_name.snakeCase()}}_view.dart';

class {{page_name.pascalCase()}}Page extends StatelessWidget {
  const {{page_name.pascalCase()}}Page({super.key});

  /// Route name used with `context.goNamed({{page_name.pascalCase()}}Page.routeName)`.
  static const routeName = '{{route_name}}';

  /// Path registered as a child route under the feature.
  static const routePath = '{{{route_path}}}';

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => {{feature_name.pascalCase()}}Notifier()..load(),
      child: const {{page_name.pascalCase()}}View(),
    );
  }
}
''';

  static const _providerView = '''
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/core.dart';
import '../controllers/{{feature_name.snakeCase()}}_notifier.dart';
import '../states/{{feature_name.snakeCase()}}_state.dart';

class {{page_name.pascalCase()}}View extends StatelessWidget {
  const {{page_name.pascalCase()}}View({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<{{feature_name.pascalCase()}}Notifier>().state;

    return Scaffold(
      appBar: AppBar(title: const Text('{{page_name.titleCase()}}')),
      body: switch (state) {
        {{feature_name.pascalCase()}}Loading() => const Loading(),
        {{feature_name.pascalCase()}}Error(:final message) => ErrorView(message: message),
        {{feature_name.pascalCase()}}Loaded() => const Center(
            child: Text('{{page_name.titleCase()}}'),
          ),
      },
    );
  }
}
''';

  // ═══════════════════════════════════════════════════════════════
  //  RIVERPOD
  // ═══════════════════════════════════════════════════════════════

  static List<TemplateFile> get riverpod => [
    TemplateFile(
      'presentation/pages/{{page_name.snakeCase()}}_page.dart',
      _riverpodPage,
    ),
    TemplateFile(
      'presentation/pages/{{page_name.snakeCase()}}_view.dart',
      _riverpodView,
    ),
  ];

  static const _riverpodPage = '''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '{{page_name.snakeCase()}}_view.dart';

class {{page_name.pascalCase()}}Page extends ConsumerWidget {
  const {{page_name.pascalCase()}}Page({super.key});

  /// Route name used with `context.goNamed({{page_name.pascalCase()}}Page.routeName)`.
  static const routeName = '{{route_name}}';

  /// Path registered as a child route under the feature.
  static const routePath = '{{{route_path}}}';

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      const {{page_name.pascalCase()}}View();
}
''';

  static const _riverpodView = '''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/core.dart';
import '../controllers/{{feature_name.snakeCase()}}_notifier.dart';
import '../states/{{feature_name.snakeCase()}}_state.dart';

class {{page_name.pascalCase()}}View extends ConsumerWidget {
  const {{page_name.pascalCase()}}View({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch({{feature_name.camelCase()}}Provider);

    return Scaffold(
      appBar: AppBar(title: const Text('{{page_name.titleCase()}}')),
      body: switch (state) {
        {{feature_name.pascalCase()}}Loading() => const Loading(),
        {{feature_name.pascalCase()}}Error(:final message) => ErrorView(message: message),
        {{feature_name.pascalCase()}}Loaded() => const Center(
            child: Text('{{page_name.titleCase()}}'),
          ),
      },
    );
  }
}
''';

  // ═══════════════════════════════════════════════════════════════
  //  GETX
  // ═══════════════════════════════════════════════════════════════

  static List<TemplateFile> get getx => [
    TemplateFile(
      'presentation/pages/{{page_name.snakeCase()}}_page.dart',
      _getxPage,
    ),
    TemplateFile(
      'presentation/pages/{{page_name.snakeCase()}}_view.dart',
      _getxView,
    ),
  ];

  static const _getxPage = '''
import 'package:flutter/material.dart';

import '{{page_name.snakeCase()}}_view.dart';

class {{page_name.pascalCase()}}Page extends StatelessWidget {
  const {{page_name.pascalCase()}}Page({super.key});

  /// Route name used with `Get.toNamed({{page_name.pascalCase()}}Page.routePath)`.
  static const routeName = '{{route_name}}';

  /// Absolute route path registered in [appPages].
  static const routePath = '{{{route_path}}}';

  @override
  Widget build(BuildContext context) => const {{page_name.pascalCase()}}View();
}
''';

  static const _getxView = '''
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/core.dart';
import '../controllers/{{feature_name.snakeCase()}}_controller.dart';
import '../states/{{feature_name.snakeCase()}}_state.dart';

class {{page_name.pascalCase()}}View extends GetView<{{feature_name.pascalCase()}}Controller> {
  const {{page_name.pascalCase()}}View({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('{{page_name.titleCase()}}')),
      body: Obx(
        () => switch (controller.state.value) {
          {{feature_name.pascalCase()}}Loading() => const Loading(),
          {{feature_name.pascalCase()}}Error(:final message) => ErrorView(message: message),
          {{feature_name.pascalCase()}}Loaded() => const Center(
              child: Text('{{page_name.titleCase()}}'),
            ),
        },
      ),
    );
  }
}
''';
}
