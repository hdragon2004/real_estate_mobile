import '../network/api_client.dart';
import '../constants/api_constants.dart';

class FavoriteRepository {
  final ApiClient _apiClient = ApiClient();

  /// Lấy danh sách favorites của user
  Future<List<Map<String, dynamic>>> getFavoritesByUser(int userId) async {
    try {
      final response = await _apiClient.get('${ApiConstants.favorites}/user/$userId');
      
      if (response is List) {
        return response.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Thêm favorite
  Future<Map<String, dynamic>> addFavorite(int userId, int postId) async {
    try {
      final response = await _apiClient.post('${ApiConstants.favorites}/$userId/$postId');
      return response as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// Xóa favorite
  Future<void> removeFavorite(int userId, int postId) async {
    try {
      await _apiClient.delete('${ApiConstants.favorites}/user/$userId/post/$postId');
    } catch (e) {
      rethrow;
    }
  }

  /// Kiểm tra xem post có trong favorites không
  Future<bool> checkFavorite(int postId) async {
    try {
      final response = await _apiClient.get('${ApiConstants.favorites}/check/$postId');
      return response['isFavorite'] ?? false;
    } catch (e) {
      return false;
    }
  }
}
