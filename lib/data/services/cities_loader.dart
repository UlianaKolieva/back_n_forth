import 'dart:convert';
import 'package:flutter/services.dart';
import '../../domain/entities/city.dart';

class CitiesLoader {
  Future<List<City>> loadCities() async {
    try {
      String jsonString = await rootBundle.loadString('assets/data/cities.json');
      
      List<dynamic> jsonList = jsonDecode(jsonString);
      
      return jsonList.map((e) => City.fromJson(e)).toList();
    } catch (e) {
      print('Ошибка загрузки городов: $e');
      return [];
    }
  }
}