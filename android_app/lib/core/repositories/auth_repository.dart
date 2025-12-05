import '../network/api_client.dart';
import '../constants/api_constants.dart';
import '../models/auth_models.dart';

class AuthRepository {
  final ApiClient _apiClient = ApiClient();

  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.login,
        data: {
          'email': email,
          'password': password,
        },
      );
      return AuthResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    required String phone,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.register,
        data: {
          'name': name,
          'email': email,
          'password': password,
          'confirmPassword': confirmPassword,
          'phone': phone,
        },
      );
      return AuthResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }
}
