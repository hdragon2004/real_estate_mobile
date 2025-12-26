import '../constants/api_constants.dart';
import 'base_repository.dart';
import 'api_response.dart';

class FavoriteRepository extends BaseRepository {
  /// Lấy danh sách favorites của user
  Future<ApiResponse<List<Map<String, dynamic>>>> getFavoritesByUser(int userId) async {
    return await handleRequestListWithResponse<Map<String, dynamic>>(
      request: () => apiClient.get('${ApiConstants.favorites}/user/$userId'),
      fromJson: (json) => Map<String, dynamic>.from(json),
    );
  }

  /// Thêm favorite
  Future<ApiResponse<Map<String, dynamic>>> addFavorite(int userId, int postId) async {
    return await handleRequestWithResponse<Map<String, dynamic>>(
      request: () => apiClient.post('${ApiConstants.favorites}/$userId/$postId'),
      fromJson: (json) => Map<String, dynamic>.from(json),
    );
  }

  /// Xóa favorite
  Future<void> removeFavorite(int userId, int postId) async {
    return await handleVoidRequest(
      request: () => apiClient.delete('${ApiConstants.favorites}/user/$userId/post/$postId'),
    );
  }

  /// Kiểm tra post có trong favorites không
  Future<ApiResponse<bool>> checkFavorite(int postId) async {
    return await handleRequestWithResponse<bool>(
      request: () => apiClient.get('${ApiConstants.favorites}/check/$postId'),
      fromJson: (json) {
        // json luôn là Map<String, dynamic> từ ApiResponse.fromJson
        return json['isFavorite'] as bool? ?? false;
      },
    );
  }
}
