import '../utils/datetime_helper.dart';

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
  final String? phone;
  final String? avatarUrl;
  final String role;
  final bool isLocked;
  final DateTime? create;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatarUrl,
    required this.role,
    this.isLocked = false,
    this.create,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? json['Id'] ?? 0,
      name: json['name'] ?? json['Name'] ?? '',
      email: json['email'] ?? json['Email'] ?? '',
      phone: json['phone'] ?? json['Phone'],
      avatarUrl: json['avatarUrl'] ?? json['AvatarUrl'],
      role: json['role'] ?? json['Role'] ?? 'User',
      isLocked: json['isLocked'] ?? json['IsLocked'] ?? false,
      create: json['create'] != null 
          ? DateTimeHelper.fromBackendString(json['create'] as String)
          : json['Create'] != null 
              ? DateTimeHelper.fromBackendString(json['Create'] as String)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'role': role,
      'isLocked': isLocked,
      'create': create?.toIso8601String(),
    };
  }
}
