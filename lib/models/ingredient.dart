class Ingredient {
  final String id;
  final String name;
  final String type;

  Ingredient({required this.id, required this.name, required this.type});

  factory Ingredient.fromMap(Map<String, dynamic> map, String id) {
    return Ingredient(
      id: id,
      name: map['name'] ?? '',
      type: map['type'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
    };
  }
}

