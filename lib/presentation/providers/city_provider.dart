import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/overpass_datasource.dart';
import '../../data/services/cities_loader.dart';
import '../../domain/entities/city.dart';
import '../../domain/entities/stop.dart';
import 'transit_provider.dart';

final allCitiesProvider = FutureProvider<List<City>>((ref) async {
  final cities = await CitiesLoader().loadCities();
  return [...cities.where((c) => c.isDefault), ...cities.where((c) => !c.isDefault)];
});

final downloadedCitiesProvider = FutureProvider<List<City>>(
  (ref) => ref.watch(localDbProvider).getDownloadedCities(),
);

class CityNotifier extends StateNotifier<City?> {
  final Ref _ref;

  CityNotifier(this._ref) : super(null) {
    _ref.read(downloadedCitiesProvider.future).then((c) {
      if (c.isNotEmpty) state = c.first;
    });
  }

  Future<void> select(City city) async {
    final downloaded = await _ref.read(downloadedCitiesProvider.future);
    if (!downloaded.any((c) => c.slug == city.slug)) {
      final stops = await (await OverpassDataSource.fetchCity(city.name)).getStops();
      if (stops.isEmpty) throw Exception('Остановки не найдены');
      await _ref.read(localDbProvider).saveCityAndStops(city, stops);
      _ref.invalidate(downloadedCitiesProvider);
      _ref.invalidate(stopsByCityProvider(city.slug));
    }
    state = city;
  }

  Future<void> delete(City city) async {
    await _ref.read(localDbProvider).deleteCity(city.slug);
    _ref.invalidate(downloadedCitiesProvider);
    _ref.invalidate(stopsByCityProvider(city.slug));
    if (state?.slug == city.slug) state = null;
  }
}

final activeCityProvider = StateNotifierProvider<CityNotifier, City?>(CityNotifier.new);

final stopsByCityProvider = FutureProvider.family<List<Stop>, String>(
  (ref, slug) => ref.watch(repositoryProvider).getStopsByCity(slug),
);
