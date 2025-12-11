import '../network/api_client.dart';
import '../constants/api_constants.dart';

class MessageRepository {
  final ApiClient _apiClient = ApiClient();

  /// Lấy danh sách tin nhắn giữa 2 user cho một post
  Future<List<Map<String, dynamic>>> getMessages({
    required int senderId,
    required int receiverId,
    required int postId,
  }) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.messages}?senderId=$senderId&receiverId=$receiverId&postId=$postId',
      );
      
      if (response is List) {
        return response.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Gửi tin nhắn
  Future<Map<String, dynamic>> sendMessage({
    required int senderId,
    required int receiverId,
    required int postId,
    required String content,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.messages,
        data: {
          'senderId': senderId,
          'receiverId': receiverId,
          'postId': postId,
          'content': content,
        },
      );
      return response as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// Lấy danh sách conversations của user
  Future<List<Map<String, dynamic>>> getConversations(int userId) async {
    try {
      final response = await _apiClient.get('${ApiConstants.messages}/conversations/$userId');
      
      if (response is List) {
        return response.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Đánh dấu tin nhắn đã đọc
  Future<void> markAsRead({
    required int userId,
    required int otherUserId,
    required int postId,
    required int messageId,
  }) async {
    try {
      await _apiClient.put(
        '${ApiConstants.messages}/read',
        data: {
          'userId': userId,
          'otherUserId': otherUserId,
          'postId': postId,
          'messageId': messageId,
        },
      );
    } catch (e) {
      rethrow;
    }
  }
}

