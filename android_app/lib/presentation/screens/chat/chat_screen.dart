import 'package:flutter/material.dart';
import '../../../core/services/image_picker_service.dart';
import '../../../core/repositories/message_repository.dart';
import '../../../core/services/auth_storage_service.dart';
import '../../../core/services/signalr_service.dart';
import '../../../core/utils/image_url_helper.dart' as image_helper;

/// Model cho Message
class MessageModel {
  final String id;
  final String senderId;
  final String content;
  final DateTime timestamp;
  final MessageType type;
  final String? imageUrl;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.content,
    required this.timestamp,
    this.type = MessageType.text,
    this.imageUrl,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'].toString(),
      senderId: json['senderId'].toString(),
      content: json['content'] as String? ?? '',
      timestamp: json['sentTime'] != null
          ? DateTime.parse(json['sentTime'] as String)
          : DateTime.now(),
      type: MessageType.text,
    );
  }
}

enum MessageType {
  text,
  image,
}

/// Màn hình Chat 1-1
class ChatScreen extends StatefulWidget {
  final String chatId;
  final String? userName;
  final String? userAvatar;
  final int? otherUserId;
  final int? postId;
  final String? postTitle;
  final double? postPrice;
  final String? postAddress;

  const ChatScreen({
    super.key,
    required this.chatId,
    this.userName,
    this.userAvatar,
    this.otherUserId,
    this.postId,
    this.postTitle,
    this.postPrice,
    this.postAddress,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final MessageRepository _messageRepository = MessageRepository();
  final SignalRService _signalRService = SignalRService();
  
  bool _isLoading = false;
  List<MessageModel> _messages = [];
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    await _loadUserId();
    await _loadMessages();
    _setupSignalR();
    // Gửi message tự động sau khi đã load messages xong
    await _sendPostInfoMessageIfNeeded();
  }

  /// Tự động gửi message với thông tin post nếu mở chat từ post details và chưa có tin nhắn nào
  Future<void> _sendPostInfoMessageIfNeeded() async {
    // Chỉ gửi nếu có thông tin post và chưa có tin nhắn nào
    if (widget.postTitle != null && 
        widget.postTitle!.isNotEmpty &&
        _messages.isEmpty &&
        _currentUserId != null &&
        widget.otherUserId != null &&
        mounted) {
      // Tạo message với thông tin post
      final postInfo = StringBuffer();
      postInfo.writeln('📋 ${widget.postTitle}');
      if (widget.postPrice != null && widget.postPrice! > 0) {
        postInfo.writeln('💰 Giá: ${_formatPrice(widget.postPrice!)}');
      }
      if (widget.postAddress != null && widget.postAddress!.isNotEmpty) {
        postInfo.writeln('📍 Địa chỉ: ${widget.postAddress}');
      }
      
      // Gửi message tự động
      _messageController.text = postInfo.toString().trim();
      await _sendMessage();
    }
  }

  String _formatPrice(double price) {
    if (price >= 1000000000) {
      return '${(price / 1000000000).toStringAsFixed(1)} tỷ';
    } else if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(0)} triệu';
    } else {
      return '${price.toStringAsFixed(0)} đ';
    }
  }

  /// Thiết lập SignalR để nhận tin nhắn real-time
  Future<void> _setupSignalR() async {
    // Đảm bảo MessageHub đã kết nối
    if (!_signalRService.isMessageHubConnected) {
      await _signalRService.connectMessageHub();
    }

    // Đăng ký callback để nhận tin nhắn real-time
    _signalRService.onMessageReceived = (Map<String, dynamic> messageData) {
      // Kiểm tra xem tin nhắn có phải cho conversation này không
      // ConversationId chỉ dựa trên SenderId và ReceiverId, không có PostId
      final senderId = messageData['senderId'];
      final receiverId = messageData['receiverId'];
      final conversationId = messageData['conversationId'];
      
      // Kiểm tra user match
      final isUserMatch = (senderId == widget.otherUserId && receiverId == _currentUserId) ||
                          (senderId == _currentUserId && receiverId == widget.otherUserId);
      
      // Tạo ConversationId từ currentUserId và otherUserId để so sánh
      String? expectedConversationId;
      if (_currentUserId != null && widget.otherUserId != null) {
        final minId = _currentUserId! < widget.otherUserId! 
            ? _currentUserId! 
            : widget.otherUserId!;
        final maxId = _currentUserId! > widget.otherUserId! 
            ? _currentUserId! 
            : widget.otherUserId!;
        expectedConversationId = '$minId' '_' '$maxId';
      }
      
      // Kiểm tra ConversationId match
      final isConversationMatch = conversationId != null && 
                                   conversationId == expectedConversationId;
      
      // Chỉ xử lý nếu tin nhắn thuộc conversation hiện tại
      if (_currentUserId != null && 
          widget.otherUserId != null &&
          isUserMatch &&
          isConversationMatch) {
        
        // Kiểm tra xem message đã tồn tại chưa (tránh duplicate)
        final messageId = messageData['id']?.toString();
        if (messageId != null && 
            !_messages.any((m) => m.id == messageId)) {
          
          // Thêm message mới vào list
          final newMessage = MessageModel.fromJson(messageData);
          if (mounted) {
            setState(() {
              _messages.add(newMessage);
            });
            _scrollToBottom();
          }
        }
      }
    };
  }

  Future<void> _loadUserId() async {
    final userId = await AuthStorageService.getUserId();
    setState(() {
      _currentUserId = userId;
    });
  }

  Future<void> _loadMessages() async {
    if (widget.otherUserId == null || _currentUserId == null) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Backend endpoint: GET /api/messages/conversation/{otherUserId}
      // ConversationId được tạo từ senderId và receiverId (không có postId)
      // Một conversation có thể chứa tin nhắn về nhiều PostId khác nhau
      final messages = await _messageRepository.getMessages(
        senderId: _currentUserId!,
        receiverId: widget.otherUserId!,
        postId: widget.postId, // Không còn bắt buộc, chỉ để tương thích
      );

      if (!mounted) return;
      setState(() {
        _messages = messages.map((json) => MessageModel.fromJson(json)).toList();
        _isLoading = false;
      });
      
      _scrollToBottom();
    } catch (e) {
      debugPrint('Lỗi khi tải messages: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    // Không disconnect SignalR vì có thể đang dùng ở màn hình khác
    // Chỉ xóa callback để tránh memory leak
    _signalRService.onMessageReceived = null;
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    if (_currentUserId == null || widget.otherUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể gửi tin nhắn')),
      );
      return;
    }

    final content = _messageController.text.trim();
    _messageController.clear();

    // Optimistic update - thêm message vào UI ngay
    final tempMessage = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: _currentUserId.toString(),
      content: content,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(tempMessage);
    });
    _scrollToBottom();

    try {
      // Gửi message qua API (backend sẽ tự động gửi qua SignalR cho receiver)
      // postId có thể null nếu tin nhắn không liên quan đến post
      await _messageRepository.sendMessage(
        senderId: _currentUserId!,
        receiverId: widget.otherUserId!,
        postId: widget.postId ?? 0, // Nếu null thì dùng 0, backend sẽ xử lý
        content: content,
      );

      // Không cần reload vì:
      // 1. Optimistic update đã thêm message vào UI
      // 2. Backend sẽ gửi lại qua SignalR với message ID chính xác
      // 3. Nếu cần, có thể reload để đảm bảo sync
      // await _loadMessages();
    } catch (e) {
      // Nếu gửi thất bại, xóa message tạm
      setState(() {
        _messages.removeWhere((m) => m.id == tempMessage.id);
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi gửi tin nhắn: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendImage() async {
    final image = await ImagePickerService.showImageSourceDialog(context);
    if (image != null) {
      // TODO: Upload ảnh lên server và gửi URL trong message
      if (_currentUserId == null) return;
      final message = MessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: _currentUserId.toString(),
        content: 'Đã gửi ảnh',
        timestamp: DateTime.now(),
        type: MessageType.image,
        imageUrl: image.path, // TODO: Thay bằng URL từ server
      );

      setState(() {
        _messages.add(message);
      });

      _scrollToBottom();
      // TODO: Gửi message qua API/WebSocket
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  bool _isOwnMessage(String senderId) {
    return senderId == _currentUserId.toString();
  }

  String _formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: widget.userAvatar != null && widget.userAvatar!.isNotEmpty
                  ? NetworkImage(image_helper.ImageUrlHelper.resolveImageUrl(widget.userAvatar!))
                  : null,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: widget.userAvatar == null || widget.userAvatar!.isEmpty
                  ? Text(
                      widget.userName != null && widget.userName!.isNotEmpty
                          ? widget.userName![0].toUpperCase()
                          : 'U',
                      style: const TextStyle(color: Colors.white),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.userName ?? 'Người dùng',
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    'Đang hoạt động',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // TODO: Điều hướng đến thông tin người chat
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Post info card (nếu có thông tin post)
          if (widget.postTitle != null && widget.postTitle!.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                      const SizedBox(width: 6),
                      Text(
                        'Thông tin bài đăng',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (widget.postTitle != null && widget.postTitle!.isNotEmpty)
                    Text(
                      widget.postTitle!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  if (widget.postPrice != null && widget.postPrice! > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      '💰 Giá: ${_formatPrice(widget.postPrice!)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                  if (widget.postAddress != null && widget.postAddress!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '📍 ${widget.postAddress}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          // Messages list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Text(
                          'Chưa có tin nhắn',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadMessages,
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            final isOwn = _isOwnMessage(message.senderId);
                            return _MessageBubble(
                              message: message,
                              isOwn: isOwn,
                              time: _formatTime(message.timestamp),
                            );
                          },
                        ),
                      ),
          ),
          // Input area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.image),
                  onPressed: _sendImage,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Nhập tin nhắn...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isOwn;
  final String time;

  const _MessageBubble({
    required this.message,
    required this.isOwn,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isOwn
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.type == MessageType.image && message.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  message.imageUrl!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            else
              Text(
                message.content,
                style: TextStyle(
                  color: isOwn ? Colors.white : Colors.black87,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                fontSize: 10,
                color: isOwn
                    ? Colors.white70
                    : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

