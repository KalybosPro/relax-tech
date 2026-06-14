import 'package:mason/mason.dart';

/// Page + View templates for all architectures.
///
/// Variables: `feature_name` (snake_case folder), `page_name` (snake_case).
/// Files are generated relative to `lib/features/<feature_name>/`.
abstract final class PageTemplate {
  // ═══════════════════════════════════════════════════════════════
  //  BLOC
  // ═══════════════════════════════════════════════════════════════

  static List<TemplateFile> get bloc => [
        TemplateFile(
          'view/{{page_name.snakeCase()}}_page.dart',
          _blocPage,
        ),
        TemplateFile(
          'view/{{page_name.snakeCase()}}_view.dart',
          _blocView,
        ),
      ];

  static const _blocPage = '''
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/{{feature_name.snakeCase()}}_bloc.dart';
import '{{page_name.snakeCase()}}_view.dart';

class {{page_name.pascalCase()}}Page extends StatelessWidget {
  const {{page_name.pascalCase()}}Page({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => {{feature_name.pascalCase()}}Bloc()..add(const {{feature_name.pascalCase()}}Started()),
      child: const {{page_name.pascalCase()}}View(),
    );
  }
}
''';

  static const _blocView = '''
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/{{feature_name.snakeCase()}}_bloc.dart';

class {{page_name.pascalCase()}}View extends StatelessWidget {
  const {{page_name.pascalCase()}}View({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '{{page_name.titleCase()}}',
          style: theme.textTheme.titleLarge,
        ),
      ),
      body: BlocBuilder<{{feature_name.pascalCase()}}Bloc, {{feature_name.pascalCase()}}State>(
        builder: (context, state) {
          return const Center(
            child: Text('{{page_name.titleCase()}}'),
          );
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
          'view/{{page_name.snakeCase()}}_page.dart',
          _providerPage,
        ),
        TemplateFile(
          'view/{{page_name.snakeCase()}}_view.dart',
          _providerView,
        ),
      ];

  static const _providerPage = '''
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../notifiers/{{feature_name.snakeCase()}}_notifier.dart';
import '{{page_name.snakeCase()}}_view.dart';

class {{page_name.pascalCase()}}Page extends StatelessWidget {
  const {{page_name.pascalCase()}}Page({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => {{feature_name.pascalCase()}}Notifier()..init(),
      child: const {{page_name.pascalCase()}}View(),
    );
  }
}
''';

  static const _providerView = '''
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/{{feature_name.snakeCase()}}_state.dart';
import '../notifiers/{{feature_name.snakeCase()}}_notifier.dart';

class {{page_name.pascalCase()}}View extends StatelessWidget {
  const {{page_name.pascalCase()}}View({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = context.watch<{{feature_name.pascalCase()}}Notifier>().state;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '{{page_name.titleCase()}}',
          style: theme.textTheme.titleLarge,
        ),
      ),
      body: switch (state) {
        {{feature_name.pascalCase()}}Initial() => const Center(
            child: CircularProgressIndicator(),
          ),
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
          'view/{{page_name.snakeCase()}}_page.dart',
          _riverpodPage,
        ),
        TemplateFile(
          'view/{{page_name.snakeCase()}}_view.dart',
          _riverpodView,
        ),
      ];

  static const _riverpodPage = '''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/{{feature_name.snakeCase()}}_provider.dart';
import '{{page_name.snakeCase()}}_view.dart';

class {{page_name.pascalCase()}}Page extends ConsumerStatefulWidget {
  const {{page_name.pascalCase()}}Page({super.key});

  @override
  ConsumerState<{{page_name.pascalCase()}}Page> createState() => _{{page_name.pascalCase()}}PageState();
}

class _{{page_name.pascalCase()}}PageState extends ConsumerState<{{page_name.pascalCase()}}Page> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read({{feature_name.camelCase()}}Provider.notifier).init());
  }

  @override
  Widget build(BuildContext context) {
    return const {{page_name.pascalCase()}}View();
  }
}
''';

  static const _riverpodView = '''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/{{feature_name.snakeCase()}}_state.dart';
import '../providers/{{feature_name.snakeCase()}}_provider.dart';

class {{page_name.pascalCase()}}View extends ConsumerWidget {
  const {{page_name.pascalCase()}}View({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch({{feature_name.camelCase()}}Provider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '{{page_name.titleCase()}}',
          style: theme.textTheme.titleLarge,
        ),
      ),
      body: switch (state) {
        {{feature_name.pascalCase()}}Initial() => const Center(
            child: CircularProgressIndicator(),
          ),
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
          'view/{{page_name.snakeCase()}}_page.dart',
          _getxPage,
        ),
        TemplateFile(
          'view/{{page_name.snakeCase()}}_view.dart',
          _getxView,
        ),
      ];

  static const _getxPage = '''
import 'package:flutter/material.dart';

import '{{page_name.snakeCase()}}_view.dart';

class {{page_name.pascalCase()}}Page extends StatelessWidget {
  const {{page_name.pascalCase()}}Page({super.key});

  @override
  Widget build(BuildContext context) {
    return const {{page_name.pascalCase()}}View();
  }
}
''';

  static const _getxView = '''
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/{{feature_name.snakeCase()}}_controller.dart';

class {{page_name.pascalCase()}}View extends GetView<{{feature_name.pascalCase()}}Controller> {
  const {{page_name.pascalCase()}}View({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '{{page_name.titleCase()}}',
          style: theme.textTheme.titleLarge,
        ),
      ),
      body: Obx(() {
        if (!controller.isLoaded.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return const Center(
          child: Text('{{page_name.titleCase()}}'),
        );
      }),
    );
  }
}
''';
}
