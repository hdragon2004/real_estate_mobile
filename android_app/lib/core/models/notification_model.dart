/// Model cho Notification
class NotificationModel {
  final int id;
  final int userId;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final NotificationType type;
  final int? postId;
  final int? senderId;
  final int? savedSearchId; // ID của khu vực tìm kiếm yêu thích
  final int? appointmentId; // ID của lịch hẹn
  final NotificationUser? user;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    required this.type,
    this.postId,
    this.senderId,
    this.savedSearchId,
    this.appointmentId,
    this.user,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    // Xử lý timestamp từ nhiều field có thể có
    DateTime timestamp;
    if (json['createdAt'] != null) {
      timestamp = DateTime.parse(json['createdAt'] as String);
    } else if (json['created'] != null) {
      timestamp = DateTime.parse(json['created'] as String);
    } else if (json['timestamp'] != null) {
      timestamp = DateTime.parse(json['timestamp'] as String);
    } else {
      timestamp = DateTime.now(); // Fallback
    }
    
    return NotificationModel(
      id: json['id'] as int,
      userId: json['userId'] as int? ?? 0,
      title: json['title'] as String? ?? json['message'] as String? ?? 'Thông báo',
      message: json['message'] as String? ?? json['content'] as String? ?? '',
      timestamp: timestamp,
      isRead: json['isRead'] as bool? ?? false,
      type: _parseType(json['type'] as String? ?? 'system'),
      postId: json['postId'] as int?,
      senderId: json['senderId'] as int?,
      savedSearchId: json['savedSearchId'] as int?,
      appointmentId: json['appointmentId'] as int?,
      user: json['user'] != null ? NotificationUser.fromJson(json['user']) : null,
    );
  }

  static NotificationType _parseType(String type) {
    switch (type.toLowerCase()) {
      case 'property':
      case 'new_property':
      case 'savedsearch': // Thông báo tin mới theo khu vực yêu thích
        return NotificationType.property;
      case 'appointment':
      case 'appointmentrequest': // Yêu cầu lịch hẹn mới
      case 'appointmentconfirmed': // Lịch hẹn đã được chấp nhận
      case 'appointmentrejected': // Lịch hẹn đã bị từ chối
      case 'reminder': // Nhắc lịch hẹn
      case 'expire':
      case 'expired':
        return NotificationType.appointment;
      case 'message': // Tin nhắn mới
        return NotificationType.message;
      case 'approved':
      case 'postapproved': // Bài đăng được duyệt
      case 'postpending': // Bài đăng đang chờ duyệt
      case 'favorite': // Bài đăng được thêm vào yêu thích
      case 'welcome': // Thông báo chào mừng
      default:
        return NotificationType.system;
    }
  }
}

enum NotificationType {
  property,
  appointment,
  message,
  system,
}

class NotificationUser {
  final int id;
  final String name;
  final String? email;
  final String? avatarUrl;

  NotificationUser({
    required this.id,
    required this.name,
    this.email,
    this.avatarUrl,
  });

  factory NotificationUser.fromJson(Map<String, dynamic> json) {
    return NotificationUser(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'],
      avatarUrl: json['avatarUrl'],
    );
  }
}

