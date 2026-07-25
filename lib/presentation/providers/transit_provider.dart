import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../data/datasources/local_db_datasource.dart';
import '../../data/repositories/transit_repository_impl.dart';
import '../../domain/entities/stop.dart';

final localDbProvider = Provider((_) => LocalDbDatasource());
final repositoryProvider = Provider((ref) => TransitRepositoryImpl(ref.watch(localDbProvider)));

final stopsProvider = FutureProvider<List<Stop>>((ref) async {
  final repo = ref.watch(repositoryProvider);
  return repo.getStops();
});

final myLocationProvider = StateProvider<LatLng?>((_) => null);