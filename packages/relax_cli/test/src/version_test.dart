import 'dart:io';

import 'package:relax_cli/src/version.dart';
import 'package:test/test.dart';

void main() {
  group('version', () {
    test('matches the version declared in pubspec.yaml', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      final declared = RegExp(
        r'^version:\s*(\S+)\s*$',
        multiLine: true,
      ).firstMatch(pubspec)?.group(1);

      expect(
        declared,
        isNotNull,
        reason: 'pubspec.yaml has no top-level version field',
      );
      expect(
        version,
        declared,
        reason:
            'lib/src/version.dart is out of sync with pubspec.yaml — '
            '`relax --version` would report the wrong version once published',
      );
    });
  });
}
