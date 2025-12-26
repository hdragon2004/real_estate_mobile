import '../constants/api_constants.dart';
import 'base_repository.dart';
import 'api_response.dart';

class NotificationRepository extends BaseRepository {
  /// Lấy danh sách thông báo của user
  Future<ApiResponse<List<Map<String, dynamic>>>> getNotifications(int userId) async {
    return await handleRequestListWithResponse<Map<String, dynamic>>(
      request: () => apiClient.get('${ApiConstants.notifications}?userId=$userId'),
      fromJson: (json) => Map<String, dynamic>.from(json),
    );
  }

  /// Đánh dấu thông báo đã đọc
  Future<void> markAsRead(int notificationId) async {
    return await handleVoidRequest(
      request: () => apiClient.put('${ApiConstants.notifications}/$notificationId/mark-read'),
    );
  }

  /// Xóa thông báo
  Future<void> deleteNotification(int notificationId) async {
    return await handleVoidRequest(
      request: () => apiClient.delete('${ApiConstants.notifications}/$notificationId'),
    );
  }
}
