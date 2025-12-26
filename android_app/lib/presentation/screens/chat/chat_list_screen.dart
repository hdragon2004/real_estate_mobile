import 'package:flutter/material.dart';
import 'dart:async';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/empty_state.dart';
import '../../../core/services/message_service.dart';
import '../../../core/services/auth_storage_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/models/chat_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/image_url_helper.dart' as image_helper;
import 'chat_screen.dart';

/// Màn hình Danh sách cuộc trò chuyện
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final MessageService _messageService = MessageService();
  final NotificationService _notificationService = NotificationService();
  bool _isLoading = false;
  List<ChatModel> _chats = [];
  StreamSubscription<Map<String, dynamic>>? _messageStreamSubscription;

  @override
  void initState() {
    super.initState();
    _loadChats();
    // Lắng nghe tin nhắn mới từ SignalR để cập nhật danh sách chat real-time
    _messageStreamSubscription = _notificationService.messageStream.listen((messageData) {
      // Khi có tin nhắn mới, cập nhật local state thay vì reload từ server
      try {
        final senderId = int.tryParse(messageData['senderId']?.toString() ?? 
                                     messageData['SenderId']?.toString() ?? '0') ?? 0;
        final receiverId = int.tryParse(messageData['receiverId']?.toString() ?? 
                                        messageData['ReceiverId']?.toString() ?? '0') ?? 0;
        final content = messageData['content']?.toString() ?? 
                       messageData['Content']?.toString() ?? '';
        final sentTime = messageData['sentTime']?.toString() ?? 
                        messageData['SentTime']?.toString();
        
        // Lấy currentUserId để xác định otherUserId
        AuthStorageService.getUserId().then((currentUserId) {
          if (currentUserId == null) return;
          
          // Xác định otherUserId (người còn lại trong conversation)
          final otherUserId = senderId == currentUserId ? receiverId : senderId;
          
          if (otherUserId > 0 && content.isNotEmpty) {
            DateTime lastMessageTime;
            if (sentTime != null) {
              final parsed = DateTime.parse(sentTime);
              lastMessageTime = parsed.isUtc ? parsed.toLocal() : parsed;
            } else {
              lastMessageTime = DateTime.now();
            }
            
            // Cập nhật local state
            if (mounted) {
              _updateChatLastMessage(
                otherUserId: otherUserId,
                lastMessage: content,
                lastMessageTime: lastMessageTime,
              );
            }
          }
        });
      } catch (e) {
        debugPrint('Lỗi khi cập nhật chat từ SignalR: $e');
        // Fallback: reload nếu có lỗi
        if (mounted) {
          _loadChats();
        }
      }
    });
  }

  @override
  void dispose() {
    _messageStreamSubscription?.cancel();
    super.dispose();
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
        final conversations = await _messageService.getConversations(userId);
        
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

  /// Cập nhật tin nhắn cuối cùng cho một chat cụ thể mà không cần reload từ server
  void _updateChatLastMessage({
    required int otherUserId,
    required String lastMessage,
    required DateTime lastMessageTime,
  }) {
    setState(() {
      // Tìm chat tương ứng với otherUserId
      final chatIndex = _chats.indexWhere((chat) => chat.userId == otherUserId);
      if (chatIndex != -1) {
        // Cập nhật lastMessage và lastMessageTime
        final updatedChat = ChatModel(
          id: _chats[chatIndex].id,
          userId: _chats[chatIndex].userId,
          userName: _chats[chatIndex].userName,
          userAvatar: _chats[chatIndex].userAvatar,
          lastMessage: lastMessage,
          lastMessageTime: lastMessageTime,
          unreadCount: _chats[chatIndex].unreadCount,
          isOnline: _chats[chatIndex].isOnline,
          postId: _chats[chatIndex].postId,
          postTitle: _chats[chatIndex].postTitle,
        );
        _chats[chatIndex] = updatedChat;
        
        // Sắp xếp lại danh sách để chat có tin nhắn mới nhất lên đầu
        _chats.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
      }
    });
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
                        onTap: () async {
                          // Navigate đến ChatScreen và cập nhật danh sách khi quay lại
                          final result = await Navigator.push(
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
                          
                          // Nếu có thông tin tin nhắn mới từ ChatScreen, cập nhật local state
                          if (mounted && result != null && result is Map<String, dynamic>) {
                            _updateChatLastMessage(
                              otherUserId: result['otherUserId'] as int,
                              lastMessage: result['lastMessage'] as String,
                              lastMessageTime: result['lastMessageTime'] as DateTime,
                            );
                          }
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

