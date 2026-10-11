import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presentation/screens/map_screen.dart';

void main() {
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