import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presentation/screens/map_screen.dart';
import 'data/datasources/local_db_datasource.dart';
import 'data/datasources/overpass_datasource.dart';
import 'domain/entities/stop.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    final jsonString = await rootBundle.loadString('assets/data/omsk_overpass.json');
    final dataSource = OverpassDataSource(jsonData: jsonString);
    final stops = await dataSource.getStops();
    print('Загружено ${stops.length} остановок из Overpass');
    final db = LocalDbDatasource();
    await db.seedStops(stops);
  } catch (e) {
    print('Не удалось загрузить данные из Overpass: $e');
  }

  runApp(const ProviderScope(child: OmskTransitApp()));
}

class OmskTransitApp extends StatelessWidget {
  const OmskTransitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Омск Транспорт',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        useMaterial3: true, 
        colorSchemeSeed: Colors.blue,
        brightness: Brightness.light,
      ),

      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        brightness: Brightness.dark,
      ),

      themeMode: ThemeMode.system,

      home: const MapScreen(),
    );
  }
}