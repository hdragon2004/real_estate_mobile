import '../repositories/auth_repository.dart';
import '../models/auth_models.dart';
import 'base_service.dart';

class AuthService extends BaseService {
  late AuthRepository _authRepository;

  AuthService() {
    _authRepository = AuthRepository();
  }

  /// Đăng nhập
  Future<AuthResponse> login(String email, String password) async {
    final response = await _authRepository.login(email, password);
    return unwrapResponse(response);
  }

  /// Đăng ký tài khoản mới
  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    required String phone,
  }) async {
    final response = await _authRepository.register(
      name: name,
      email: email,
      password: password,
      confirmPassword: confirmPassword,
      phone: phone,
    );
    return unwrapResponse(response);
  }

  /// Validate email format
  bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Validate password strength
  bool isStrongPassword(String password) {
    // Ít nhất 8 ký tự, có chữ hoa, chữ thường, số
    return password.length >= 8 &&
        RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password) &&
        RegExp(r'[0-9]').hasMatch(password);
  }
}
