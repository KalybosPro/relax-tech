import 'package:mason/mason.dart';

/// Template for generating a RelaxORM model class with `@RelaxTable` annotation.
///
/// Usage: `relax generate model user_profile`
///
/// Generates:
/// ```
/// lib/models/user_profile/
/// └── user_profile.dart
/// ```
abstract final class ModelTemplate {
  static List<TemplateFile> get files => [
        TemplateFile(
          '{{model_name.snakeCase()}}.dart',
          _modelFile,
        ),
      ];

  static const _modelFile = '''
import 'package:relax_orm/relax_orm.dart';

part '{{model_name.snakeCase()}}.g.dart';

@RelaxTable()
class {{model_name.pascalCase()}} {
  @PrimaryKey()
  final String id;

  final String name;

  final DateTime createdAt;

  final DateTime updatedAt;

  {{model_name.pascalCase()}}({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });
}
''';
}
