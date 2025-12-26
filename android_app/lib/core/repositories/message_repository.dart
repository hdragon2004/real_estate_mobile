import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import 'base_repository.dart';
import 'api_response.dart';

class MessageRepository extends BaseRepository {
  /// Lấy danh sách tin nhắn giữa 2 user
  Future<ApiResponse<List<Map<String, dynamic>>>> getMessages({
    required int senderId,
    required int receiverId,
    int? postId,
  }) async {
    final otherUserId = receiverId;
    return await handleRequestListWithResponse<Map<String, dynamic>>(
      request: () => apiClient.get('${ApiConstants.messages}/conversation/$otherUserId'),
      fromJson: (json) => Map<String, dynamic>.from(json),
    );
  }

  /// Gửi tin nhắn
  Future<ApiResponse<Map<String, dynamic>>> sendMessage({
    required int senderId,
    required int receiverId,
    required int postId,
    required String content,
    String? imageUrl, // Optional - URL của hình ảnh
  }) async {
    final data = <String, dynamic>{
      'receiverId': receiverId,
      'content': content,
    };
    
    if (postId > 0) {
      data['postId'] = postId;
    }
    
    if (imageUrl != null && imageUrl.isNotEmpty) {
      data['imageUrl'] = imageUrl;
    }
    
    return await handleRequestWithResponse<Map<String, dynamic>>(
      request: () => apiClient.post(
        ApiConstants.messages,
        data: data,
      ),
      fromJson: (json) => Map<String, dynamic>.from(json),
    );
  }

  /// Lấy danh sách conversations của user
  Future<ApiResponse<List<Map<String, dynamic>>>> getConversations(int userId) async {
    return await handleRequestListWithResponse<Map<String, dynamic>>(
      request: () => apiClient.get('${ApiConstants.messages}/conversations'),
      fromJson: (json) => Map<String, dynamic>.from(json),
    );
  }

  /// Đánh dấu tin nhắn đã đọc
  Future<void> markAsRead({
    required int userId,
    required int otherUserId,
    required int postId,
    required int messageId,
  }) async {
    return await handleVoidRequest(
      request: () => apiClient.put(
        '${ApiConstants.messages}/read',
        data: {
          'userId': userId,
          'otherUserId': otherUserId,
          'postId': postId,
          'messageId': messageId,
        },
      ),
    );
  }

  /// Upload hình ảnh cho tin nhắn
  Future<ApiResponse<String>> uploadMessageImage(String filePath) async {
    FormData formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(filePath),
    });

    try {
      final response = await apiClient.dio.post(
        '${ApiConstants.messages}/upload-image',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      // Backend trả về ApiResponse<T> với structure: {status: 200, message: "...", data: imageUrl}
      final responseData = response.data;
      
      if (responseData is Map<String, dynamic>) {
        // Kiểm tra nếu đã là ApiResponse structure
        if (responseData.containsKey('data')) {
          final imageUrl = responseData['data'] as String?;
          if (imageUrl != null && imageUrl.isNotEmpty) {
            return ApiResponse<String>(
              status: responseData['status'] as int? ?? 200,
              message: responseData['message'] as String? ?? 'Upload thành công',
              data: imageUrl,
            );
          }
        }
        // Fallback: thử parse trực tiếp nếu data là string
        if (responseData.containsKey('imageUrl')) {
          return ApiResponse<String>(
            status: 200,
            message: 'Upload thành công',
            data: responseData['imageUrl'] as String,
          );
        }
      }

      // Nếu không parse được, throw error
      throw Exception('Không thể parse response từ server');
    } catch (e) {
      // Nếu là DioException, extract message
      if (e is DioException) {
        final errorMessage = e.response?.data?['message'] as String? ?? 
                           e.message ?? 
                           'Lỗi khi upload ảnh';
        throw Exception(errorMessage);
      }
      rethrow;
    }
  }
}
