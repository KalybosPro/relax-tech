import 'package:mason_logger/mason_logger.dart';

/// Validates that [name] is a valid Dart package/identifier name:
/// lowercase letters, digits, underscores; must start with a letter.
bool isValidDartName(String name) =>
    RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(name);

/// Parses a slash-separated spec like `auth/login` into a parent [subPath]
/// (`auth`) and a final [name] (`login`). Supports arbitrary depth
/// (`a/b/c/login`). Backslashes are normalized to `/`.
///
/// When [spec] has no separator (`login`), [subPath] is empty and [name] is the
/// spec itself — i.e. the existing behaviour.
({String subPath, String name}) parsePathSpec(String spec) {
  final parts = spec
      .replaceAll(r'\', '/')
      .split('/')
      .where((p) => p.isNotEmpty)
      .toList();
  final name = parts.isEmpty ? '' : parts.removeLast();
  return (subPath: parts.join('/'), name: name);
}

/// True if every `/`-separated segment of [spec] is a valid Dart name.
///
/// Empty segments (`auth//login`, `/login`, trailing `login/`) are rejected
/// because [isValidDartName] fails on the empty string.
bool isValidPathSpec(String spec) {
  final parts = spec.replaceAll(r'\', '/').split('/');
  return parts.isNotEmpty && parts.every(isValidDartName);
}

/// Logs a standard validation error for an invalid [kind] name and returns
/// [ExitCode.usage.code] — meant to be returned directly from Command.run().
int invalidNameError(Logger logger, String kind, String name) {
  logger.err('Invalid $kind name: "$name"');
  logger.info(
    '$kind name must be lowercase letters, digits, underscores; '
    'must start with a letter.',
  );
  return ExitCode.usage.code;
}
