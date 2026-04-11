import 'dart:io';

/// Utility class for colored CLI output using ANSI escape codes
class CliColors {
  static const String _reset = '\x1B[0m';
  static const String _red = '\x1B[31m';
  static const String _green = '\x1B[32m';
  static const String _yellow = '\x1B[33m';
  static const String _blue = '\x1B[34m';
  static const String _magenta = '\x1B[35m';
  static const String _cyan = '\x1B[36m';
  static const String _white = '\x1B[37m';
  static const String _gray = '\x1B[90m';
  static const String _bold = '\x1B[1m';

  static bool _useColors = true;

  static void setUseColors(bool useColors) => _useColors = useColors && stdout.supportsAnsiEscapes;

  // Colors
  static String red(String text) => _useColors ? '$_red$text$_reset' : text;
  static String green(String text) => _useColors ? '$_green$text$_reset' : text;
  static String yellow(String text) => _useColors ? '$_yellow$text$_reset' : text;
  static String blue(String text) => _useColors ? '$_blue$text$_reset' : text;
  static String magenta(String text) => _useColors ? '$_magenta$text$_reset' : text;
  static String cyan(String text) => _useColors ? '$_cyan$text$_reset' : text;
  static String white(String text) => _useColors ? '$_white$text$_reset' : text;
  static String gray(String text) => _useColors ? '$_gray$text$_reset' : text;

  // Styles
  static String bold(String text) => _useColors ? '$_bold$text$_reset' : text;

  // Combined styles
  static String error(String text) => bold(red(text));
  static String success(String text) => bold(green(text));
  static String warning(String text) => bold(yellow(text));
  static String info(String text) => bold(blue(text));
  static String debug(String text) => gray(text);
}

/// Enhanced logger with colors and real-time feedback
class CliLogger {
  static bool _verbose = false;

  static void setVerbose(bool verbose) => _verbose = verbose;

  static void error(String message) {
    stderr.writeln('${CliColors.error('✗ Error:')} $message');
  }

  static void success(String message) {
    print('${CliColors.success('✓')} $message');
  }

  static void warning(String message) {
    print('${CliColors.warning('⚠ Warning:')} $message');
  }

  static void info(String message) {
    print('${CliColors.info('ℹ')} $message');
  }

  static void debug(String message) {
    if (_verbose) {
      print('${CliColors.debug('🔍')} $message');
    }
  }

  static void step(String message) {
    print('${CliColors.cyan('→')} $message');
  }

  static void progress(String message) {
    print('${CliColors.blue('⏳')} $message');
  }

  static void done(String message) {
    print('${CliColors.green('✓')} $message');
  }
}