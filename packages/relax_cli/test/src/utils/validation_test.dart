import 'package:relax_cli/src/utils/validation.dart';
import 'package:test/test.dart';

void main() {
  group('isValidDartName', () {
    test('accepts lowercase snake_case names', () {
      expect(isValidDartName('login'), isTrue);
      expect(isValidDartName('user_profile'), isTrue);
      expect(isValidDartName('a1'), isTrue);
    });

    test('rejects invalid names', () {
      expect(isValidDartName(''), isFalse);
      expect(isValidDartName('My-Feature'), isFalse);
      expect(isValidDartName('1abc'), isFalse);
      expect(isValidDartName('auth/login'), isFalse);
    });
  });

  group('parsePathSpec', () {
    test('returns name only when there is no separator', () {
      final spec = parsePathSpec('login');
      expect(spec.subPath, isEmpty);
      expect(spec.name, equals('login'));
    });

    test('splits a single-level path', () {
      final spec = parsePathSpec('auth/login');
      expect(spec.subPath, equals('auth'));
      expect(spec.name, equals('login'));
    });

    test('supports arbitrary depth', () {
      final spec = parsePathSpec('a/b/c/login');
      expect(spec.subPath, equals('a/b/c'));
      expect(spec.name, equals('login'));
    });

    test('normalizes backslashes and drops empty segments', () {
      final spec = parsePathSpec(r'auth\login');
      expect(spec.subPath, equals('auth'));
      expect(spec.name, equals('login'));

      final trailing = parsePathSpec('auth/login/');
      expect(trailing.subPath, equals('auth'));
      expect(trailing.name, equals('login'));
    });
  });

  group('isValidPathSpec', () {
    test('accepts single names and valid paths', () {
      expect(isValidPathSpec('login'), isTrue);
      expect(isValidPathSpec('auth/login'), isTrue);
      expect(isValidPathSpec('a/b/c/login'), isTrue);
      expect(isValidPathSpec(r'auth\login'), isTrue);
    });

    test('rejects specs with any invalid segment', () {
      expect(isValidPathSpec('auth/My-Feature'), isFalse);
      expect(isValidPathSpec('Auth/login'), isFalse);
    });

    test('rejects empty segments', () {
      expect(isValidPathSpec('auth//login'), isFalse);
      expect(isValidPathSpec('/login'), isFalse);
      expect(isValidPathSpec(''), isFalse);
    });
  });
}
