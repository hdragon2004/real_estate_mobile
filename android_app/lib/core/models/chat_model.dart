import '../utils/datetime_helper.dart';

class ChatModel {
  final String id; 
  final int userId; 
  final String userName; 
  final String? userAvatar;
  final String lastMessage; 
  final DateTime lastMessageTime; 
  final int unreadCount; 
  final bool isOnline; 
  final int? postId; 
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
    this.postId,
    this.postTitle,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json, int currentUserId) {
    final lastMessage = json['lastMessage'] as Map<String, dynamic>?;
    final otherUserId = json['otherUserId'] as int;
    
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
          ? DateTimeHelper.fromBackendString(lastMessage['sentTime'] as String)
          : DateTimeHelper.getVietnamNow(),
      unreadCount: json['unreadCount'] as int? ?? 0,
      isOnline: false, 
      postId: lastMessage?['postId'] as int?, 
      postTitle: lastMessage?['postTitle'] as String?,
    );
  }
}

