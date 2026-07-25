import '../entities/stop.dart';

abstract class TransitRepository {
  Future<List<Stop>> getStops();
}