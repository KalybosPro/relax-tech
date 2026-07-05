import '../models/quality_models.dart';
import 'dart_parser.dart';

/// Detects the state-management flavor used in a single file, combining
/// import, inheritance, and annotation signals. Detectors are independent so a
/// hybrid project (e.g. Bloc + Provider) surfaces every flavor it uses.
class StateManagementDetector {
  StateManagementKind detect(ParsedFile parsed) {
    final imports = parsed.imports.join('\n');

    for (final cls in parsed.classes) {
      final supers = cls.supertypes;

      if (supers.any((s) => s.startsWith('Cubit'))) {
        return StateManagementKind.cubit;
      }
      if (supers.any((s) => s.startsWith('Bloc'))) {
        return StateManagementKind.bloc;
      }
      if (supers.any(
        (s) =>
            s.contains('StateNotifier') ||
            s == 'Notifier' ||
            s.startsWith('Notifier<') ||
            s.startsWith('AsyncNotifier'),
      )) {
        return StateManagementKind.riverpod;
      }
      if (supers.any(
        (s) => s.contains('GetxController') || s == 'GetxService',
      )) {
        return StateManagementKind.getx;
      }
      if (cls.annotations.contains('observable') ||
          cls.annotations.contains('action') ||
          cls.annotations.contains('computed')) {
        return StateManagementKind.mobx;
      }
      if (supers.any((s) => s.contains('ChangeNotifier'))) {
        return StateManagementKind.provider;
      }
    }

    // Import-based fallbacks.
    if (imports.contains('flutter_bloc') || imports.contains('package:bloc')) {
      return StateManagementKind.bloc;
    }
    if (imports.contains('riverpod')) return StateManagementKind.riverpod;
    if (imports.contains('package:get/')) return StateManagementKind.getx;
    if (imports.contains('mobx')) return StateManagementKind.mobx;
    if (imports.contains('package:provider/')) {
      return StateManagementKind.provider;
    }

    return StateManagementKind.none;
  }
}
