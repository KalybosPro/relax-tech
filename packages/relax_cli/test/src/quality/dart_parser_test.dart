import 'package:relax_cli/src/quality/analyzer/dart_parser.dart';
import 'package:test/test.dart';

void main() {
  final parser = DartParser();

  group('DartParser', () {
    test('extracts classes, supertypes, and method signatures', () {
      final parsed = parser.parse('''
class AuthController extends GetxController {
  Future<User> login(String email, String password) async {
    return repository.login(email, password);
  }
}
''');

      expect(parsed.classes, hasLength(1));
      final cls = parsed.classes.single;
      expect(cls.name, 'AuthController');
      expect(cls.superclass, 'GetxController');

      final method = cls.methods.single;
      expect(method.name, 'login');
      expect(method.isAsync, isTrue);
      expect(method.returnType, 'Future<User>');
      expect(method.params.map((p) => p.type), ['String', 'String']);
      expect(method.calls.map((c) => c.target), contains('login'));
      expect(method.calls.first.receiver, 'repository');
    });

    test('computes cyclomatic complexity from branch points', () {
      final parsed = parser.parse('''
class C {
  int f(int x) {
    if (x > 0 && x < 10) {
      for (var i = 0; i < x; i++) {
        x += i;
      }
    } else if (x < 0) {
      return -1;
    }
    return x > 5 ? 1 : 0;
  }
}
''');
      // if, &&, for, else-if, ?: => 5 branches + 1 baseline = 6.
      expect(parsed.classes.single.methods.single.cyclomaticComplexity, 6);
    });

    test('captures referenced names including tear-offs', () {
      final parsed = parser.parse('''
class W {
  void build() {
    button(onPressed: _submit);
  }
  void _submit() {}
  void _unused() {}
}
''');
      expect(parsed.referencedNames, contains('_submit'));
      expect(parsed.referencedNames, isNot(contains('_unused')));
    });

    test('records import show clauses', () {
      final parsed = parser.parse('''
import 'package:flutter/material.dart' show Widget, BuildContext;
import 'a.dart';
import 'a.dart';
''');
      expect(parsed.importDirectives, hasLength(3));
      expect(parsed.importDirectives.first.shownNames, [
        'Widget',
        'BuildContext',
      ]);
    });
  });
}
