import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../data/datasources/local_db_datasource.dart';
import '../../data/repositories/transit_repository_impl.dart';

final localDbProvider = Provider((_) => LocalDbDatasource());
final repositoryProvider = Provider((ref) => TransitRepositoryImpl(ref.watch(localDbProvider)));

final myLocationProvider = StateProvider<LatLng?>((_) => null);