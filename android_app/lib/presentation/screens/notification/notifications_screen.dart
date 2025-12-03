import 'package:flutter/material.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/empty_state.dart';

/// Model cho Notification
class NotificationModel {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final NotificationType type;
  final String? imageUrl;
  final String? actionId; // ID của property, appointment, etc.

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    required this.type,
    this.imageUrl,
    this.actionId,
  });
}

enum NotificationType {
  property,
  appointment,
  message,
  system,
}

/// Màn hình Danh sách thông báo
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = false;
  final List<NotificationModel> _notifications = _getSampleNotifications(); // Dữ liệu mẫu

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    // TODO: Gọi API lấy notifications
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  // Dữ liệu mẫu
  static List<NotificationModel> _getSampleNotifications() {
    return [
      NotificationModel(
        id: '1',
        title: 'Tin nhắn mới',
        message: 'Bạn có tin nhắn mới từ Nguyễn Văn A',
        timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
        isRead: false,
        type: NotificationType.message,
        actionId: 'chat1',
      ),
      NotificationModel(
        id: '2',
        title: 'Bất động sản mới',
        message: 'Có 5 bất động sản mới trong khu vực yêu thích của bạn',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        isRead: false,
        type: NotificationType.property,
      ),
      NotificationModel(
        id: '3',
        title: 'Nhắc lịch hẹn',
        message: 'Bạn có lịch hẹn xem nhà vào ngày mai',
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        isRead: true,
        type: NotificationType.appointment,
      ),
    ];
  }

  void _markAsRead(NotificationModel notification) {
    if (!notification.isRead) {
      setState(() {
        // TODO: Update local state
      });
      // TODO: Gọi API đánh dấu đã đọc
    }
  }

  void _handleNotificationTap(NotificationModel notification) {
    _markAsRead(notification);

    // TODO: Điều hướng dựa trên type
    switch (notification.type) {
      case NotificationType.property:
        // Navigator.pushNamed(context, '/property-detail', arguments: notification.actionId);
        break;
      case NotificationType.appointment:
        // Navigator.pushNamed(context, '/appointment-detail', arguments: notification.actionId);
        break;
      case NotificationType.message:
        // Navigator.pushNamed(context, '/chat', arguments: notification.actionId);
        break;
      case NotificationType.system:
        break;
    }
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.property:
        return Icons.home;
      case NotificationType.appointment:
        return Icons.calendar_today;
      case NotificationType.message:
        return Icons.chat;
      case NotificationType.system:
        return Icons.notifications;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          TextButton(
            onPressed: () {
              // TODO: Mở cài đặt thông báo
              // Navigator.pushNamed(context, '/notification-settings');
            },
            child: const Text('Cài đặt'),
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : _notifications.isEmpty
              ? const EmptyState(
                  icon: Icons.notifications_none,
                  title: 'Chưa có thông báo',
                  message: 'Bạn sẽ nhận được thông báo tại đây',
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return Dismissible(
                        key: Key(notification.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: Colors.red,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (direction) {
                          setState(() {
                            _notifications.removeAt(index);
                          });
                          // TODO: Gọi API xóa notification
                        },
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: notification.isRead
                                ? Colors.grey.shade300
                                : Theme.of(context).colorScheme.primary,
                            child: Icon(
                              _getNotificationIcon(notification.type),
                              color: notification.isRead
                                  ? Colors.grey.shade600
                                  : Colors.white,
                            ),
                          ),
                          title: Text(
                            notification.title,
                            style: TextStyle(
                              fontWeight: notification.isRead
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(notification.message),
                              const SizedBox(height: 4),
                              Text(
                                _formatTime(notification.timestamp),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          trailing: notification.isRead
                              ? null
                              : Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                          onTap: () => _handleNotificationTap(notification),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

