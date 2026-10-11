import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../domain/entities/stop.dart';
import '../../domain/entities/transit_route.dart';
import 'transit_data_source.dart';

class OverpassDataSource implements TransitDataSource {
  final String jsonData;

  OverpassDataSource({required this.jsonData});

  static Future<OverpassDataSource> fetchCity(String cityName) async {
    // Границы городов в OSM называются "городской округ Омск" и т.п.,
    // поэтому ищем узел place и берём его админ. границу, оканчивающуюся на имя города
    final name = cityName.replaceAll('"', r'\"');
    final query = '''
[out:json][timeout:120];
node["place"~"^(city|town)\$"]["name"="$name"];
is_in->.a;
area.a["boundary"="administrative"]["admin_level"~"^(4|5|6|8)\$"]["name"~"(^|[ «])$name»?\$"]->.city;
node["highway"="bus_stop"](area.city);
out;
''';
    final res = await http
        .post(
          Uri.parse('https://overpass-api.de/api/interpreter'),
          headers: {'User-Agent': 'back_n_forth/1.0 (com.ukolieva.maps.back_n_forth)'},
          body: {'data': query},
        )
        .timeout(const Duration(seconds: 150));
    if (res.statusCode != 200) throw Exception('Overpass ${res.statusCode}');
    return OverpassDataSource(jsonData: utf8.decode(res.bodyBytes));
  }

  @override
  Future<List<Stop>> getStops() async {
    final data = jsonDecode(jsonData);
    final stops = <Stop>[];
    final stopIds = <String>{};

    print('🔍 Начинаем парсинг остановок...');
    print('📊 Всего элементов: ${data['elements']?.length ?? 0}');

    // Просто ищем ВСЕ узлы с highway=bus_stop
    for (final element in data['elements'] ?? []) {
      if (element['type'] == 'node' && 
          element['tags']?['highway'] == 'bus_stop') {
        
        final id = element['id']?.toString();
        if (id == null || stopIds.contains(id)) continue;
        
        stopIds.add(id);
        
        final tags = element['tags'] ?? {};
        final lat = element['lat'] as num?;
        final lon = element['lon'] as num?;
        
        if (lat == null || lon == null) continue;
        
        final name = tags['name'] ?? 
                    tags['ref'] ?? 
                    'Остановка #$id';
        
        stops.add(Stop(
          id: id,
          name: name,
          lat: lat.toDouble(),
          lon: lon.toDouble(),
        ));
        
        // Выводим первые 5 для отладки
        if (stops.length <= 5) {
          print('  ✅ Добавлена: $name ($id)');
        }
      }
    }

    print('✅ Найдено остановок: ${stops.length}');
    return stops;
  }

  @override
  Future<List<TransitRoute>> getRoutes() async {
    final data = jsonDecode(jsonData);
    final routes = <TransitRoute>[];

    for (final element in data['elements'] ?? []) {
      if (element['type'] == 'relation' && 
          element['tags']?['route'] == 'bus') {
        
        final tags = element['tags'] ?? {};
        final stopIds = <String>[];
        
        // Собираем ID остановок в порядке следования
        for (final member in element['members'] ?? []) {
          if (member['role']?.contains('platform') == true && 
              member['type'] == 'node') {
            stopIds.add(member['id'].toString());
          }
        }

        if (stopIds.isNotEmpty) {
          routes.add(TransitRoute(
            id: element['id'].toString(),
            number: tags['ref'] ?? '',
            name: tags['from'] ?? tags['to'] ?? '',
            color: _getColorForRoute(tags['ref']),
            stopIds: stopIds,
          ));
        }
      }
    }

    return routes;
  }

  Color _getColorForRoute(String? ref) {
    // Простая логика цветов для разных маршрутов
    final colors = [
      Colors.blue, Colors.red, Colors.green, 
      Colors.orange, Colors.purple, Colors.teal,
    ];
    final hash = ref?.hashCode ?? 0;
    return colors[hash.abs() % colors.length];
  }

  @override
  Stream<Map<String, double>>? getRealTimePositions() => null;
}