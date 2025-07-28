class Recipe {
  final String id;
  final String title;
  final String description;
  final List<String> images; // Thay đổi từ String imageUrl thành List<String> images
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
    required this.images, // Thay đổi từ imageUrl thành images
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

  // Getter để lấy ảnh bìa (ảnh đầu tiên)
  String get coverImage => images.isNotEmpty ? images.first : '';

  // Getter để tương thích với code cũ
  String get imageUrl => coverImage;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'images': images, // Thay đổi từ imageUrl thành images
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
    // Xử lý tương thích với dữ liệu cũ và mới
    List<String> imagesList = [];

    // Nếu có trường 'images' (dữ liệu mới)
    if (map['images'] != null) {
      imagesList = List<String>.from(map['images']);
    }
    // Nếu có trường 'imageUrl' (dữ liệu cũ) và chưa có images
    else if (map['imageUrl'] != null && map['imageUrl'].toString().isNotEmpty) {
      imagesList = [map['imageUrl'].toString()];
    }

    return Recipe(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      images: imagesList, // Sử dụng imagesList đã xử lý
      ingredients: List<String>.from(map['ingredients'] ?? []),
      instructions: List<String>.from(map['instructions'] ?? []),
      category: map['category'] ?? '',
      cookingTime: map['cookingTime']?.toInt() ?? 0,
      servings: map['servings']?.toInt() ?? 0,
      difficulty: map['difficulty'] ?? 'easy',
      createdBy: map['createdBy'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      tags: List<String>.from(map['tags'] ?? []),
      rating: map['rating']?.toDouble() ?? 0.0,
      ratingCount: map['ratingCount']?.toInt() ?? 0,
    );
  }
}
