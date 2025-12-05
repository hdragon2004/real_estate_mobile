import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../constants/api_constants.dart';
import '../models/auth_models.dart';

class UserRepository {
  final ApiClient _apiClient = ApiClient();

  Future<User> getProfile() async {
    try {
      final response = await _apiClient.get(ApiConstants.userProfile);
      return User.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<User> updateProfile(User user) async {
    try {
      final response = await _apiClient.dio.put(
        ApiConstants.userProfile,
        data: user.toJson(),
      );
      return User.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<String> uploadAvatar(String filePath) async {
    try {
      FormData formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(filePath),
      });

      final response = await _apiClient.dio.post(
        ApiConstants.userAvatar,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      return response.data['avatarUrl'] ?? '';
    } catch (e) {
      rethrow;
    }
  }

  Future<User> getUserById(int id) async {
    try {
      final response = await _apiClient.get('${ApiConstants.users}/$id');
      return User.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }
}
