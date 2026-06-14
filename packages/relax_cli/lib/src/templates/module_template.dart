import 'package:mason/mason.dart';

/// Module templates — generates a domain/data layer module.
///
/// Variable: `module_name` (snake_case).
/// Files are generated relative to `lib/`.
abstract final class ModuleTemplate {
  static String _p(String path) => '{{module_name.snakeCase()}}/$path';

  static List<TemplateFile> get files => [
    TemplateFile(_p('{{module_name.snakeCase()}}.dart'), _barrel),

    // ── Models ──────────────────────────────────────────────
    TemplateFile(_p('models/{{module_name.snakeCase()}}.dart'), _model),

    // ── Repository (abstract) ───────────────────────────────
    TemplateFile(
      _p('repositories/{{module_name.snakeCase()}}_repository.dart'),
      _repository,
    ),

    // ── Repository (implementation) ─────────────────────────
    TemplateFile(
      _p('repositories/{{module_name.snakeCase()}}_repository_impl.dart'),
      _repositoryImpl,
    ),

    // ── Data source ─────────────────────────────────────────
    TemplateFile(
      _p('data_sources/{{module_name.snakeCase()}}_data_source.dart'),
      _dataSource,
    ),
  ];

  static const _barrel = '''
export 'models/{{module_name.snakeCase()}}.dart';
export 'repositories/{{module_name.snakeCase()}}_repository.dart';
export 'repositories/{{module_name.snakeCase()}}_repository_impl.dart';
export 'data_sources/{{module_name.snakeCase()}}_data_source.dart';
''';

  static const _model = '''
import 'package:relax_orm/relax_orm.dart';

part '{{module_name.snakeCase()}}.g.dart';

@RelaxTable()
class {{module_name.pascalCase()}} {

  const {{module_name.pascalCase()}}({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  @PrimaryKey()
  final String id;

  final String name;

  final DateTime createdAt;

  final DateTime updatedAt;
}
''';

  static const _repository = '''
import '../models/{{module_name.snakeCase()}}.dart';

/// Abstract repository for [{{module_name.pascalCase()}}] entities.
abstract interface class {{module_name.pascalCase()}}Repository {
  Future<List<{{module_name.pascalCase()}}>> getAll();

  Future<{{module_name.pascalCase()}}?> getById(String id);

  Future<void> create({{module_name.pascalCase()}} item);

  Future<void> update({{module_name.pascalCase()}} item);

  Future<void> upsert({{module_name.pascalCase()}} item);

  Future<void> delete(String id);

  Stream<List<{{module_name.pascalCase()}}>> watchAll();
}
''';

  static const _repositoryImpl = '''
import '../data_sources/{{module_name.snakeCase()}}_data_source.dart';
import '../models/{{module_name.snakeCase()}}.dart';
import '{{module_name.snakeCase()}}_repository.dart';

class {{module_name.pascalCase()}}RepositoryImpl
    implements {{module_name.pascalCase()}}Repository {
  const {{module_name.pascalCase()}}RepositoryImpl({
    required {{module_name.pascalCase()}}DataSource dataSource,
  }) : _dataSource = dataSource;

  final {{module_name.pascalCase()}}DataSource _dataSource;

  @override
  Future<List<{{module_name.pascalCase()}}>> getAll() => _dataSource.getAll();

  @override
  Future<{{module_name.pascalCase()}}?> getById(String id) =>
      _dataSource.getById(id);

  @override
  Future<void> create({{module_name.pascalCase()}} item) =>
      _dataSource.create(item);

  @override
  Future<void> update({{module_name.pascalCase()}} item) =>
      _dataSource.update(item);

  @override
  Future<void> upsert({{module_name.pascalCase()}} item) =>
      _dataSource.upsert(item);

  @override
  Future<void> delete(String id) => _dataSource.delete(id);

  @override
  Stream<List<{{module_name.pascalCase()}}>> watchAll() =>
      _dataSource.watchAll();
}
''';

  static const _dataSource = '''
import 'package:relax_orm/relax_orm.dart';

import '../models/{{module_name.snakeCase()}}.dart';

/// Data source for [{{module_name.pascalCase()}}] backed by RelaxORM.
class {{module_name.pascalCase()}}DataSource {
  {{module_name.pascalCase()}}DataSource({required RelaxDB db})
      : _collection = db.collection<{{module_name.pascalCase()}}>();

  final Collection<{{module_name.pascalCase()}}> _collection;

  Future<List<{{module_name.pascalCase()}}>> getAll() => _collection.getAll();

  Future<{{module_name.pascalCase()}}?> getById(String id) =>
      _collection.get(id);

  Future<void> create({{module_name.pascalCase()}} item) =>
      _collection.add(item);

  Future<void> update({{module_name.pascalCase()}} item) =>
      _collection.update(item);

  Future<void> upsert({{module_name.pascalCase()}} item) =>
      _collection.upsert(item);

  Future<void> delete(String id) => _collection.delete(id);

  Stream<List<{{module_name.pascalCase()}}>> watchAll() =>
      _collection.watchAll();
}
''';
}
