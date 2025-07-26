class AppUser {
  final String id;
  final String email;
  final String name;
  final String role; // 'admin' hoặc 'user'
  final String? profileImageUrl;
  final List<String> favoriteRecipes;
  final DateTime createdAt;
  final String? bio;
  final int recipesCreated;

  AppUser({
    required this.id,
    required this.email,
    required this.name,
    this.role = 'user',
    this.profileImageUrl,
    this.favoriteRecipes = const [],
    required this.createdAt,
    this.bio,
    this.recipesCreated = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'profileImageUrl': profileImageUrl,
      'favoriteRecipes': favoriteRecipes,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'bio': bio,
      'recipesCreated': recipesCreated,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? 'user',
      profileImageUrl: map['profileImageUrl'],
      favoriteRecipes: List<String>.from(map['favoriteRecipes'] ?? []),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      bio: map['bio'],
      recipesCreated: map['recipesCreated'] ?? 0,
    );
  }

  bool get isAdmin => role == 'admin';
}
