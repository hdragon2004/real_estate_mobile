import '../network/api_client.dart';
import '../constants/api_constants.dart';
import '../models/post_model.dart';

class FavoriteRepository {
  final ApiClient _apiClient = ApiClient();

  /// Lấy danh sách yêu thích của user
  Future<List<PostModel>> getFavoritesByUser(int userId) async {
    try {
      final response = await _apiClient.get('${ApiConstants.favorites}/user/$userId');
      
      if (response is List) {
        // Backend trả về List<Favorite> với Post nested
        return response.map((json) {
          // Extract Post từ Favorite object
          final postJson = json['post'] ?? json;
          return PostModel.fromJson(postJson);
        }).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Thêm vào yêu thích
  Future<void> addFavorite(int userId, int postId) async {
    try {
      await _apiClient.post('${ApiConstants.favorites}/$userId/$postId');
    } catch (e) {
      rethrow;
    }
  }

  /// Xóa khỏi yêu thích
  Future<void> removeFavorite(int userId, int postId) async {
    try {
      await _apiClient.delete('${ApiConstants.favorites}/user/$userId/post/$postId');
    } catch (e) {
      rethrow;
    }
  }

  /// Kiểm tra xem có yêu thích không
  Future<bool> checkFavorite(int postId) async {
    try {
      final response = await _apiClient.get('${ApiConstants.favorites}/check/$postId');
      return response['isFavorite'] ?? false;
    } catch (e) {
      return false;
    }
  }
}

