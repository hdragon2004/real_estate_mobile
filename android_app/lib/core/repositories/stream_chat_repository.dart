import 'package:dio/dio.dart';
import '../models/stream_chat_models.dart';
import '../network/api_client.dart';
import '../constants/api_constants.dart';

/// Repository cho Stream Chat API endpoints
/// Hỗ trợ các operations mobile-specific
class StreamChatRepository {
  final ApiClient _apiClient = ApiClient();

  /// Lấy danh sách channels cho mobile với pagination
  Future<MobileChannelsResponse> getMobileChannels({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.chat}/channels/mobile',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      return MobileChannelsResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Lấy tổng số tin nhắn chưa đọc
  Future<UnreadCountResponse> getUnreadCount() async {
    try {
      final response = await _apiClient.get('${ApiConstants.chat}/unread-count');
      
      return UnreadCountResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Upload file/image cho Stream Chat
  Future<UploadResponse> uploadFile({
    required String filePath,
    required String fileName,
    String? channelId,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
        if (channelId != null) 'channelId': channelId,
      });

      final response = await _apiClient.dio.post(
        '${ApiConstants.chat}/upload/mobile',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
            'Accept': 'application/json',
          },
        ),
      );

      return UploadResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Sync data giữa mobile và server
  Future<SyncResponse> syncData({
    required DateTime lastSyncTime,
    Map<String, dynamic>? localChanges,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.chat}/sync',
        data: {
          'lastSyncTime': lastSyncTime.toIso8601String(),
          'localChanges': localChanges,
        },
      );

      return SyncResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }
}
