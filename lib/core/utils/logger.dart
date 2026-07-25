enum LogLevel { debug, info, warning, error }

class AppLogger {
  static const bool _isDebug = true; // Отключите в релизе

  static void _log(LogLevel level, String message, [dynamic error]) {
    if (!_isDebug && level == LogLevel.debug) return;
    
    final timestamp = DateTime.now().toIso8601String().split('T').last;
    final prefix = switch (level) {
      LogLevel.debug => '🔍',
      LogLevel.info => 'ℹ️',
      LogLevel.warning => '⚠️',
      LogLevel.error => '❌',
    };
    
    print('[$timestamp] $prefix [$level] $message');
    if (error != null) print('   Error: $error');
  }

  static void d(String msg) => _log(LogLevel.debug, msg);
  static void i(String msg) => _log(LogLevel.info, msg);
  static void w(String msg, [dynamic e]) => _log(LogLevel.warning, msg, e);
  static void e(String msg, [dynamic e]) => _log(LogLevel.error, msg, e);
}