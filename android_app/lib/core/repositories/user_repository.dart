import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../models/auth_models.dart';
import 'base_repository.dart';
import 'api_response.dart';

class UserRepository extends BaseRepository {
  /// Lấy profile của user hiện tại
  Future<ApiResponse<User>> getProfile() async {
    return await handleRequestWithResponse<User>(
      request: () => apiClient.get(ApiConstants.userProfile),
      fromJson: (json) => User.fromJson(json),
    );
  }

  /// Lấy user theo ID
  Future<ApiResponse<User>> getUserById(int id) async {
    return await handleRequestWithResponse<User>(
      request: () => apiClient.get('${ApiConstants.users}/$id'),
      fromJson: (json) => User.fromJson(json),
    );
  }

  /// Cập nhật profile
  Future<ApiResponse<User>> updateProfile(User user) async {
    return await handleRequestWithResponse<User>(
      request: () => apiClient.dio.put(
        ApiConstants.userProfile,
        data: user.toJson(),
      ).then((response) => response.data),
      fromJson: (json) => User.fromJson(json),
    );
  }

  /// Upload avatar
  Future<ApiResponse<String>> uploadAvatar(String filePath) async {
    FormData formData = FormData.fromMap({
      'avatar': await MultipartFile.fromFile(filePath),
    });

    return await handleRequestWithResponse<String>(
      request: () => apiClient.dio.post(
        ApiConstants.userAvatar,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      ).then((response) => response.data),
      fromJson: (json) {
        // json luôn là Map<String, dynamic> từ ApiResponse.fromJson
        // Nếu data là String trực tiếp, ApiResponse.fromJson sẽ tự cast
        // Nếu data là Map, parse từ Map
        return json['avatarUrl'] as String? ?? json['data'] as String? ?? '';
      },
    );
  }
}
