abstract class RelaxPayLogger {
  void info(String message);
  void warning(String message, [dynamic error, StackTrace? stackTrace]);
  void error(String message, [dynamic error, StackTrace? stackTrace]);
}

/// Default implementation using the console.
class DefaultRelaxPayLogger implements RelaxPayLogger {
  final bool enableLogs;

  DefaultRelaxPayLogger({this.enableLogs = true});

  @override
  void info(String message) {
    if (enableLogs) print('[RelaxPay INFO] $message');
  }

  @override
  void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    if (enableLogs) print('[RelaxPay WARNING] $message ${error ?? ""}');
  }

  @override
  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (enableLogs) print('[RelaxPay ERROR] $message ${error ?? ""}');
  }
}