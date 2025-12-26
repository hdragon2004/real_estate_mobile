import '../constants/api_constants.dart';
import '../models/auth_models.dart';
import 'base_repository.dart';
import 'api_response.dart';

class AuthRepository extends BaseRepository {
  /// Đăng nhập
  Future<ApiResponse<AuthResponse>> login(String email, String password) async {
    return await handleRequestWithResponse<AuthResponse>(
      request: () => apiClient.post(
        ApiConstants.login,
        data: {
          'email': email,
          'password': password,
        },
      ),
      fromJson: (json) => AuthResponse.fromJson(json),
    );
  }

  /// Đăng ký tài khoản mới
  Future<ApiResponse<AuthResponse>> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    required String phone,
  }) async {
    return await handleRequestWithResponse<AuthResponse>(
      request: () => apiClient.post(
        ApiConstants.register,
        data: {
          'name': name,
          'email': email,
          'password': password,
          'confirmPassword': confirmPassword,
          'phone': phone,
        },
      ),
      fromJson: (json) => AuthResponse.fromJson(json),
    );
  }
}
