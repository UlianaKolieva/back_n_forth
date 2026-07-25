import '../../domain/entities/stop.dart';
import '../../domain/repositories/transit_repository.dart';
import '../datasources/local_db_datasource.dart';

class TransitRepositoryImpl implements TransitRepository {
  final LocalDbDatasource _localDb;
  TransitRepositoryImpl(this._localDb);

  @override
  Future<List<Stop>> getStops() => _localDb.getStops();
}