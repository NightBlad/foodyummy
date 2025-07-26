class Recipe {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final List<String> ingredients;
  final List<String> instructions;
  final String category;
  final int cookingTime; // phút
  final int servings;
  final String difficulty; // easy, medium, hard
  final String createdBy;
  final DateTime createdAt;
  final List<String> tags;
  final double rating;
  final int ratingCount;

  Recipe({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.ingredients,
    required this.instructions,
    required this.category,
    required this.cookingTime,
    required this.servings,
    required this.difficulty,
    required this.createdBy,
    required this.createdAt,
    this.tags = const [],
    this.rating = 0.0,
    this.ratingCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'ingredients': ingredients,
      'instructions': instructions,
      'category': category,
      'cookingTime': cookingTime,
      'servings': servings,
      'difficulty': difficulty,
      'createdBy': createdBy,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'tags': tags,
      'rating': rating,
      'ratingCount': ratingCount,
    };
  }

  factory Recipe.fromMap(Map<String, dynamic> map) {
    return Recipe(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      ingredients: List<String>.from(map['ingredients'] ?? []),
      instructions: List<String>.from(map['instructions'] ?? []),
      category: map['category'] ?? '',
      cookingTime: map['cookingTime'] ?? 0,
      servings: map['servings'] ?? 1,
      difficulty: map['difficulty'] ?? 'easy',
      createdBy: map['createdBy'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      tags: List<String>.from(map['tags'] ?? []),
      rating: (map['rating'] ?? 0.0).toDouble(),
      ratingCount: map['ratingCount'] ?? 0,
    );
  }
}
