import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../domain/entities/stop.dart';
import '../../domain/entities/city.dart';

class LocalDbDatasource {
  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      join(dbPath, 'transit.db'),
      version: 2,
      // Без этого ON DELETE CASCADE в SQLite не срабатывает
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, _) => _createTables(db),
      onUpgrade: (db, _, __) async {
        await db.execute('DROP TABLE IF EXISTS stops');
        await db.execute('DROP TABLE IF EXISTS cities');
        await _createTables(db);
      },
    );
    return _db!;
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE cities (
        slug TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        downloaded_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE stops (
        id TEXT NOT NULL,
        city_slug TEXT NOT NULL,
        name TEXT,
        lat REAL,
        lon REAL,
        PRIMARY KEY (city_slug, id),
        FOREIGN KEY (city_slug) REFERENCES cities (slug) ON DELETE CASCADE
      )
    ''');
  }

  Future<List<Stop>> getStopsByCity(String citySlug) async {
    final db = await database;
    final maps = await db.query('stops', where: 'city_slug = ?', whereArgs: [citySlug]);
    return maps.map((m) => Stop(
      id: m['id'] as String,
      name: m['name'] as String,
      lat: m['lat'] as double,
      lon: m['lon'] as double,
    )).toList();
  }

  Future<void> saveCityAndStops(City city, List<Stop> stops) async {
    final db = await database;
    await db.transaction((txn) async {
      // replace удаляет старый город -> каскадом его остановки
      await txn.insert('cities', {
        'slug': city.slug,
        'name': city.name,
        'downloaded_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      final batch = txn.batch();
      for (final stop in stops) {
        batch.insert('stops', {
          'id': stop.id,
          'city_slug': city.slug,
          'name': stop.name,
          'lat': stop.lat,
          'lon': stop.lon,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    });
  }

  Future<List<City>> getDownloadedCities() async {
    final db = await database;
    final maps = await db.query('cities', orderBy: 'downloaded_at DESC');
    return maps.map((m) => City(slug: m['slug'] as String, name: m['name'] as String)).toList();
  }

  Future<void> deleteCity(String citySlug) async {
    final db = await database;
    await db.delete('cities', where: 'slug = ?', whereArgs: [citySlug]);
  }
}
