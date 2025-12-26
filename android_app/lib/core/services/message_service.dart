import '../repositories/message_repository.dart';
import 'base_service.dart';

class MessageService extends BaseService {
  late MessageRepository _messageRepository;

  MessageService() {
    _messageRepository = MessageRepository();
  }

  /// Lấy danh sách tin nhắn giữa 2 user
  Future<List<Map<String, dynamic>>> getMessages({
    required int senderId,
    required int receiverId,
    int? postId,
  }) async {
    final response = await _messageRepository.getMessages(
      senderId: senderId,
      receiverId: receiverId,
      postId: postId,
    );
    return unwrapListResponse(response);
  }

  /// Gửi tin nhắn
  Future<Map<String, dynamic>> sendMessage({
    required int senderId,
    required int receiverId,
    required int postId,
    required String content,
    String? imageUrl, // Optional - URL của hình ảnh
  }) async {
    final response = await _messageRepository.sendMessage(
      senderId: senderId,
      receiverId: receiverId,
      postId: postId,
      content: content,
      imageUrl: imageUrl,
    );
    return unwrapResponse(response);
  }

  /// Upload hình ảnh cho tin nhắn
  Future<String> uploadMessageImage(String filePath) async {
    final response = await _messageRepository.uploadMessageImage(filePath);
    // Response đã là ApiResponse<String>, lấy data
    if (response.data != null) {
      return response.data!;
    }
    throw Exception(response.message ?? 'Không thể upload ảnh');
  }

  /// Lấy danh sách conversations của user
  Future<List<Map<String, dynamic>>> getConversations(int userId) async {
    final response = await _messageRepository.getConversations(userId);
    return unwrapListResponse(response);
  }

  /// Đánh dấu tin nhắn đã đọc
  Future<void> markAsRead({
    required int userId,
    required int otherUserId,
    required int postId,
    required int messageId,
  }) async {
    return await _messageRepository.markAsRead(
      userId: userId,
      otherUserId: otherUserId,
      postId: postId,
      messageId: messageId,
    );
  }
}

