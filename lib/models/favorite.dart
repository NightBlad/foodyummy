class Favorite {
  final String id;
  final String name;
  final String type;
  final String userId;

  Favorite({required this.id, required this.name, required this.type, required this.userId});

  factory Favorite.fromMap(Map<String, dynamic> map, String id) {
    return Favorite(
      id: id,
      name: map['name'] ?? '',
      type: map['type'] ?? '',
      userId: map['userId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'userId': userId,
    };
  }
}

