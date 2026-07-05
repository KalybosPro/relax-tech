import '../models/quality_models.dart';
import '../test_engine/scenario_library.dart';

/// Generates minimal `Fake` data objects for a function's return type, used by
/// mocktail's `registerFallbackValue` and as canned success responses.
///
/// Fakes carry no data — they exist so tests compile and reference a concrete
/// instance without depending on the real model's constructor. Deterministic by
/// design (no `Random`), for reproducible tests.
class FakeGenerator {
  static const Set<String> _primitives = {
    'void',
    'bool',
    'int',
    'double',
    'num',
    'String',
    'Object',
    'dynamic',
    'DateTime',
  };

  /// Returns the fake spec for the element type of [returnType], or `null` when
  /// the type is a primitive/collection that needs no fake.
  FakeSpec? specForReturnType(String returnType) {
    final element = ScenarioLibrary.elementType(returnType);
    if (element.isEmpty) return null;
    if (_primitives.contains(element)) return null;
    if (element.startsWith('List') || element.startsWith('Map')) return null;
    return FakeSpec(targetTypeName: element, fakeClassName: 'Fake$element');
  }

  /// Renders a fake class declaration.
  String render(FakeSpec spec) =>
      'class ${spec.fakeClassName} extends Fake '
      'implements ${spec.targetTypeName} {}';
}
