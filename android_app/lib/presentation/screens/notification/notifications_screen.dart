import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/empty_state.dart';
import '../../../core/repositories/notification_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_shadows.dart';
import '../property/property_detail_screen.dart';
import '../chat/chat_screen.dart';

/// Model cho Notification
class NotificationModel {
  final int id;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final NotificationType type;
  final int? postId;
  final int? senderId;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    required this.type,
    this.postId,
    this.senderId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as int,
      title: json['title'] as String,
      message: json['message'] as String,
      timestamp: DateTime.parse(json['createdAt'] as String),
      isRead: json['isRead'] as bool? ?? false,
      type: _parseType(json['type'] as String),
      postId: json['postId'] as int?,
      senderId: json['senderId'] as int?,
    );
  }

  static NotificationType _parseType(String type) {
    switch (type.toLowerCase()) {
      case 'property':
      case 'new_property':
        return NotificationType.property;
      case 'appointment':
      case 'expire':
      case 'expired':
        return NotificationType.appointment;
      case 'message':
        return NotificationType.message;
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

/// Màn hình Danh sách thông báo
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationRepository _repository = NotificationRepository();
  bool _isLoading = false;
  List<NotificationModel> _notifications = [];
  int? _currentUserId; // TODO: Lấy từ auth service

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    // TODO: Lấy userId từ auth
    // _currentUserId = await AuthService.getCurrentUserId();
    // Tạm thời dùng userId = 1
    _currentUserId ??= 1;
    
    setState(() => _isLoading = true);
    try {
      final data = await _repository.getNotifications(_currentUserId!);
      if (!mounted) return;
      
      setState(() {
        _notifications = data.map((json) => NotificationModel.fromJson(json)).toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tải thông báo: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    if (notification.isRead) return;
    
    try {
      await _repository.markAsRead(notification.id);
      if (!mounted) return;
      
      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notification.id);
        if (index >= 0) {
          _notifications[index] = NotificationModel(
            id: notification.id,
            title: notification.title,
            message: notification.message,
            timestamp: notification.timestamp,
            isRead: true,
            type: notification.type,
            postId: notification.postId,
            senderId: notification.senderId,
          );
        }
      });
    } catch (e) {
      debugPrint('Error marking as read: $e');
    }
  }

  Future<void> _deleteNotification(NotificationModel notification, int index) async {
    try {
      await _repository.deleteNotification(notification.id);
      if (!mounted) return;
      
      setState(() {
        _notifications.removeAt(index);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi xóa thông báo: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _handleNotificationTap(NotificationModel notification) {
    _markAsRead(notification);

    switch (notification.type) {
      case NotificationType.property:
        if (notification.postId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PropertyDetailScreen(
                propertyId: notification.postId.toString(),
              ),
            ),
          );
        }
        break;
      case NotificationType.appointment:
        // TODO: Điều hướng đến màn hình lịch hẹn
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tính năng lịch hẹn đang phát triển')),
        );
        break;
      case NotificationType.message:
        if (notification.senderId != null && notification.postId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                chatId: '${notification.senderId}_${notification.postId}',
              ),
            ),
          );
        }
        break;
      case NotificationType.system:
        break;
    }
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.property:
        return Iconsax.home;
      case NotificationType.appointment:
        return Iconsax.calendar;
      case NotificationType.message:
        return Iconsax.message;
      case NotificationType.system:
        return Iconsax.notification;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.property:
        return AppColors.primary;
      case NotificationType.appointment:
        return AppColors.accent;
      case NotificationType.message:
        return Colors.blue;
      case NotificationType.system:
        return AppColors.textSecondary;
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('Thông báo', style: AppTextStyles.h6),
        actions: [
          TextButton(
            onPressed: () {
              // TODO: Mở cài đặt thông báo
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tính năng cài đặt thông báo đang phát triển')),
              );
            },
            child: Text('Cài đặt', style: AppTextStyles.labelMedium),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : _notifications.isEmpty
              ? EmptyState(
                  icon: Iconsax.notification_bing,
                  title: 'Chưa có thông báo',
                  message: 'Bạn sẽ nhận được thông báo tại đây',
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      final color = _getNotificationColor(notification.type);
                      
                      return Dismissible(
                        key: Key(notification.id.toString()),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Iconsax.trash, color: Colors.white),
                        ),
                        onDismissed: (direction) {
                          _deleteNotification(notification, index);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: notification.isRead ? AppColors.border : color.withValues(alpha: 0.3),
                              width: notification.isRead ? 1 : 2,
                            ),
                            boxShadow: AppShadows.card,
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: notification.isRead 
                                    ? color.withValues(alpha: 0.1) 
                                    : color.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _getNotificationIcon(notification.type),
                                color: color,
                                size: 24,
                              ),
                            ),
                            title: Text(
                              notification.title,
                              style: AppTextStyles.labelLarge.copyWith(
                                fontWeight: notification.isRead 
                                    ? FontWeight.normal 
                                    : FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Gap(4),
                                Text(
                                  notification.message,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Gap(8),
                                Text(
                                  _formatTime(notification.timestamp),
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textHint,
                                  ),
                                ),
                              ],
                            ),
                            trailing: notification.isRead
                                ? null
                                : Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                            onTap: () => _handleNotificationTap(notification),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

