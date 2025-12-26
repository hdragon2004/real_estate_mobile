import '../utils/datetime_helper.dart';

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
    DateTime timestamp;
    if (json['sentTime'] != null) {
      timestamp = DateTimeHelper.fromBackendString(json['sentTime'] as String);
    } else if (json['SentTime'] != null) {
      timestamp = DateTimeHelper.fromBackendString(json['SentTime'] as String);
    } else if (json['timestamp'] != null) {
      timestamp = DateTimeHelper.fromBackendString(json['timestamp'] as String);
    } else {
      timestamp = DateTimeHelper.getVietnamNow(); 
    }
    
    // Xác định loại tin nhắn: nếu có imageUrl thì là image, ngược lại là text
    final imageUrl = json['imageUrl'] ?? json['ImageUrl'];
    final messageType = imageUrl != null && imageUrl.toString().isNotEmpty 
        ? MessageType.image 
        : MessageType.text;
    
    return MessageModel(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      senderId: (json['senderId'] ?? json['SenderId'] ?? '').toString(),
      content: json['content'] ?? json['Content'] ?? '',
      timestamp: timestamp,
      type: messageType,
      imageUrl: imageUrl?.toString(),
    );
  }
}

enum MessageType {
  text, 
  image, 
}

