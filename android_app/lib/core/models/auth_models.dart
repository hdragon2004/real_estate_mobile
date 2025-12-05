class AuthResponse {
  final String token;
  final User user;

  AuthResponse({
    required this.token,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] ?? '',
      user: User.fromJson(json['user'] ?? {}),
    );
  }
}

class User {
  final int id;
  final String name;
  final String email;
  final String? avatarUrl;
  final String role;
  final bool isLocked;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.role,
    this.isLocked = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      avatarUrl: json['avatarUrl'],
      role: json['role'] ?? 'User',
      isLocked: json['isLocked'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'role': role,
      'isLocked': isLocked,
    };
  }
}
