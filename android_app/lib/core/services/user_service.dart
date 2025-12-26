import '../repositories/user_repository.dart';
import '../models/auth_models.dart';
import 'base_service.dart';

class UserService extends BaseService {
  late UserRepository _userRepository;

  UserService() {
    _userRepository = UserRepository();
  }

  /// Lấy profile của user hiện tại
  Future<User> getProfile() async {
    final response = await _userRepository.getProfile();
    return unwrapResponse(response);
  }

  /// Lấy user theo ID
  Future<User> getUserById(int id) async {
    final response = await _userRepository.getUserById(id);
    return unwrapResponse(response);
  }

  /// Cập nhật profile
  Future<User> updateProfile(User user) async {
    final response = await _userRepository.updateProfile(user);
    return unwrapResponse(response);
  }

  /// Upload avatar
  Future<String> uploadAvatar(String filePath) async {
    final response = await _userRepository.uploadAvatar(filePath);
    return unwrapResponse(response);
  }
}

