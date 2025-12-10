import 'package:flutter/material.dart';
import '../../../core/services/image_picker_service.dart';
import '../../../core/repositories/message_repository.dart';
import '../../../core/services/auth_storage_service.dart';
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

  const ChatScreen({
    super.key,
    required this.chatId,
    this.userName,
    this.userAvatar,
    this.otherUserId,
    this.postId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final MessageRepository _messageRepository = MessageRepository();
  
  bool _isLoading = false;
  List<MessageModel> _messages = [];
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _loadMessages();
  }

  Future<void> _loadUserId() async {
    final userId = await AuthStorageService.getUserId();
    setState(() {
      _currentUserId = userId;
    });
  }

  Future<void> _loadMessages() async {
    if (widget.otherUserId == null || widget.postId == null || _currentUserId == null) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      final messages = await _messageRepository.getMessages(
        senderId: _currentUserId!,
        receiverId: widget.otherUserId!,
        postId: widget.postId!,
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
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    if (_currentUserId == null || widget.otherUserId == null || widget.postId == null) {
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
      // Gửi message qua API
      await _messageRepository.sendMessage(
        senderId: _currentUserId!,
        receiverId: widget.otherUserId!,
        postId: widget.postId!,
        content: content,
      );

      // Reload messages để có message ID chính xác từ server
      await _loadMessages();
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

