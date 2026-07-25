import 'dart:async';
import 'dart:io';

class NetworkResilience {
  // Выполняет операцию с повторными попытками при сбое
  static Future<T> retry<T>(
    Future<T> Function() operation, {
    int maxAttempts = 3,
    Duration initialDelay = const Duration(seconds: 1),
    double backoffMultiplier = 2.0,
    bool Function(Exception)? shouldRetry,
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;

    while (true) {
      try {
        return await operation();
      } catch (e) {
        attempt++;
        if (attempt >= maxAttempts) rethrow;
        
        // Проверяем, стоит ли повторять
        if (shouldRetry != null && !shouldRetry(e as Exception)) rethrow;
        
        // Ждём перед следующей попыткой
        await Future.delayed(delay);
        delay = Duration(milliseconds: (delay.inMilliseconds * backoffMultiplier).toInt());
      }
    }
  }

  // Проверяет, является ли ошибка сетевой
  static bool isNetworkError(Exception e) {
    return e is SocketException ||
           e is HttpException ||
           e is TimeoutException ||
           e.toString().contains('Connection') ||
           e.toString().contains('timeout');
  }
}