import 'package:mason/mason.dart';

/// Full Clean-Architecture feature templates for all architectures.
///
/// Every feature is a vertical slice:
///
/// ```
/// <feature>/
/// ├── data/         datasources, models, mappers, repository impl
/// ├── domain/       entities, repository contract, use cases, failure
/// ├── presentation/ pages, states, controller (per state manager)
/// └── routes.dart
/// ```
///
/// The `data/` and `domain/` layers are identical across state managers; only
/// `presentation/` (and the barrel) differ.
///
/// Variables: `feature_name` (snake_case), `route_name`, `route_path`.
/// Files are generated relative to `lib/features/`.
abstract final class FeatureTemplate {
  static String _p(String path) => '{{feature_name.snakeCase()}}/$path';

  /// Data + domain layers + shared state — identical for every architecture.
  static List<TemplateFile> _shared() => [
    TemplateFile(
      _p('domain/entities/{{feature_name.snakeCase()}}_entity.dart'),
      _entity,
    ),
    TemplateFile(
      _p('domain/repositories/{{feature_name.snakeCase()}}_repository.dart'),
      _repository,
    ),
    TemplateFile(
      _p('domain/usecases/get_{{feature_name.snakeCase()}}_usecase.dart'),
      _useCase,
    ),
    TemplateFile(
      _p('domain/failures/{{feature_name.snakeCase()}}_failure.dart'),
      _failure,
    ),
    TemplateFile(
      _p('data/models/{{feature_name.snakeCase()}}_model.dart'),
      _model,
    ),
    TemplateFile(
      _p('data/mappers/{{feature_name.snakeCase()}}_mapper.dart'),
      _mapper,
    ),
    TemplateFile(
      _p('data/datasources/{{feature_name.snakeCase()}}_remote_datasource.dart'),
      _remoteDatasource,
    ),
    TemplateFile(
      _p('data/datasources/{{feature_name.snakeCase()}}_local_datasource.dart'),
      _localDatasource,
    ),
    TemplateFile(
      _p('data/repositories/{{feature_name.snakeCase()}}_repository_impl.dart'),
      _repositoryImpl,
    ),
    TemplateFile(
      _p('presentation/states/{{feature_name.snakeCase()}}_state.dart'),
      _state,
    ),
  ];

  // ═══════════════════════════════════════════════════════════════
  //  Shared data / domain
  // ═══════════════════════════════════════════════════════════════

  static const _entity = '''
/// Domain entity for the {{feature_name.titleCase()}} feature.
///
/// A pure business object — no JSON, Dio or database knowledge.
class {{feature_name.pascalCase()}}Entity {
  const {{feature_name.pascalCase()}}Entity({required this.id, required this.name});

  final String id;
  final String name;
}
''';

  static const _repository = '''
import '../entities/{{feature_name.snakeCase()}}_entity.dart';

/// Contract implemented in the data layer. The domain depends only on this.
abstract class {{feature_name.pascalCase()}}Repository {
  Future<List<{{feature_name.pascalCase()}}Entity>> getAll();
}
''';

  static const _useCase = '''
import '../entities/{{feature_name.snakeCase()}}_entity.dart';
import '../repositories/{{feature_name.snakeCase()}}_repository.dart';

/// Fetches all {{feature_name.titleCase()}} items.
///
/// One use case = one business action. Add [Create/Update/Delete] use cases as
/// the feature grows.
class Get{{feature_name.pascalCase()}}UseCase {
  const Get{{feature_name.pascalCase()}}UseCase(this._repository);

  final {{feature_name.pascalCase()}}Repository _repository;

  Future<List<{{feature_name.pascalCase()}}Entity>> call() => _repository.getAll();
}
''';

  static const _failure = '''
import '../../../../core/errors/errors.dart';

/// Feature-specific failure, alongside the shared [Failure]s in `core/errors`.
final class {{feature_name.pascalCase()}}Failure extends Failure {
  const {{feature_name.pascalCase()}}Failure([
    super.message = '{{feature_name.titleCase()}} error',
  ]);
}
''';

  static const _model = '''
/// Data model mirroring the API / DB shape for {{feature_name.titleCase()}}.
///
/// Kept separate from the domain entity; convert with the mapper.
class {{feature_name.pascalCase()}}Model {
  const {{feature_name.pascalCase()}}Model({required this.id, required this.name});

  factory {{feature_name.pascalCase()}}Model.fromJson(Map<String, dynamic> json) =>
      {{feature_name.pascalCase()}}Model(
        id: json['id'].toString(),
        name: (json['name'] ?? '').toString(),
      );

  final String id;
  final String name;

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}
''';

  static const _mapper = '''
import '../../domain/entities/{{feature_name.snakeCase()}}_entity.dart';
import '../models/{{feature_name.snakeCase()}}_model.dart';

/// Converts between the data [{{feature_name.pascalCase()}}Model] and the domain
/// [{{feature_name.pascalCase()}}Entity].
extension {{feature_name.pascalCase()}}ModelMapper on {{feature_name.pascalCase()}}Model {
  {{feature_name.pascalCase()}}Entity toEntity() =>
      {{feature_name.pascalCase()}}Entity(id: id, name: name);
}

extension {{feature_name.pascalCase()}}EntityMapper on {{feature_name.pascalCase()}}Entity {
  {{feature_name.pascalCase()}}Model toModel() =>
      {{feature_name.pascalCase()}}Model(id: id, name: name);
}
''';

  static const _remoteDatasource = '''
import '../../../../core/network/network.dart';
import '../models/{{feature_name.snakeCase()}}_model.dart';

/// Talks to the backend for {{feature_name.titleCase()}} data.
class {{feature_name.pascalCase()}}RemoteDatasource {
  const {{feature_name.pascalCase()}}RemoteDatasource(this._api);

  final ApiClient _api;

  Future<List<{{feature_name.pascalCase()}}Model>> getAll() async {
    final res = await _api.get<List<dynamic>>('/{{feature_name.snakeCase()}}');
    final data = res.data ?? const <dynamic>[];
    return data
        .map(
          (e) => {{feature_name.pascalCase()}}Model.fromJson(
            e as Map<String, dynamic>,
          ),
        )
        .toList();
  }
}
''';

  static const _localDatasource = '''
import '../models/{{feature_name.snakeCase()}}_model.dart';

/// Caches {{feature_name.titleCase()}} data locally. Swap the in-memory list for
/// RelaxORM / drift when you need real persistence.
class {{feature_name.pascalCase()}}LocalDatasource {
  final List<{{feature_name.pascalCase()}}Model> _cache = [];

  Future<List<{{feature_name.pascalCase()}}Model>> getAll() async => _cache;

  Future<void> cache(List<{{feature_name.pascalCase()}}Model> items) async {
    _cache
      ..clear()
      ..addAll(items);
  }
}
''';

  static const _repositoryImpl = '''
import '../../domain/entities/{{feature_name.snakeCase()}}_entity.dart';
import '../../domain/repositories/{{feature_name.snakeCase()}}_repository.dart';
import '../datasources/{{feature_name.snakeCase()}}_local_datasource.dart';
import '../datasources/{{feature_name.snakeCase()}}_remote_datasource.dart';
import '../mappers/{{feature_name.snakeCase()}}_mapper.dart';

/// Coordinates the remote + local datasources and maps models to entities.
class {{feature_name.pascalCase()}}RepositoryImpl
    implements {{feature_name.pascalCase()}}Repository {
  {{feature_name.pascalCase()}}RepositoryImpl({
    required {{feature_name.pascalCase()}}RemoteDatasource remote,
    required {{feature_name.pascalCase()}}LocalDatasource local,
  })  : _remote = remote,
        _local = local;

  final {{feature_name.pascalCase()}}RemoteDatasource _remote;
  final {{feature_name.pascalCase()}}LocalDatasource _local;

  @override
  Future<List<{{feature_name.pascalCase()}}Entity>> getAll() async {
    final models = await _remote.getAll();
    await _local.cache(models);
    return models.map((m) => m.toEntity()).toList();
  }
}
''';

  static const _state = '''
import '../../domain/entities/{{feature_name.snakeCase()}}_entity.dart';

export '../../domain/entities/{{feature_name.snakeCase()}}_entity.dart';

/// Immutable UI state for the {{feature_name.titleCase()}} feature.
sealed class {{feature_name.pascalCase()}}State {
  const {{feature_name.pascalCase()}}State();
}

final class {{feature_name.pascalCase()}}Loading extends {{feature_name.pascalCase()}}State {
  const {{feature_name.pascalCase()}}Loading();
}

final class {{feature_name.pascalCase()}}Loaded extends {{feature_name.pascalCase()}}State {
  const {{feature_name.pascalCase()}}Loaded(this.items);
  final List<{{feature_name.pascalCase()}}Entity> items;
}

final class {{feature_name.pascalCase()}}Error extends {{feature_name.pascalCase()}}State {
  const {{feature_name.pascalCase()}}Error(this.message);
  final String message;
}
''';

  // ═══════════════════════════════════════════════════════════════
  //  BLOC (Cubit)
  // ═══════════════════════════════════════════════════════════════

  static List<TemplateFile> get bloc => [
    ..._shared(),
    TemplateFile(_p('{{feature_name.snakeCase()}}.dart'), _blocBarrel),
    TemplateFile(
      _p('presentation/controllers/{{feature_name.snakeCase()}}_cubit.dart'),
      _blocCubit,
    ),
    TemplateFile(
      _p('presentation/pages/{{feature_name.snakeCase()}}_page.dart'),
      _blocPage,
    ),
    TemplateFile(
      _p('presentation/pages/{{feature_name.snakeCase()}}_view.dart'),
      _blocView,
    ),
    TemplateFile(_p('routes.dart'), _goRouterRoutes),
  ];

  static const _blocBarrel = '''
export 'domain/entities/{{feature_name.snakeCase()}}_entity.dart';
export 'presentation/controllers/{{feature_name.snakeCase()}}_cubit.dart';
export 'presentation/pages/{{feature_name.snakeCase()}}_page.dart';
export 'presentation/states/{{feature_name.snakeCase()}}_state.dart';
''';

  static const _blocCubit = '''
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/core.dart';
import '../../data/datasources/{{feature_name.snakeCase()}}_local_datasource.dart';
import '../../data/datasources/{{feature_name.snakeCase()}}_remote_datasource.dart';
import '../../data/repositories/{{feature_name.snakeCase()}}_repository_impl.dart';
import '../../domain/usecases/get_{{feature_name.snakeCase()}}_usecase.dart';
import '../states/{{feature_name.snakeCase()}}_state.dart';

/// Cubit driving the {{feature_name.titleCase()}} feature.
class {{feature_name.pascalCase()}}Cubit extends Cubit<{{feature_name.pascalCase()}}State> {
  {{feature_name.pascalCase()}}Cubit({Get{{feature_name.pascalCase()}}UseCase? getAll})
      : _getAll = getAll ??
            Get{{feature_name.pascalCase()}}UseCase(
              {{feature_name.pascalCase()}}RepositoryImpl(
                remote: {{feature_name.pascalCase()}}RemoteDatasource(getIt<ApiClient>()),
                local: {{feature_name.pascalCase()}}LocalDatasource(),
              ),
            ),
        super(const {{feature_name.pascalCase()}}Loading());

  final Get{{feature_name.pascalCase()}}UseCase _getAll;

  Future<void> load() async {
    emit(const {{feature_name.pascalCase()}}Loading());
    try {
      final items = await _getAll();
      emit({{feature_name.pascalCase()}}Loaded(items));
    } catch (e) {
      emit({{feature_name.pascalCase()}}Error(ErrorMapper.map(e).message));
    }
  }
}
''';

  static const _blocPage = '''
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../controllers/{{feature_name.snakeCase()}}_cubit.dart';
import '{{feature_name.snakeCase()}}_view.dart';

class {{feature_name.pascalCase()}}Page extends StatelessWidget {
  const {{feature_name.pascalCase()}}Page({super.key});

  /// Route name used with `context.goNamed({{feature_name.pascalCase()}}Page.routeName)`.
  static const routeName = '{{route_name}}';

  /// URL path registered in the app router.
  static const routePath = '{{{route_path}}}';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => {{feature_name.pascalCase()}}Cubit()..load(),
      child: const {{feature_name.pascalCase()}}View(),
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

class {{feature_name.pascalCase()}}View extends StatelessWidget {
  const {{feature_name.pascalCase()}}View({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('{{feature_name.titleCase()}}')),
      body: BlocBuilder<{{feature_name.pascalCase()}}Cubit, {{feature_name.pascalCase()}}State>(
        builder: (context, state) => switch (state) {
          {{feature_name.pascalCase()}}Loading() => const Loading(),
          {{feature_name.pascalCase()}}Error(:final message) => ErrorView(
              message: message,
              onRetry: () => context.read<{{feature_name.pascalCase()}}Cubit>().load(),
            ),
          {{feature_name.pascalCase()}}Loaded(:final items) => _List(items: items),
        },
      ),
    );
  }
}

class _List extends StatelessWidget {
  const _List({required this.items});

  final List<{{feature_name.pascalCase()}}Entity> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('No items yet.'));
    }
    return ListView(
      children: [
        for (final item in items) ListTile(title: Text(item.name)),
      ],
    );
  }
}
''';

  // ═══════════════════════════════════════════════════════════════
  //  PROVIDER
  // ═══════════════════════════════════════════════════════════════

  static List<TemplateFile> get provider => [
    ..._shared(),
    TemplateFile(_p('{{feature_name.snakeCase()}}.dart'), _providerBarrel),
    TemplateFile(
      _p('presentation/controllers/{{feature_name.snakeCase()}}_notifier.dart'),
      _providerNotifier,
    ),
    TemplateFile(
      _p('presentation/pages/{{feature_name.snakeCase()}}_page.dart'),
      _providerPage,
    ),
    TemplateFile(
      _p('presentation/pages/{{feature_name.snakeCase()}}_view.dart'),
      _providerView,
    ),
    TemplateFile(_p('routes.dart'), _goRouterRoutes),
  ];

  static const _providerBarrel = '''
export 'domain/entities/{{feature_name.snakeCase()}}_entity.dart';
export 'presentation/controllers/{{feature_name.snakeCase()}}_notifier.dart';
export 'presentation/pages/{{feature_name.snakeCase()}}_page.dart';
export 'presentation/states/{{feature_name.snakeCase()}}_state.dart';
''';

  static const _providerNotifier = '''
import 'package:flutter/foundation.dart';

import '../../../../core/core.dart';
import '../../data/datasources/{{feature_name.snakeCase()}}_local_datasource.dart';
import '../../data/datasources/{{feature_name.snakeCase()}}_remote_datasource.dart';
import '../../data/repositories/{{feature_name.snakeCase()}}_repository_impl.dart';
import '../../domain/usecases/get_{{feature_name.snakeCase()}}_usecase.dart';
import '../states/{{feature_name.snakeCase()}}_state.dart';

/// [ChangeNotifier] driving the {{feature_name.titleCase()}} feature.
class {{feature_name.pascalCase()}}Notifier extends ChangeNotifier {
  {{feature_name.pascalCase()}}Notifier({Get{{feature_name.pascalCase()}}UseCase? getAll})
      : _getAll = getAll ??
            Get{{feature_name.pascalCase()}}UseCase(
              {{feature_name.pascalCase()}}RepositoryImpl(
                remote: {{feature_name.pascalCase()}}RemoteDatasource(getIt<ApiClient>()),
                local: {{feature_name.pascalCase()}}LocalDatasource(),
              ),
            );

  final Get{{feature_name.pascalCase()}}UseCase _getAll;

  {{feature_name.pascalCase()}}State _state = const {{feature_name.pascalCase()}}Loading();
  {{feature_name.pascalCase()}}State get state => _state;

  Future<void> load() async {
    _state = const {{feature_name.pascalCase()}}Loading();
    notifyListeners();
    try {
      final items = await _getAll();
      _state = {{feature_name.pascalCase()}}Loaded(items);
    } catch (e) {
      _state = {{feature_name.pascalCase()}}Error(ErrorMapper.map(e).message);
    }
    notifyListeners();
  }
}
''';

  static const _providerPage = '''
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/{{feature_name.snakeCase()}}_notifier.dart';
import '{{feature_name.snakeCase()}}_view.dart';

class {{feature_name.pascalCase()}}Page extends StatelessWidget {
  const {{feature_name.pascalCase()}}Page({super.key});

  /// Route name used with `context.goNamed({{feature_name.pascalCase()}}Page.routeName)`.
  static const routeName = '{{route_name}}';

  /// URL path registered in the app router.
  static const routePath = '{{{route_path}}}';

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => {{feature_name.pascalCase()}}Notifier()..load(),
      child: const {{feature_name.pascalCase()}}View(),
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

class {{feature_name.pascalCase()}}View extends StatelessWidget {
  const {{feature_name.pascalCase()}}View({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<{{feature_name.pascalCase()}}Notifier>();
    return Scaffold(
      appBar: AppBar(title: const Text('{{feature_name.titleCase()}}')),
      body: switch (notifier.state) {
        {{feature_name.pascalCase()}}Loading() => const Loading(),
        {{feature_name.pascalCase()}}Error(:final message) => ErrorView(
            message: message,
            onRetry: notifier.load,
          ),
        {{feature_name.pascalCase()}}Loaded(:final items) => _List(items: items),
      },
    );
  }
}

class _List extends StatelessWidget {
  const _List({required this.items});

  final List<{{feature_name.pascalCase()}}Entity> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('No items yet.'));
    }
    return ListView(
      children: [
        for (final item in items) ListTile(title: Text(item.name)),
      ],
    );
  }
}
''';

  // ═══════════════════════════════════════════════════════════════
  //  RIVERPOD
  // ═══════════════════════════════════════════════════════════════

  static List<TemplateFile> get riverpod => [
    ..._shared(),
    TemplateFile(_p('{{feature_name.snakeCase()}}.dart'), _riverpodBarrel),
    TemplateFile(
      _p('presentation/controllers/{{feature_name.snakeCase()}}_notifier.dart'),
      _riverpodNotifier,
    ),
    TemplateFile(
      _p('presentation/pages/{{feature_name.snakeCase()}}_page.dart'),
      _riverpodPage,
    ),
    TemplateFile(
      _p('presentation/pages/{{feature_name.snakeCase()}}_view.dart'),
      _riverpodView,
    ),
    TemplateFile(_p('routes.dart'), _goRouterRoutes),
  ];

  static const _riverpodBarrel = '''
export 'domain/entities/{{feature_name.snakeCase()}}_entity.dart';
export 'presentation/controllers/{{feature_name.snakeCase()}}_notifier.dart';
export 'presentation/pages/{{feature_name.snakeCase()}}_page.dart';
export 'presentation/states/{{feature_name.snakeCase()}}_state.dart';
''';

  static const _riverpodNotifier = '''
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/core.dart';
import '../../data/datasources/{{feature_name.snakeCase()}}_local_datasource.dart';
import '../../data/datasources/{{feature_name.snakeCase()}}_remote_datasource.dart';
import '../../data/repositories/{{feature_name.snakeCase()}}_repository_impl.dart';
import '../../domain/usecases/get_{{feature_name.snakeCase()}}_usecase.dart';
import '../states/{{feature_name.snakeCase()}}_state.dart';

final {{feature_name.camelCase()}}Provider =
    NotifierProvider<{{feature_name.pascalCase()}}Notifier, {{feature_name.pascalCase()}}State>(
  {{feature_name.pascalCase()}}Notifier.new,
);

/// [Notifier] driving the {{feature_name.titleCase()}} feature.
class {{feature_name.pascalCase()}}Notifier extends Notifier<{{feature_name.pascalCase()}}State> {
  late final Get{{feature_name.pascalCase()}}UseCase _getAll;

  @override
  {{feature_name.pascalCase()}}State build() {
    _getAll = Get{{feature_name.pascalCase()}}UseCase(
      {{feature_name.pascalCase()}}RepositoryImpl(
        remote: {{feature_name.pascalCase()}}RemoteDatasource(getIt<ApiClient>()),
        local: {{feature_name.pascalCase()}}LocalDatasource(),
      ),
    );
    Future.microtask(load);
    return const {{feature_name.pascalCase()}}Loading();
  }

  Future<void> load() async {
    state = const {{feature_name.pascalCase()}}Loading();
    try {
      final items = await _getAll();
      state = {{feature_name.pascalCase()}}Loaded(items);
    } catch (e) {
      state = {{feature_name.pascalCase()}}Error(ErrorMapper.map(e).message);
    }
  }
}
''';

  static const _riverpodPage = '''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '{{feature_name.snakeCase()}}_view.dart';

class {{feature_name.pascalCase()}}Page extends ConsumerWidget {
  const {{feature_name.pascalCase()}}Page({super.key});

  /// Route name used with `context.goNamed({{feature_name.pascalCase()}}Page.routeName)`.
  static const routeName = '{{route_name}}';

  /// URL path registered in the app router.
  static const routePath = '{{{route_path}}}';

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      const {{feature_name.pascalCase()}}View();
}
''';

  static const _riverpodView = '''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/core.dart';
import '../controllers/{{feature_name.snakeCase()}}_notifier.dart';
import '../states/{{feature_name.snakeCase()}}_state.dart';

class {{feature_name.pascalCase()}}View extends ConsumerWidget {
  const {{feature_name.pascalCase()}}View({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch({{feature_name.camelCase()}}Provider);
    return Scaffold(
      appBar: AppBar(title: const Text('{{feature_name.titleCase()}}')),
      body: switch (state) {
        {{feature_name.pascalCase()}}Loading() => const Loading(),
        {{feature_name.pascalCase()}}Error(:final message) => ErrorView(
            message: message,
            onRetry: () =>
                ref.read({{feature_name.camelCase()}}Provider.notifier).load(),
          ),
        {{feature_name.pascalCase()}}Loaded(:final items) => _List(items: items),
      },
    );
  }
}

class _List extends StatelessWidget {
  const _List({required this.items});

  final List<{{feature_name.pascalCase()}}Entity> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('No items yet.'));
    }
    return ListView(
      children: [
        for (final item in items) ListTile(title: Text(item.name)),
      ],
    );
  }
}
''';

  // ═══════════════════════════════════════════════════════════════
  //  GETX
  // ═══════════════════════════════════════════════════════════════

  static List<TemplateFile> get getx => [
    ..._shared(),
    TemplateFile(_p('{{feature_name.snakeCase()}}.dart'), _getxBarrel),
    TemplateFile(
      _p('presentation/controllers/{{feature_name.snakeCase()}}_controller.dart'),
      _getxController,
    ),
    TemplateFile(
      _p('presentation/controllers/{{feature_name.snakeCase()}}_binding.dart'),
      _getxBinding,
    ),
    TemplateFile(
      _p('presentation/pages/{{feature_name.snakeCase()}}_page.dart'),
      _getxPage,
    ),
    TemplateFile(
      _p('presentation/pages/{{feature_name.snakeCase()}}_view.dart'),
      _getxView,
    ),
    TemplateFile(_p('routes.dart'), _getxRoutes),
  ];

  static const _getxBarrel = '''
export 'domain/entities/{{feature_name.snakeCase()}}_entity.dart';
export 'presentation/controllers/{{feature_name.snakeCase()}}_binding.dart';
export 'presentation/controllers/{{feature_name.snakeCase()}}_controller.dart';
export 'presentation/pages/{{feature_name.snakeCase()}}_page.dart';
export 'presentation/states/{{feature_name.snakeCase()}}_state.dart';
''';

  static const _getxController = '''
import 'package:get/get.dart';

import '../../../../core/core.dart';
import '../../data/datasources/{{feature_name.snakeCase()}}_local_datasource.dart';
import '../../data/datasources/{{feature_name.snakeCase()}}_remote_datasource.dart';
import '../../data/repositories/{{feature_name.snakeCase()}}_repository_impl.dart';
import '../../domain/usecases/get_{{feature_name.snakeCase()}}_usecase.dart';
import '../states/{{feature_name.snakeCase()}}_state.dart';

/// GetX controller driving the {{feature_name.titleCase()}} feature.
class {{feature_name.pascalCase()}}Controller extends GetxController {
  {{feature_name.pascalCase()}}Controller({Get{{feature_name.pascalCase()}}UseCase? getAll})
      : _getAll = getAll ??
            Get{{feature_name.pascalCase()}}UseCase(
              {{feature_name.pascalCase()}}RepositoryImpl(
                remote: {{feature_name.pascalCase()}}RemoteDatasource(getIt<ApiClient>()),
                local: {{feature_name.pascalCase()}}LocalDatasource(),
              ),
            );

  final Get{{feature_name.pascalCase()}}UseCase _getAll;

  final Rx<{{feature_name.pascalCase()}}State> state =
      Rx<{{feature_name.pascalCase()}}State>(const {{feature_name.pascalCase()}}Loading());

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    state.value = const {{feature_name.pascalCase()}}Loading();
    try {
      final items = await _getAll();
      state.value = {{feature_name.pascalCase()}}Loaded(items);
    } catch (e) {
      state.value = {{feature_name.pascalCase()}}Error(ErrorMapper.map(e).message);
    }
  }
}
''';

  static const _getxBinding = '''
import 'package:get/get.dart';

import '{{feature_name.snakeCase()}}_controller.dart';

class {{feature_name.pascalCase()}}Binding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<{{feature_name.pascalCase()}}Controller>(
      {{feature_name.pascalCase()}}Controller.new,
    );
  }
}
''';

  static const _getxPage = '''
import 'package:flutter/material.dart';

import '{{feature_name.snakeCase()}}_view.dart';

class {{feature_name.pascalCase()}}Page extends StatelessWidget {
  const {{feature_name.pascalCase()}}Page({super.key});

  /// Route name used with `Get.toNamed({{feature_name.pascalCase()}}Page.routeName)`.
  static const routeName = '{{route_name}}';

  /// Route path registered in [appPages].
  static const routePath = '{{{route_path}}}';

  @override
  Widget build(BuildContext context) => const {{feature_name.pascalCase()}}View();
}
''';

  static const _getxView = '''
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/core.dart';
import '../controllers/{{feature_name.snakeCase()}}_controller.dart';
import '../states/{{feature_name.snakeCase()}}_state.dart';

class {{feature_name.pascalCase()}}View extends GetView<{{feature_name.pascalCase()}}Controller> {
  const {{feature_name.pascalCase()}}View({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('{{feature_name.titleCase()}}')),
      body: Obx(
        () => switch (controller.state.value) {
          {{feature_name.pascalCase()}}Loading() => const Loading(),
          {{feature_name.pascalCase()}}Error(:final message) => ErrorView(
              message: message,
              onRetry: controller.load,
            ),
          {{feature_name.pascalCase()}}Loaded(:final items) => _List(items: items),
        },
      ),
    );
  }
}

class _List extends StatelessWidget {
  const _List({required this.items});

  final List<{{feature_name.pascalCase()}}Entity> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('No items yet.'));
    }
    return ListView(
      children: [
        for (final item in items) ListTile(title: Text(item.name)),
      ],
    );
  }
}
''';

  // ═══════════════════════════════════════════════════════════════
  //  Feature-owned routes
  // ═══════════════════════════════════════════════════════════════

  /// go_router route exposed by the feature. The app router aggregates feature
  /// pages through the `features/features.dart` barrel; this file gives the
  /// feature ownership of its own route object should you prefer that style.
  static const _goRouterRoutes = '''
import 'package:go_router/go_router.dart';

import 'presentation/pages/{{feature_name.snakeCase()}}_page.dart';

/// Route for the {{feature_name.titleCase()}} feature.
GoRoute get {{feature_name.camelCase()}}Route => GoRoute(
      path: {{feature_name.pascalCase()}}Page.routePath,
      name: {{feature_name.pascalCase()}}Page.routeName,
      builder: (context, state) => const {{feature_name.pascalCase()}}Page(),
    );
''';

  static const _getxRoutes = '''
import 'package:get/get.dart';

import 'presentation/controllers/{{feature_name.snakeCase()}}_binding.dart';
import 'presentation/pages/{{feature_name.snakeCase()}}_page.dart';

/// GetPage for the {{feature_name.titleCase()}} feature.
GetPage<dynamic> get {{feature_name.camelCase()}}Page => GetPage(
      name: {{feature_name.pascalCase()}}Page.routePath,
      page: () => const {{feature_name.pascalCase()}}Page(),
      binding: {{feature_name.pascalCase()}}Binding(),
    );
''';
}
