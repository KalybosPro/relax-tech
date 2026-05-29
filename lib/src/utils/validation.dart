import 'package:mason_logger/mason_logger.dart';

/// Validates that [name] is a valid Dart package/identifier name:
/// lowercase letters, digits, underscores; must start with a letter.
bool isValidDartName(String name) =>
    RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(name);

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
