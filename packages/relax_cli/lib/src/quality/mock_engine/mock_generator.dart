import '../analyzer/infra_types.dart';
import '../models/quality_models.dart';

/// Generates `mocktail`-based mock classes for a business function's
/// dependencies. mocktail is preferred over mockito because it needs no
/// `build_runner` code generation.
class MockGenerator {
  /// Returns the mock specs for the dependency types of [fn] that look like
  /// infrastructure (deduplicated by target type).
  List<MockSpec> specsFor(BusinessFunction fn) {
    final seen = <String>{};
    final specs = <MockSpec>[];
    for (final dep in fn.dependencies) {
      final type = InfraTypes.baseType(dep.type);
      if (type.isEmpty || !InfraTypes.isInfra(type)) continue;
      if (!seen.add(type)) continue;
      specs.add(MockSpec(targetClassName: type, mockClassName: 'Mock$type'));
    }
    return specs;
  }

  /// Renders a mock class declaration.
  String render(MockSpec spec) =>
      'class ${spec.mockClassName} extends Mock '
      'implements ${spec.targetClassName} {}';
}
