class City {
  final String slug;
  final String name;
  final bool isDefault;

  const City({required this.slug, required this.name, this.isDefault = false});

  factory City.fromJson(Map<String, dynamic> json) => City(
        slug: json['slug'],
        name: json['name'],
        isDefault: json['isDefault'] ?? false,
      );
}
