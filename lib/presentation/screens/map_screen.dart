import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../providers/transit_provider.dart';
import '../../core/network/network_resilience.dart';
import '../../core/network/logging_tile_provider.dart';
import '../../core/utils/logger.dart';
import '../../domain/entities/stop.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final _searchController = TextEditingController();
  List<Stop> _allStops = [];
  List<Stop> _filteredStops = [];
  bool _isSearching = false;
  
  late MapController _mapController;
  
  bool _mapReady = false;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _initLocation();
  }

  @override
  void dispose() {
    // Освобождаем контроллер карты
    _mapController.dispose();
    _searchController.dispose();
    // Отменяем подписки на геолокацию (если есть)
    super.dispose();
  }

  ColorFilter _getHighContrastFilter() {
    const double contrast = 3.5;   // Усиление контраста
    const double brightness = 0;
    
    return ColorFilter.matrix([
      contrast, 0, 0, 0, brightness * 255,
      0, contrast, 0, 0, brightness * 255,
      0, 0, contrast, 0, brightness * 255,
      0, 0, 0, 1, 0,
    ]);
  }

  Future<void> _initLocation() async {
    try {
      // Проверяем, включена ли геолокация на устройстве
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        AppLogger.w('Геолокация отключена в настройках');
        if (mounted) {
          _showLocationDisabledDialog();
        }
        return;
      }

      final permission = await NetworkResilience.retry(
        () async => await Geolocator.checkPermission(),
        maxAttempts: 2,
      );

      if (permission == LocationPermission.denied) {
        final requested = await Geolocator.requestPermission();
        if (requested == LocationPermission.denied || 
            requested == LocationPermission.deniedForever) {
          if (mounted) _showLocationDisabledDialog();
          return;
        }
      }
      
      final position = await NetworkResilience.retry(
        () => Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 8),
        ),
        maxAttempts: 2,
        shouldRetry: NetworkResilience.isNetworkError,
      );

      if (mounted) {
        ref.read(myLocationProvider.notifier).state = LatLng(
          position.latitude, 
          position.longitude,
        );
      }
    } catch (e) {
      print('Геолокация не доступна: $e');
    }
  }

  Future<void> _searchStops(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _filteredStops = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      // Всегда загружаем свежие данные из БД
      final allStops = await ref.read(repositoryProvider).getStops();
      
      // Фильтруем с учётом кириллицы (регистронезависимо)
      final normalizedQuery = query.toLowerCase().trim();
      final filtered = allStops.where((stop) {
        final normalizedName = stop.name.toLowerCase();
        return normalizedName.contains(normalizedQuery);
      }).toList();

      setState(() {
        _filteredStops = filtered;
        _isSearching = false;
      });
      
      AppLogger.d('Найдено ${filtered.length} остановок по запросу "$query"');
      
    } catch (e) {
      AppLogger.e('Ошибка поиска', e);
      setState(() => _isSearching = false);
    }
  }

  // диалог для пользователя
  void _showLocationDisabledDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Геолокация отключена'),
        content: const Text(
          'Чтобы видеть своё положение на карте, '
          'включите геолокацию в настройках устройства.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Понятно'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stopsAsync = ref.watch(stopsProvider);
    final myLoc = ref.watch(myLocationProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tileUrl = isDark
      // ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
      ? 'https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
      : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(54.9885, 73.3242),
              initialZoom: 12,
              onMapReady: () {
                setState(() => _mapReady = true);
              },
            ),
            children: [
              if (isDark)
                ColorFiltered(
                  // colorFilter: ColorFilter.mode(
                  //   Colors.white.withOpacity(1), // Регулируйте прозрачность: 0.1–0.3
                  //   BlendMode.overlay,
                  // ),
                  colorFilter: _getHighContrastFilter(),
                  child: TileLayer(
                    urlTemplate: 'https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                    userAgentPackageName: 'com.yourname.transit',
                    tileProvider: LoggingTileProvider(),//это нужно только для логирования???
                  ),
                )
              else
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.yourname.transit',
                  tileProvider: LoggingTileProvider(),//это нужно только для логирования???
                ),
              stopsAsync.when(
                data: (stops) => MarkerLayer(
                  markers: stops.map((s) => Marker(
                    point: LatLng(s.lat, s.lon),
                    child: const Icon(Icons.circle, size: 8, color: Colors.blue),
                  )).toList(),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Ошибка: $e')),
              ),
              if (myLoc != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: myLoc,
                      child: const Icon(Icons.my_location, size: 24, color: Colors.red),
                    ),
                  ],
                ),
            ],
          ),
          if (!_mapReady)
            const Positioned.fill(
              child: Center(child: CircularProgressIndicator()),
            ),
          // Панель поиска
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (value) => _searchStops(value),
                      decoration: InputDecoration(
                        hintText: 'Например: Центр, Рынок, Ленина...',
                        hintStyle: TextStyle(color: Theme.of(context).hintColor),
                        prefixIcon: Icon(Icons.search, color: Theme.of(context).iconTheme.color),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, color: Theme.of(context).iconTheme.color),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _filteredStops = []);
                                },
                              )
                            : null,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Theme.of(context).cardColor,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      onChanged: (value) => _searchStops(value),
                    ),
                    if (_isSearching)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    if (_filteredStops.isNotEmpty)
                      Container(
                        constraints: const BoxConstraints(maxHeight: 250),
                        margin: const EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.withOpacity(0.2)),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: _filteredStops.length > 7 ? 7 : _filteredStops.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, thickness: 0.5),
                          itemBuilder: (context, index) {
                            final stop = _filteredStops[index];
                            return ListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              leading: CircleAvatar(
                                radius: 10,
                                backgroundColor: Colors.blue,
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(color: Colors.white, fontSize: 10),
                                ),
                              ),
                              title: Text(
                                stop.name,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                '${stop.lat.toStringAsFixed(4)}, ${stop.lon.toStringAsFixed(4)}',
                                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                              onTap: () {
                                _mapController.move(
                                  LatLng(stop.lat, stop.lon),
                                  17, // Ближе зум при выборе
                                );
                                _searchController.clear();
                                FocusScope.of(context).unfocus(); // Скрыть клавиатуру
                                setState(() => _filteredStops = []);
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (_isOffline)
          Container(
            color: Colors.grey[850],
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cloud_off,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Нет подключения к интернету',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Карта будет доступна при подключении',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}