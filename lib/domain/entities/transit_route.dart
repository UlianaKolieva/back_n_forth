import 'package:flutter/material.dart';

class TransitRoute {
  final String id;
  final String number;
  final String name;
  final Color color;
  final List<String> stopIds; // ID остановок в порядке следования

  const TransitRoute({
    required this.id,
    required this.number,
    required this.name,
    required this.color,
    required this.stopIds,
  });
}