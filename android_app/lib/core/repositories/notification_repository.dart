import '../network/api_client.dart';
import '../constants/api_constants.dart';

class NotificationRepository {
  final ApiClient _apiClient = ApiClient();

  /// Lấy danh sách thông báo của user
  Future<List<Map<String, dynamic>>> getNotifications(int userId) async {
    try {
      final response = await _apiClient.get('${ApiConstants.notifications}?userId=$userId');
      
      if (response is List) {
        return response.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Đánh dấu thông báo đã đọc
  Future<void> markAsRead(int notificationId) async {
    try {
      await _apiClient.put('${ApiConstants.notifications}/$notificationId/mark-read');
    } catch (e) {
      rethrow;
    }
  }

  /// Xóa thông báo
  Future<void> deleteNotification(int notificationId) async {
    try {
      await _apiClient.delete('${ApiConstants.notifications}/$notificationId');
    } catch (e) {
      rethrow;
    }
  }
}

