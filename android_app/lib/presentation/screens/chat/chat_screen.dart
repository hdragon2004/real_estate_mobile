import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/services/post_service.dart';
import '../../../core/services/message_service.dart';
import '../../../core/services/auth_storage_service.dart';
import '../../../core/services/signalr_service.dart';
import '../../../core/models/message_model.dart';
import '../../../core/utils/image_url_helper.dart' as image_helper;
import '../../../core/utils/formatters.dart';
import '../../../core/utils/datetime_helper.dart';
import '../../widgets/common/choose_photo.dart';

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
  final MessageService _messageService = MessageService();
  final PostService _postService = PostService();
  final SignalRService _signalRService = SignalRService();
  
  bool _isLoading = false;
  List<MessageModel> _messages = [];
  int? _currentUserId;
  Map<String, dynamic>? _lastSentMessage; // Lưu tin nhắn cuối cùng đã gửi
  File? _selectedImageFile; // Ảnh đã chọn nhưng chưa gửi
  bool _isUploadingImage = false; // Đang upload ảnh
  bool _hasText = false; // Track xem có text trong input không

  @override
  void initState() {
    super.initState();
    _initializeChat();
    // Listen to text changes để update button state
    _messageController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasText = _messageController.text.trim().isNotEmpty;
    if (_hasText != hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
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
        postInfo.writeln('💰 Giá: ${Formatters.formatCurrency(widget.postPrice!)} VNĐ');
      }
      if (widget.postAddress != null && widget.postAddress!.isNotEmpty) {
        postInfo.writeln('📍 Địa chỉ: ${widget.postAddress}');
      }
      
      // Gửi message tự động
      _messageController.text = postInfo.toString().trim();
      await _sendMessage();
    }
  }

  // _formatPrice đã được thay thế bằng Formatters.formatCurrency

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
      final messages = await _messageService.getMessages(
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
    // Remove text change listener
    _messageController.removeListener(_onTextChanged);
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
    // Sử dụng DateTimeHelper để đảm bảo timezone đúng
    final now = DateTimeHelper.getVietnamNow();
    final tempMessage = MessageModel(
      id: now.millisecondsSinceEpoch.toString(),
      senderId: _currentUserId.toString(),
      content: content,
      timestamp: now,
    );

    setState(() {
      _messages.add(tempMessage);
    });
    _scrollToBottom();

    try {
      await _messageService.sendMessage(
        senderId: _currentUserId!,
        receiverId: widget.otherUserId!,
        postId: widget.postId ?? 0, // Nếu null thì dùng 0, backend sẽ xử lý
        content: content,
        imageUrl: null, 
      );

      // Lưu thông tin tin nhắn mới để truyền về ChatListScreen khi pop
      // Sẽ được sử dụng trong dispose hoặc khi pop
      _lastSentMessage = {
        'content': content,
        'timestamp': DateTimeHelper.getVietnamNow(),
      };
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

  Future<void> _pickImage() async {
    // Chọn nguồn ảnh (camera hoặc gallery)
    final source = await showImageSourceDialog(context);
    if (source == null) return;

    // Chọn/chụp ảnh dựa trên nguồn đã chọn
    File? imageFile;
    if (source == 'camera') {
      imageFile = await _postService.takePicture(context);
    } else if (source == 'gallery') {
      final images = await _postService.pickMultipleImagesFromGallery(
        context,
        maxImages: 1,
      );
      if (images.isNotEmpty) {
        imageFile = images.first;
      }
    }
    
    if (imageFile != null && mounted) {
      setState(() {
        _selectedImageFile = imageFile;
      });
    }
  }

  void _removeSelectedImage() {
    setState(() {
      _selectedImageFile = null;
    });
  }

  Future<void> _sendImage() async {
    if (_currentUserId == null || widget.otherUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể gửi hình ảnh')),
      );
      return;
    }

    if (_selectedImageFile == null) {
      // Nếu chưa chọn ảnh, mở dialog chọn ảnh
      await _pickImage();
      return;
    }

    setState(() => _isUploadingImage = true);

    try {
      // Upload ảnh lên server
      final imageUrl = await _messageService.uploadMessageImage(_selectedImageFile!.path);
      
      if (imageUrl.isEmpty) {
        throw Exception('Không nhận được URL ảnh từ server');
      }

      // Lấy content từ text field (có thể rỗng)
      final content = _messageController.text.trim();
   
      final messageContent = content.isNotEmpty ? content : '';
      
      final tempMessage = MessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: _currentUserId.toString(),
        content: messageContent, // Có thể rỗng nếu chỉ gửi ảnh
        timestamp: DateTimeHelper.getVietnamNow(),
        type: MessageType.image,
        imageUrl: imageUrl,
      );

      setState(() {
        _messages.add(tempMessage);
        _selectedImageFile = null; // Xóa ảnh đã chọn
        _messageController.clear(); // Xóa text input
      });
      _scrollToBottom();

      await _messageService.sendMessage(
        senderId: _currentUserId!,
        receiverId: widget.otherUserId!,
        postId: widget.postId ?? 0,
        content: messageContent, 
        imageUrl: imageUrl,
      );

      // Lưu thông tin tin nhắn mới để truyền về ChatListScreen khi pop
      _lastSentMessage = {
        'content': messageContent,
        'timestamp': DateTimeHelper.getVietnamNow(),
        'imageUrl': imageUrl,
      };

      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi gửi hình ảnh: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Truyền thông tin tin nhắn cuối cùng về ChatListScreen nếu có
            if (_lastSentMessage != null && widget.otherUserId != null) {
              Navigator.pop(context, {
                'otherUserId': widget.otherUserId,
                'lastMessage': _lastSentMessage!['content'],
                'lastMessageTime': _lastSentMessage!['timestamp'],
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
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
                      '💰 Giá: ${Formatters.formatCurrency(widget.postPrice!)} VNĐ',
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
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Preview ảnh đã chọn (nếu có)
              if (_selectedImageFile != null)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      // Preview ảnh nhỏ
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _selectedImageFile!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Text thông báo
                      Expanded(
                        child: Text(
                          'Ảnh đã chọn. Nhập nội dung (tùy chọn) và nhấn gửi.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Nút xóa ảnh
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: _removeSelectedImage,
                        color: Colors.grey.shade700,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                    ],
                  ),
                ),
              // Input field và buttons
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
                      onPressed: _pickImage,
                      color: _selectedImageFile != null 
                          ? Theme.of(context).colorScheme.primary 
                          : Colors.grey,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        enabled: !_isUploadingImage,
                        onChanged: (text) {
                          setState(() {
                            _hasText = text.trim().isNotEmpty;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: _selectedImageFile != null 
                              ? 'Nhập nội dung (tùy chọn)...' 
                              : 'Nhập tin nhắn...',
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
                      icon: _isUploadingImage
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              Icons.send,
                              color: (_selectedImageFile != null || _hasText)
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey,
                            ),
                      onPressed: (_isUploadingImage || 
                                 (_selectedImageFile == null && !_hasText))
                          ? null
                          : (_selectedImageFile != null ? _sendImage : _sendMessage),
                    ),
                  ],
                ),
              ),
            ],
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
            if (message.imageUrl != null && message.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  image_helper.ImageUrlHelper.resolveImageUrl(message.imageUrl!),
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 200,
                      color: Colors.grey.shade200,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(Icons.broken_image, size: 48),
                      ),
                    );
                  },
                ),
              ),
            if (message.content.isNotEmpty && 
                !(message.imageUrl != null && message.content == '[Hình ảnh]'))
              Padding(
                padding: EdgeInsets.only(top: message.imageUrl != null ? 8.0 : 0),
                child: Text(
                  message.content,
                  style: TextStyle(
                    color: isOwn ? Colors.white : Colors.black87,
                  ),
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

