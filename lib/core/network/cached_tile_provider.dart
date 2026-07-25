import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class CachedTileProvider extends TileProvider {
  final CacheManager cacheManager;

  CachedTileProvider({CacheManager? cacheManager})
      : cacheManager = cacheManager ?? DefaultCacheManager();

  @override
  Future<ImageProvider> getImage(TileCoordinates coordinates, TileLayer options) async {
    final url = getTileUrl(coordinates, options);
    
    // Проверяем кэш
    final fileInfo = await cacheManager.getFileFromCache(url);
    if (fileInfo != null) {
      return FileImage(fileInfo.file);
    }
    
    // Скачиваем и кэшируем
    final file = await cacheManager.downloadFile(url);
    return FileImage(file.file);
  }

  @override
  bool supportsRetry() => true;
}