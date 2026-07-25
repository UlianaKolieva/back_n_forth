import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../domain/entities/stop.dart';

class LocalDbDatasource {
  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      join(dbPath, 'transit.db'),
      version: 1,
      onCreate: (db, _) {
        db.execute('''
          CREATE TABLE stops (
            id TEXT PRIMARY KEY,
            name TEXT,
            lat REAL,
            lon REAL
          )
        ''');
      },
    );
    return _db!;
  }

  Future<List<Stop>> getStops() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('stops');
    return maps.map((m) => Stop(
      id: m['id'],
      name: m['name'],
      lat: m['lat'],
      lon: m['lon'],
    )).toList();
  }

  Future<void> seedStops(List<Stop> stops) async {
    final db = await database;
    final batch = db.batch();
    for (final s in stops) {
      batch.insert('stops', {
        'id': s.id,
        'name': s.name,
        'lat': s.lat,
        'lon': s.lon,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit();
  }
}