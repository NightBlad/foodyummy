import 'package:cloud_firestore/cloud_firestore.dart';

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
    this.role = 'user', // default value, can be overridden by constructor
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
      'createdAt': createdAt.toIso8601String(),
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
      createdAt: (map['createdAt'] is Timestamp)
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
                DateTime.now(),
      bio: map['bio'],
      recipesCreated: map['recipesCreated'] ?? 0,
    );
  }

  bool get isAdmin => role == 'admin';

  AppUser copyWith({
    String? id,
    String? email,
    String? name,
    String? role,
    String? profileImageUrl,
    List<String>? favoriteRecipes,
    DateTime? createdAt,
    String? bio,
    int? recipesCreated,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      favoriteRecipes: favoriteRecipes ?? this.favoriteRecipes,
      createdAt: createdAt ?? this.createdAt,
      bio: bio ?? this.bio,
      recipesCreated: recipesCreated ?? this.recipesCreated,
    );
  }
}
