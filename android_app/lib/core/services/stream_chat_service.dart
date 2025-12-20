import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../config/app_config.dart';
import '../models/stream_chat_models.dart';
import '../repositories/stream_chat_repository.dart';
import '../network/api_client.dart';
import '../constants/api_constants.dart';
import 'auth_storage_service.dart';

/// Service quản lý Stream Chat integration cho mobile app
/// Hỗ trợ offline persistence, real-time messaging, và cross-platform sync
class StreamChatService {
  static final StreamChatService _instance = StreamChatService._internal();
  factory StreamChatService() => _instance;
  StreamChatService._internal();

  StreamChatClient? _client;
  StreamChatClient? get client => _client;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  User? _currentUser;
  User? get currentUser => _currentUser;

  final StreamChatRepository _streamChatRepository = StreamChatRepository();
  final ApiClient _apiClient = ApiClient();

  /// Khởi tạo Stream Chat client với offline persistence
  Future<void> initialize() async {
    try {
      if (_client != null) {
        debugPrint('[StreamChat] Client already initialized');
        return;
      }

      // Lấy API key từ config, nếu là placeholder thì bỏ qua khởi tạo
      final apiKey = AppConfig.streamChatApiKey;
      if (apiKey.isEmpty || apiKey == 'x6me5kuj9y2n') {
        debugPrint(
          '[StreamChat] API key missing/placeholder, delaying client init until user connect',
        );
        return;
      }

      // Tạo client với persistence cho offline support
      _client = StreamChatClient(
        apiKey,
        logLevel: kDebugMode ? Level.INFO : Level.WARNING,
      );

      debugPrint('[StreamChat] Client initialized successfully');
    } catch (e) {
      debugPrint('[StreamChat] Error initializing client: $e');
      rethrow;
    }
  }

  /// Kết nối user với Stream Chat
  Future<void> connectUser() async {
    try {
      // Lấy user info từ auth storage
      final userId = await AuthStorageService.getUserId();
      final token = await AuthStorageService.getToken();
      final userName = await AuthStorageService.getUserName();

      if (userId == null || token == null) {
        throw Exception('User not authenticated');
      }

      // Lấy Stream Chat token và API key từ backend
      final auth = await _getStreamChatAuth(userId, userName);
      final streamToken = (auth['token'] ?? auth['Token']) as String;
      final streamApiKey =
          ((auth['apiKey'] ?? auth['ApiKey']) as String?) ??
          AppConfig.streamChatApiKey;

      if (_client == null) {
        _client = StreamChatClient(
          streamApiKey,
          logLevel: kDebugMode ? Level.INFO : Level.WARNING,
        );
      }

      // Tạo user object
      final user = User(
        id: userId.toString(),
        name: userName ?? 'Người dùng',
        // Thêm avatar nếu có
      );

      // Kết nối với Stream Chat
      await _client!.connectUser(user, streamToken);

      _currentUser = user;
      _isConnected = true;

      debugPrint('[StreamChat] User connected: ${user.id}');
    } catch (e) {
      debugPrint('[StreamChat] Error connecting user: $e');
      rethrow;
    }
  }

  /// Lấy Stream Chat token và API key từ backend
  Future<Map<String, dynamic>> _getStreamChatAuth(
    int userId,
    String? userName,
  ) async {
    try {
      // Gọi API để lấy Stream Chat token
      final response = await _apiClient.post(
        ApiConstants.chatToken,
        data: {'userId': userId, 'userName': userName},
      );

      if (response is Map<String, dynamic>) {
        return response;
      }
      throw Exception('Invalid response format');
    } catch (e) {
      debugPrint('[StreamChat] Error getting auth: $e');
      rethrow;
    }
  }

  /// Lấy danh sách channels của user
  Stream<List<Channel>> getChannels({int limit = 20, int offset = 0}) {
    if (_client == null || !_isConnected || _currentUser == null) {
      // Trả stream rỗng nếu chưa sẵn sàng; caller nên kiểm tra và gọi connectUser trước
      return Stream<List<Channel>>.value(const []);
    }
    final filter = Filter.in_('members', [_currentUser!.id]);
    return _client!.queryChannels(
      filter: filter,
      paginationParams: PaginationParams(limit: limit, offset: offset),
    );
  }

  /// Tạo hoặc lấy channel giữa 2 users
  Future<Channel> getOrCreateChannel({
    required String otherUserId,
    String? postId,
    String? postTitle,
  }) async {
    try {
      if (!_isConnected) {
        await connectUser();
      }

      // Tạo channel ID unique
      final memberIds = [_currentUser!.id, otherUserId]..sort();
      final channelId = postId != null
          ? 'messaging-$postId-${memberIds.join('-')}'
          : 'messaging-${memberIds.join('-')}-${DateTime.now().millisecondsSinceEpoch}';

      // Tạo hoặc lấy channel
      final channel = _client!.channel(
        'messaging',
        id: channelId,
        extraData: {'members': memberIds},
      );

      // Tạo channel trên server
      await channel.create();

      // Update metadata nếu có post info
      if (postId != null || postTitle != null) {
        await channel.updatePartial(
          set: {
            if (postId != null) 'postId': postId,
            if (postTitle != null) 'postTitle': postTitle,
            'name': postTitle != null ? 'Chat về $postTitle' : 'Chat cá nhân',
          },
        );
      }

      return channel;
    } catch (e) {
      debugPrint('[StreamChat] Error creating channel: $e');
      rethrow;
    }
  }

  /// Gửi message vào channel
  Future<void> sendMessage({
    required Channel channel,
    required String text,
    List<Attachment>? attachments,
  }) async {
    try {
      await channel.sendMessage(
        Message(text: text, attachments: attachments ?? const <Attachment>[]),
      );
    } catch (e) {
      debugPrint('[StreamChat] Error sending message: $e');
      rethrow;
    }
  }

  /// Đánh dấu channel đã đọc
  Future<void> markChannelAsRead(Channel channel) async {
    try {
      await channel.markRead();
    } catch (e) {
      debugPrint('[StreamChat] Error marking as read: $e');
      // Không throw error vì đây là operation không critical
    }
  }

  /// Lấy unread count tổng (sử dụng API endpoint)
  Future<int> getTotalUnreadCount() async {
    try {
      final response = await _streamChatRepository.getUnreadCount();
      return response.unreadCount;
    } catch (e) {
      debugPrint('[StreamChat] Error getting unread count via API: $e');
      return 0;
    }
  }

  /// Lấy danh sách channels qua API (mobile-specific)
  Future<MobileChannelsResponse> getMobileChannels({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      return await _streamChatRepository.getMobileChannels(
        page: page,
        limit: limit,
      );
    } catch (e) {
      debugPrint('[StreamChat] Error getting mobile channels via API: $e');
      rethrow;
    }
  }

  /// Upload file cho Stream Chat
  Future<String?> uploadFile({
    required String filePath,
    required String fileName,
    String? channelId,
  }) async {
    try {
      final response = await _streamChatRepository.uploadFile(
        filePath: filePath,
        fileName: fileName,
        channelId: channelId,
      );
      return response.fileUrl;
    } catch (e) {
      debugPrint('[StreamChat] Error uploading file: $e');
      return null;
    }
  }

  /// Setup push notifications
  Future<void> setupPushNotifications(String firebaseToken) async {
    try {
      if (!_isConnected) {
        await connectUser();
      }

      await _client!.addDevice(firebaseToken, PushProvider.firebase);

      debugPrint('[StreamChat] Push notifications setup completed');
    } catch (e) {
      debugPrint('[StreamChat] Error setting up push notifications: $e');
      rethrow;
    }
  }

  /// Send typing event
  Future<void> sendTypingEvent(Channel channel, {bool isTyping = true}) async {
    try {
      if (isTyping) {
        await channel.keyStroke();
      } else {
        await channel.stopTyping();
      }
    } catch (e) {
      debugPrint('[StreamChat] Error sending typing event: $e');
      // Không throw error vì đây là operation không critical
    }
  }

  /// Get online status của user
  bool? getUserOnlineStatus(Channel channel, String userId) {
    final members =
        (channel.state?.members as Map?)?.cast<String, Member>() ??
        <String, Member>{};
    return members[userId]?.user?.online;
  }

  /// Listen to online status changes
  Stream<bool> getUserOnlineStatusStream(Channel channel, String userId) {
    final stream = channel.state?.membersStream;
    if (stream == null) {
      return Stream<bool>.value(false);
    }
    return stream.map(
      (members) =>
          (members as Map<String, Member>)[userId]?.user?.online ?? false,
    );
  }

  /// Get channel member count
  int getChannelMemberCount(Channel channel) {
    final members =
        (channel.state?.members as Map?)?.cast<String, Member>() ??
        <String, Member>{};
    return members.length;
  }

  /// Check if user is in channel
  bool isUserInChannel(Channel channel, String userId) {
    final members =
        (channel.state?.members as Map?)?.cast<String, Member>() ??
        <String, Member>{};
    return members.containsKey(userId);
  }

  /// Ngắt kết nối
  Future<void> disconnect() async {
    try {
      if (_client != null && _isConnected) {
        await _client!.disconnectUser();
        _isConnected = false;
        _currentUser = null;
        debugPrint('[StreamChat] Disconnected');
      }
    } catch (e) {
      debugPrint('[StreamChat] Error disconnecting: $e');
    }
  }

  /// Cleanup resources
  void dispose() {
    disconnect();
    _client = null;
  }
}
