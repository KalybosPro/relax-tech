import 'package:relax_cli/relax_cli.dart';
import 'package:test/test.dart';

void main() {
  group('Architecture', () {
    test('has 4 supported architectures', () {
      expect(Architecture.values, hasLength(4));
    });

    test('bloc is the first option', () {
      expect(Architecture.values.first, Architecture.bloc);
    });

    test('each architecture has a label', () {
      for (final arch in Architecture.values) {
        expect(arch.label, isNotEmpty);
      }
    });

    test('labels are distinct', () {
      final labels = Architecture.values.map((a) => a.label).toSet();
      expect(labels, hasLength(Architecture.values.length));
    });
  });

  group('RelaxCommandRunner', () {
    test('can be instantiated', () {
      expect(RelaxCommandRunner.new, returnsNormally);
    });

    test('has create command', () {
      final runner = RelaxCommandRunner();
      expect(runner.commands.containsKey('create'), isTrue);
    });

    test('has version flag', () {
      final runner = RelaxCommandRunner();
      expect(runner.argParser.options.containsKey('version'), isTrue);
    });
  });

  group('version', () {
    test('is semantic version', () {
      expect(version, matches(RegExp(r'^\d+\.\d+\.\d+$')));
    });
  });
}
