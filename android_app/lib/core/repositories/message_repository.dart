import '../network/api_client.dart';
import '../constants/api_constants.dart';

class MessageRepository {
  final ApiClient _apiClient = ApiClient();

  /// Lấy danh sách tin nhắn giữa 2 user (theo ConversationId, có thể chứa nhiều PostId)
  /// Backend endpoint: GET /api/messages/conversation/{otherUserId}
  /// otherUserId là userId của người còn lại (không phải current user)
  Future<List<Map<String, dynamic>>> getMessages({
    required int senderId,
    required int receiverId,
    int? postId, // Không còn bắt buộc, chỉ để tương thích
  }) async {
    try {
      // Backend endpoint: /api/messages/conversation/{otherUserId}
      // ConversationId được tạo từ senderId và receiverId (không có postId)
      // otherUserId là userId của người còn lại (không phải current user)
      final otherUserId = receiverId;
      final response = await _apiClient.get(
        '${ApiConstants.messages}/conversation/$otherUserId',
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
  /// Backend endpoint: POST /api/messages
  /// Backend expect: { receiverId, postId?, content }
  /// senderId được lấy từ JWT token, không cần gửi lên
  /// postId có thể null nếu tin nhắn không liên quan đến post
  Future<Map<String, dynamic>> sendMessage({
    required int senderId, // Không dùng, chỉ để tương thích
    required int receiverId,
    required int postId, // Có thể 0 nếu không có postId
    required String content,
  }) async {
    try {
      final data = <String, dynamic>{
        'receiverId': receiverId,
        'content': content,
      };
      
      // Chỉ thêm postId nếu > 0 (backend sẽ xử lý null)
      if (postId > 0) {
        data['postId'] = postId;
      }
      
      final response = await _apiClient.post(
        ApiConstants.messages,
        data: data,
      );
      return response as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// Lấy danh sách conversations của user
  /// Backend endpoint: GET /api/messages/conversations
  /// Backend tự động lấy userId từ JWT token
  Future<List<Map<String, dynamic>>> getConversations(int userId) async {
    try {
      // Backend endpoint không cần userId trong URL vì lấy từ JWT token
      final response = await _apiClient.get('${ApiConstants.messages}/conversations');
      
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

