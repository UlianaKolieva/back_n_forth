import '../../domain/entities/stop.dart';
import '../../domain/repositories/transit_repository.dart';
import '../datasources/local_db_datasource.dart';

class TransitRepositoryImpl implements TransitRepository {
  final LocalDbDatasource _dataSource;
  TransitRepositoryImpl(this._dataSource);

  @override
  Future<List<Stop>> getStopsByCity(String citySlug) =>
      _dataSource.getStopsByCity(citySlug);
}