import 'package:flutter/material.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/empty_state.dart';
import '../../../core/repositories/message_repository.dart';
import '../../../core/services/auth_storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/image_url_helper.dart' as image_helper;
import 'chat_screen.dart';

/// Model cho Chat
class ChatModel {
  final String id;
  final int userId;
  final String userName;
  final String? userAvatar;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final bool isOnline;
  final int? postId; // Có thể null nếu tin nhắn không liên quan đến post
  final String? postTitle;

  ChatModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.isOnline = false,
    this.postId, // Có thể null
    this.postTitle,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json, int currentUserId) {
    final lastMessage = json['lastMessage'] as Map<String, dynamic>?;
    final otherUserId = json['otherUserId'] as int;
    
    // Tạo ConversationId chỉ từ userId (không có postId)
    final minId = currentUserId < otherUserId ? currentUserId : otherUserId;
    final maxId = currentUserId > otherUserId ? currentUserId : otherUserId;
    final conversationId = '$minId' '_' '$maxId';
    
    return ChatModel(
      id: conversationId,
      userId: otherUserId,
      userName: json['otherUserName'] as String? ?? 'Người dùng',
      userAvatar: json['otherUserAvatarUrl'] as String?,
      lastMessage: lastMessage?['content'] as String? ?? '',
      lastMessageTime: lastMessage != null && lastMessage['sentTime'] != null
          ? DateTime.parse(lastMessage['sentTime'] as String)
          : DateTime.now(),
      unreadCount: json['unreadCount'] as int? ?? 0,
      isOnline: false, // TODO: Implement online status
      postId: lastMessage?['postId'] as int?, // Có thể null, lấy từ lastMessage
      postTitle: lastMessage?['postTitle'] as String?,
    );
  }
}

/// Màn hình Danh sách cuộc trò chuyện
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final MessageRepository _messageRepository = MessageRepository();
  bool _isLoading = false;
  List<ChatModel> _chats = [];

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    setState(() => _isLoading = true);
    try {
      final userId = await AuthStorageService.getUserId();
      if (userId == null) {
        if (!mounted) return;
        setState(() {
          _chats = [];
          _isLoading = false;
        });
        return;
      }

      // Lấy danh sách conversations từ API
      // Note: Backend hiện tại sử dụng Stream Chat, endpoint này có thể không tồn tại
      // Nếu không có, sẽ trả về danh sách rỗng
      try {
        final conversations = await _messageRepository.getConversations(userId);
        
        if (!mounted) return;
        setState(() {
          _chats = conversations
              .map((json) => ChatModel.fromJson(json, userId))
              .toList();
          _isLoading = false;
        });
      } catch (e) {
        // Nếu endpoint không tồn tại hoặc có lỗi, hiển thị danh sách rỗng
        debugPrint('Lỗi khi tải conversations: $e');
        if (!mounted) return;
        setState(() {
          _chats = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Lỗi khi tải chats: $e');
      if (!mounted) return;
      setState(() {
        _chats = [];
        _isLoading = false;
      });
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Hôm qua';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return '${time.day}/${time.month}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tin nhắn'),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : FutureBuilder<int?>(
              future: AuthStorageService.getUserId(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingIndicator();
                }
                
                final userId = snapshot.data;
                if (userId == null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Yêu cầu đăng nhập',
                          style: AppTextStyles.h6,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Bạn cần đăng nhập để xem và gửi tin nhắn',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/login');
                          },
                          child: const Text('Đăng nhập'),
                        ),
                      ],
                    ),
                  );
                }
                
                return _chats.isEmpty
                    ? const EmptyState(
                        icon: Icons.chat_bubble_outline,
                        title: 'Chưa có tin nhắn',
                        message: 'Bắt đầu trò chuyện với người khác',
                      )
              : RefreshIndicator(
                  onRefresh: _loadChats,
                  child: ListView.builder(
                    itemCount: _chats.length,
                    itemBuilder: (context, index) {
                      final chat = _chats[index];
                      return ListTile(
                        leading: Stack(
                          children: [
                            CircleAvatar(
                              backgroundImage: chat.userAvatar != null && chat.userAvatar!.isNotEmpty
                                  ? NetworkImage(image_helper.ImageUrlHelper.resolveImageUrl(chat.userAvatar!))
                                  : null,
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              child: chat.userAvatar == null || chat.userAvatar!.isEmpty
                                  ? Text(
                                      chat.userName.isNotEmpty ? chat.userName[0].toUpperCase() : 'U',
                                      style: const TextStyle(color: Colors.white),
                                    )
                                  : null,
                            ),
                            if (chat.isOnline)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        title: Text(
                          chat.userName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          chat.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _formatTime(chat.lastMessageTime),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            if (chat.unreadCount > 0) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  chat.unreadCount > 99
                                      ? '99+'
                                      : chat.unreadCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                chatId: chat.id,
                                userName: chat.userName,
                                userAvatar: chat.userAvatar,
                                otherUserId: chat.userId,
                                postId: chat.postId, // Có thể null
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

