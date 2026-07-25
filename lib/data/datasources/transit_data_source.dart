import '../../domain/entities/stop.dart';
import '../../domain/entities/transit_route.dart';

/// Абстрактный интерфейс источника транспортных данных
/// Позволяет легко переключаться между разными источниками:
/// - JSON из assets
/// - Overpass API
/// - Официальный городской API (когда появится)
abstract class TransitDataSource {
  /// Получить список всех остановок
  Future<List<Stop>> getStops();

  /// Получить список всех маршрутов
  Future<List<TransitRoute>> getRoutes();

  /// Поток данных о реальном положении транспорта (опционально)
  /// Возвращает null, если источник не поддерживает realtime
  Stream<Map<String, double>>? getRealTimePositions();
}