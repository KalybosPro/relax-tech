import '../models/quality_models.dart';

/// A scenario blueprint (name + kind) before setup/assertion code is filled in.
class ScenarioSpec {
  const ScenarioSpec(this.name, this.kind);

  final String name;

  /// One of TestScenario's kinds: success, invalid_input, network_error,
  /// server_error, timeout, null_response.
  final String kind;
}

/// Maps a function's return type to the default set of test scenarios, per the
/// specification's scenario table.
class ScenarioLibrary {
  List<ScenarioSpec> forReturnType(String returnType) {
    final inner = _futureInnerType(returnType);

    if (inner == 'void' || inner.isEmpty) {
      return const [
        ScenarioSpec('completes successfully', 'success'),
        ScenarioSpec('throws on network error', 'network_error'),
        ScenarioSpec('throws on server error', 'server_error'),
        ScenarioSpec('throws on timeout', 'timeout'),
      ];
    }

    if (inner == 'bool') {
      return const [
        ScenarioSpec('returns true', 'success'),
        ScenarioSpec('returns false', 'success'),
        ScenarioSpec('throws on network error', 'network_error'),
        ScenarioSpec('throws on server error', 'server_error'),
      ];
    }

    if (_isList(inner)) {
      return const [
        ScenarioSpec('returns a non-empty list', 'success'),
        ScenarioSpec('returns an empty list', 'success'),
        ScenarioSpec('throws on network error', 'network_error'),
        ScenarioSpec('throws on server error', 'server_error'),
        ScenarioSpec('throws on timeout', 'timeout'),
      ];
    }

    // Object-returning (e.g. Future<User>) — the fullest set.
    return const [
      ScenarioSpec('returns the expected result', 'success'),
      ScenarioSpec('throws on invalid input', 'invalid_input'),
      ScenarioSpec('throws on network error', 'network_error'),
      ScenarioSpec('throws on server error', 'server_error'),
      ScenarioSpec('throws on timeout', 'timeout'),
    ];
  }

  /// Returns the inner type of `Future<T>`/`Stream<T>`, or the type itself.
  String _futureInnerType(String returnType) {
    final t = returnType.trim();
    for (final wrapper in ['Future', 'FutureOr', 'Stream']) {
      final prefix = '$wrapper<';
      if (t.startsWith(prefix) && t.endsWith('>')) {
        return t.substring(prefix.length, t.length - 1).trim();
      }
    }
    if (t == 'Future' || t == 'void') return 'void';
    return t;
  }

  bool _isList(String type) =>
      type.startsWith('List<') || type.startsWith('Iterable<');

  /// The bare element type used to name a fake: `List<User>` → `User`,
  /// `User` → `User`.
  static String elementType(String returnType) {
    final lib = ScenarioLibrary();
    var inner = lib._futureInnerType(returnType);
    if (lib._isList(inner)) {
      final open = inner.indexOf('<');
      inner = inner.substring(open + 1, inner.length - 1).trim();
    }
    return inner;
  }
}

/// Builds a [TestScenario] from a spec plus generated setup/assertion code.
TestScenario buildScenario(ScenarioSpec spec, String setup, String assertion) =>
    TestScenario(
      name: spec.name,
      kind: spec.kind,
      setup: setup,
      assertion: assertion,
    );
