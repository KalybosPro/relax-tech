import 'package:mason_logger/mason_logger.dart';

/// Prompts the user to choose one item from a list.
///
/// Uses a simple numbered prompt that works reliably on all terminals
/// including Windows PowerShell (where ANSI-based arrow-key menus
/// from mason_logger don't render correctly).
T chooseOneOf<T>(
  Logger logger, {
  required String message,
  required List<T> choices,
  required String Function(T) display,
  T? defaultValue,
}) {
  logger.info(message);
  logger.info('');

  for (var i = 0; i < choices.length; i++) {
    final isDefault = choices[i] == defaultValue;
    final prefix = lightCyan.wrap('  ${i + 1}');
    final label = display(choices[i]);
    final suffix = isDefault ? darkGray.wrap(' (default)') ?? '' : '';
    logger.info('$prefix  $label$suffix');
  }

  logger.info('');

  const maxAttempts = 5;
  for (var attempt = 0; attempt < maxAttempts; attempt++) {
    final defaultHint = defaultValue != null
        ? ' [${choices.indexOf(defaultValue) + 1}]'
        : '';
    final input = logger.prompt('Choose$defaultHint').trim();

    // Enter with no input → use default
    if (input.isEmpty && defaultValue != null) {
      return defaultValue;
    }

    final index = int.tryParse(input);
    if (index != null && index >= 1 && index <= choices.length) {
      return choices[index - 1];
    }

    // Also accept the choice name
    for (final choice in choices) {
      if (display(choice).toLowerCase() == input.toLowerCase()) {
        return choice;
      }
    }

    logger.err('Please enter a number between 1 and ${choices.length}.');
  }

  // Exhausted attempts — fall back to default or first choice
  final fallback = defaultValue ?? choices.first;
  logger.warn('No valid input after $maxAttempts attempts. Using "${display(fallback)}".');
  return fallback;
}
