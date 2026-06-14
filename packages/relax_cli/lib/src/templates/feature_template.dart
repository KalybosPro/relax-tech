import 'package:mason/mason.dart';

/// Feature templates for all architectures.
///
/// Variable: `feature_name` (snake_case).
/// Files are generated relative to `lib/features/`.
abstract final class FeatureTemplate {
  static String _p(String path) => '{{feature_name.snakeCase()}}/$path';

  // ═══════════════════════════════════════════════════════════════
  //  BLOC
  // ═══════════════════════════════════════════════════════════════

  static List<TemplateFile> get bloc => [
        TemplateFile(_p('{{feature_name.snakeCase()}}.dart'), _blocBarrel),
        TemplateFile(_p('bloc/{{feature_name.snakeCase()}}_bloc.dart'), _bloc),
        TemplateFile(_p('bloc/{{feature_name.snakeCase()}}_event.dart'), _blocEvent),
        TemplateFile(_p('bloc/{{feature_name.snakeCase()}}_state.dart'), _blocState),
        TemplateFile(_p('view/{{feature_name.snakeCase()}}_page.dart'), _blocPage),
        TemplateFile(_p('view/{{feature_name.snakeCase()}}_view.dart'), _blocView),
      ];

  static const _blocBarrel = '''
export 'bloc/{{feature_name.snakeCase()}}_bloc.dart';
export 'view/{{feature_name.snakeCase()}}_page.dart';
''';

  static const _bloc = '''
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part '{{feature_name.snakeCase()}}_event.dart';
part '{{feature_name.snakeCase()}}_state.dart';

class {{feature_name.pascalCase()}}Bloc
    extends Bloc<{{feature_name.pascalCase()}}Event, {{feature_name.pascalCase()}}State> {
  {{feature_name.pascalCase()}}Bloc() : super(const {{feature_name.pascalCase()}}Initial()) {
    on<{{feature_name.pascalCase()}}Started>(_onStarted);
  }

  Future<void> _onStarted(
    {{feature_name.pascalCase()}}Started event,
    Emitter<{{feature_name.pascalCase()}}State> emit,
  ) async {
    emit(const {{feature_name.pascalCase()}}Loaded());
  }
}
''';

  static const _blocEvent = '''
part of '{{feature_name.snakeCase()}}_bloc.dart';

sealed class {{feature_name.pascalCase()}}Event extends Equatable {
  const {{feature_name.pascalCase()}}Event();

  @override
  List<Object> get props => [];
}

final class {{feature_name.pascalCase()}}Started extends {{feature_name.pascalCase()}}Event {
  const {{feature_name.pascalCase()}}Started();
}
''';

  static const _blocState = '''
part of '{{feature_name.snakeCase()}}_bloc.dart';

sealed class {{feature_name.pascalCase()}}State extends Equatable {
  const {{feature_name.pascalCase()}}State();

  @override
  List<Object> get props => [];
}

final class {{feature_name.pascalCase()}}Initial extends {{feature_name.pascalCase()}}State {
  const {{feature_name.pascalCase()}}Initial();
}

final class {{feature_name.pascalCase()}}Loaded extends {{feature_name.pascalCase()}}State {
  const {{feature_name.pascalCase()}}Loaded();
}
''';

  static const _blocPage = '''
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/{{feature_name.snakeCase()}}_bloc.dart';
import '{{feature_name.snakeCase()}}_view.dart';

class {{feature_name.pascalCase()}}Page extends StatelessWidget {
  const {{feature_name.pascalCase()}}Page({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => {{feature_name.pascalCase()}}Bloc()..add(const {{feature_name.pascalCase()}}Started()),
      child: const {{feature_name.pascalCase()}}View(),
    );
  }
}
''';

  static const _blocView = '''
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/{{feature_name.snakeCase()}}_bloc.dart';

class {{feature_name.pascalCase()}}View extends StatelessWidget {
  const {{feature_name.pascalCase()}}View({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '{{feature_name.titleCase()}}',
          style: theme.textTheme.titleLarge,
        ),
      ),
      body: BlocBuilder<{{feature_name.pascalCase()}}Bloc, {{feature_name.pascalCase()}}State>(
        builder: (context, state) {
          return switch (state) {
            {{feature_name.pascalCase()}}Initial() => const Center(
                child: CircularProgressIndicator(),
              ),
            {{feature_name.pascalCase()}}Loaded() => const Center(
                child: Text('{{feature_name.titleCase()}}'),
              ),
          };
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
        TemplateFile(_p('{{feature_name.snakeCase()}}.dart'), _providerBarrel),
        TemplateFile(_p('notifiers/{{feature_name.snakeCase()}}_notifier.dart'), _providerNotifier),
        TemplateFile(_p('models/{{feature_name.snakeCase()}}_state.dart'), _providerState),
        TemplateFile(_p('view/{{feature_name.snakeCase()}}_page.dart'), _providerPage),
        TemplateFile(_p('view/{{feature_name.snakeCase()}}_view.dart'), _providerView),
      ];

  static const _providerBarrel = '''
export 'notifiers/{{feature_name.snakeCase()}}_notifier.dart';
export 'models/{{feature_name.snakeCase()}}_state.dart';
export 'view/{{feature_name.snakeCase()}}_page.dart';
''';

  static const _providerNotifier = '''
import 'package:flutter/foundation.dart';

import '../models/{{feature_name.snakeCase()}}_state.dart';

class {{feature_name.pascalCase()}}Notifier extends ChangeNotifier {
  {{feature_name.pascalCase()}}State _state = const {{feature_name.pascalCase()}}State.initial();

  {{feature_name.pascalCase()}}State get state => _state;

  Future<void> init() async {
    _state = const {{feature_name.pascalCase()}}State.loaded();
    notifyListeners();
  }
}
''';

  static const _providerState = '''
sealed class {{feature_name.pascalCase()}}State {
  const {{feature_name.pascalCase()}}State();

  const factory {{feature_name.pascalCase()}}State.initial() = {{feature_name.pascalCase()}}Initial;
  const factory {{feature_name.pascalCase()}}State.loaded() = {{feature_name.pascalCase()}}Loaded;
}

final class {{feature_name.pascalCase()}}Initial extends {{feature_name.pascalCase()}}State {
  const {{feature_name.pascalCase()}}Initial();
}

final class {{feature_name.pascalCase()}}Loaded extends {{feature_name.pascalCase()}}State {
  const {{feature_name.pascalCase()}}Loaded();
}
''';

  static const _providerPage = '''
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../notifiers/{{feature_name.snakeCase()}}_notifier.dart';
import '{{feature_name.snakeCase()}}_view.dart';

class {{feature_name.pascalCase()}}Page extends StatelessWidget {
  const {{feature_name.pascalCase()}}Page({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => {{feature_name.pascalCase()}}Notifier()..init(),
      child: const {{feature_name.pascalCase()}}View(),
    );
  }
}
''';

  static const _providerView = '''
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/{{feature_name.snakeCase()}}_state.dart';
import '../notifiers/{{feature_name.snakeCase()}}_notifier.dart';

class {{feature_name.pascalCase()}}View extends StatelessWidget {
  const {{feature_name.pascalCase()}}View({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = context.watch<{{feature_name.pascalCase()}}Notifier>().state;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '{{feature_name.titleCase()}}',
          style: theme.textTheme.titleLarge,
        ),
      ),
      body: switch (state) {
        {{feature_name.pascalCase()}}Initial() => const Center(
            child: CircularProgressIndicator(),
          ),
        {{feature_name.pascalCase()}}Loaded() => const Center(
            child: Text('{{feature_name.titleCase()}}'),
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
        TemplateFile(_p('{{feature_name.snakeCase()}}.dart'), _riverpodBarrel),
        TemplateFile(_p('providers/{{feature_name.snakeCase()}}_provider.dart'), _riverpodProvider),
        TemplateFile(_p('models/{{feature_name.snakeCase()}}_state.dart'), _riverpodState),
        TemplateFile(_p('view/{{feature_name.snakeCase()}}_page.dart'), _riverpodPage),
        TemplateFile(_p('view/{{feature_name.snakeCase()}}_view.dart'), _riverpodView),
      ];

  static const _riverpodBarrel = '''
export 'providers/{{feature_name.snakeCase()}}_provider.dart';
export 'models/{{feature_name.snakeCase()}}_state.dart';
export 'view/{{feature_name.snakeCase()}}_page.dart';
''';

  static const _riverpodProvider = '''
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/{{feature_name.snakeCase()}}_state.dart';

final {{feature_name.camelCase()}}Provider =
    NotifierProvider<{{feature_name.pascalCase()}}Notifier, {{feature_name.pascalCase()}}State>(
  {{feature_name.pascalCase()}}Notifier.new,
);

class {{feature_name.pascalCase()}}Notifier extends Notifier<{{feature_name.pascalCase()}}State> {
  @override
  {{feature_name.pascalCase()}}State build() => const {{feature_name.pascalCase()}}State.initial();

  void init() {
    state = const {{feature_name.pascalCase()}}State.loaded();
  }
}
''';

  static const _riverpodState = '''
sealed class {{feature_name.pascalCase()}}State {
  const {{feature_name.pascalCase()}}State();

  const factory {{feature_name.pascalCase()}}State.initial() = {{feature_name.pascalCase()}}Initial;
  const factory {{feature_name.pascalCase()}}State.loaded() = {{feature_name.pascalCase()}}Loaded;
}

final class {{feature_name.pascalCase()}}Initial extends {{feature_name.pascalCase()}}State {
  const {{feature_name.pascalCase()}}Initial();
}

final class {{feature_name.pascalCase()}}Loaded extends {{feature_name.pascalCase()}}State {
  const {{feature_name.pascalCase()}}Loaded();
}
''';

  static const _riverpodPage = '''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/{{feature_name.snakeCase()}}_provider.dart';
import '{{feature_name.snakeCase()}}_view.dart';

class {{feature_name.pascalCase()}}Page extends ConsumerStatefulWidget {
  const {{feature_name.pascalCase()}}Page({super.key});

  @override
  ConsumerState<{{feature_name.pascalCase()}}Page> createState() => _{{feature_name.pascalCase()}}PageState();
}

class _{{feature_name.pascalCase()}}PageState extends ConsumerState<{{feature_name.pascalCase()}}Page> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read({{feature_name.camelCase()}}Provider.notifier).init());
  }

  @override
  Widget build(BuildContext context) {
    return const {{feature_name.pascalCase()}}View();
  }
}
''';

  static const _riverpodView = '''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/{{feature_name.snakeCase()}}_state.dart';
import '../providers/{{feature_name.snakeCase()}}_provider.dart';

class {{feature_name.pascalCase()}}View extends ConsumerWidget {
  const {{feature_name.pascalCase()}}View({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch({{feature_name.camelCase()}}Provider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '{{feature_name.titleCase()}}',
          style: theme.textTheme.titleLarge,
        ),
      ),
      body: switch (state) {
        {{feature_name.pascalCase()}}Initial() => const Center(
            child: CircularProgressIndicator(),
          ),
        {{feature_name.pascalCase()}}Loaded() => const Center(
            child: Text('{{feature_name.titleCase()}}'),
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
        TemplateFile(_p('{{feature_name.snakeCase()}}.dart'), _getxBarrel),
        TemplateFile(_p('controllers/{{feature_name.snakeCase()}}_controller.dart'), _getxController),
        TemplateFile(_p('bindings/{{feature_name.snakeCase()}}_binding.dart'), _getxBinding),
        TemplateFile(_p('view/{{feature_name.snakeCase()}}_page.dart'), _getxPage),
        TemplateFile(_p('view/{{feature_name.snakeCase()}}_view.dart'), _getxView),
      ];

  static const _getxBarrel = '''
export 'controllers/{{feature_name.snakeCase()}}_controller.dart';
export 'bindings/{{feature_name.snakeCase()}}_binding.dart';
export 'view/{{feature_name.snakeCase()}}_page.dart';
''';

  static const _getxController = '''
import 'package:get/get.dart';

class {{feature_name.pascalCase()}}Controller extends GetxController {
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

  static const _getxBinding = '''
import 'package:get/get.dart';

import '../controllers/{{feature_name.snakeCase()}}_controller.dart';

class {{feature_name.pascalCase()}}Binding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<{{feature_name.pascalCase()}}Controller>({{feature_name.pascalCase()}}Controller.new);
  }
}
''';

  static const _getxPage = '''
import 'package:flutter/material.dart';

import '{{feature_name.snakeCase()}}_view.dart';

class {{feature_name.pascalCase()}}Page extends StatelessWidget {
  const {{feature_name.pascalCase()}}Page({super.key});

  @override
  Widget build(BuildContext context) {
    return const {{feature_name.pascalCase()}}View();
  }
}
''';

  static const _getxView = '''
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/{{feature_name.snakeCase()}}_controller.dart';

class {{feature_name.pascalCase()}}View extends GetView<{{feature_name.pascalCase()}}Controller> {
  const {{feature_name.pascalCase()}}View({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '{{feature_name.titleCase()}}',
          style: theme.textTheme.titleLarge,
        ),
      ),
      body: Obx(() {
        if (!controller.isLoaded.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return const Center(
          child: Text('{{feature_name.titleCase()}}'),
        );
      }),
    );
  }
}
''';
}
