import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

class LoggingTileProvider extends TileProvider {
  final TileProvider _baseProvider;

  LoggingTileProvider({TileProvider? baseProvider})
      : _baseProvider = baseProvider ?? NetworkTileProvider();

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final url = getTileUrl(coordinates, options);
    print('🗺️ Загрузка тайла: $url');
    
    try {
      return _baseProvider.getImage(coordinates, options);
    } catch (e) {
      print('⚠️ Не удалось загрузить тайл: $e');
      // Возвращаем заглушку при ошибке
      return const AssetImage('assets/images/empty.png');
    }
  }
}