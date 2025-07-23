class AppUser {
  final String id;
  final String email;

  AppUser({required this.id, required this.email});

  factory AppUser.fromMap(Map<String, dynamic> map, String id) {
    return AppUser(
      id: id,
      email: map['email'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
    };
  }
}

