import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service để quản lý lưu trữ token xác thực một cách an toàn
class AuthStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _userNameKey = 'user_name';
  static const String _userAvatarKey = 'user_avatar';

  /// Lưu token vào secure storage
  static Future<void> saveToken(String token) async {
    try {
      await _storage.write(key: _tokenKey, value: token);
    } catch (e) {
      throw Exception('Lỗi lưu token: $e');
    }
  }

  /// Lấy token từ secure storage
  static Future<String?> getToken() async {
    try {
      return await _storage.read(key: _tokenKey);
    } catch (e) {
      throw Exception('Lỗi đọc token: $e');
    }
  }

  /// Xóa token khỏi secure storage
  static Future<void> deleteToken() async {
    try {
      await _storage.delete(key: _tokenKey);
    } catch (e) {
      throw Exception('Lỗi xóa token: $e');
    }
  }

  /// Lưu userId vào secure storage
  static Future<void> saveUserId(int userId) async {
    try {
      await _storage.write(key: _userIdKey, value: userId.toString());
    } catch (e) {
      throw Exception('Lỗi lưu userId: $e');
    }
  }

  /// Lấy userId từ secure storage
  static Future<int?> getUserId() async {
    try {
      final userIdString = await _storage.read(key: _userIdKey);
      if (userIdString != null) {
        return int.tryParse(userIdString);
      }
      return null;
    } catch (e) {
      throw Exception('Lỗi đọc userId: $e');
    }
  }

  /// Xóa tất cả dữ liệu xác thực
  static Future<void> clearAll() async {
    try {
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _userIdKey);
      await _storage.delete(key: _userNameKey);
      await _storage.delete(key: _userAvatarKey);
    } catch (e) {
      throw Exception('Lỗi xóa dữ liệu: $e');
    }
  }

  /// Lưu user name vào secure storage
  static Future<void> saveUserName(String userName) async {
    try {
      await _storage.write(key: _userNameKey, value: userName);
    } catch (e) {
      throw Exception('Lỗi lưu userName: $e');
    }
  }

  /// Lấy user name từ secure storage
  static Future<String?> getUserName() async {
    try {
      return await _storage.read(key: _userNameKey);
    } catch (e) {
      throw Exception('Lỗi đọc userName: $e');
    }
  }

  /// Lưu user avatar vào secure storage
  static Future<void> saveUserAvatar(String? avatarUrl) async {
    try {
      if (avatarUrl != null && avatarUrl.isNotEmpty) {
        await _storage.write(key: _userAvatarKey, value: avatarUrl);
      } else {
        await _storage.delete(key: _userAvatarKey);
      }
    } catch (e) {
      throw Exception('Lỗi lưu userAvatar: $e');
    }
  }

  /// Lấy user avatar từ secure storage
  static Future<String?> getUserAvatar() async {
    try {
      return await _storage.read(key: _userAvatarKey);
    } catch (e) {
      throw Exception('Lỗi đọc userAvatar: $e');
    }
  }

  /// Kiểm tra xem có token đã lưu không
  static Future<bool> hasToken() async {
    try {
      final token = await getToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}

