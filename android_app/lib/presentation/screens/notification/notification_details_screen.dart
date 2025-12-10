import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/repositories/notification_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/models/notification_model.dart';
import '../post/post_details_screen.dart';
import '../chat/chat_screen.dart';

/// Màn hình Chi tiết thông báo
class NotificationDetailsScreen extends StatefulWidget {
  final NotificationModel notification;

  const NotificationDetailsScreen({
    super.key,
    required this.notification,
  });

  @override
  State<NotificationDetailsScreen> createState() => _NotificationDetailsScreenState();
}

class _NotificationDetailsScreenState extends State<NotificationDetailsScreen> {
  final NotificationRepository _repository = NotificationRepository();
  bool _isMarkingAsRead = false;

  @override
  void initState() {
    super.initState();
    // Đánh dấu đã đọc khi mở màn hình chi tiết
    if (!widget.notification.isRead) {
      _markAsRead();
    }
  }

  Future<void> _markAsRead() async {
    if (widget.notification.isRead || _isMarkingAsRead) return;
    
    setState(() => _isMarkingAsRead = true);
    try {
      await _repository.markAsRead(widget.notification.id);
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    } finally {
      if (mounted) {
        setState(() => _isMarkingAsRead = false);
      }
    }
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.property:
        return FontAwesomeIcons.house;
      case NotificationType.appointment:
        return FontAwesomeIcons.calendarDays;
      case NotificationType.message:
        return FontAwesomeIcons.message;
      case NotificationType.system:
        return FontAwesomeIcons.bell;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.property:
        return AppColors.primary;
      case NotificationType.appointment:
        return AppColors.accent;
      case NotificationType.message:
        return AppColors.primary;
      case NotificationType.system:
        return AppColors.textSecondary;
    }
  }

  String _formatDateTime(DateTime time) {
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
      return '${time.day}/${time.month}/${time.year} ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
  }

  void _handleAction() {
    switch (widget.notification.type) {
      case NotificationType.property:
        if (widget.notification.postId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostDetailsScreen(
                propertyId: widget.notification.postId.toString(),
              ),
            ),
          );
        }
        break;
      case NotificationType.appointment:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tính năng lịch hẹn đang phát triển')),
        );
        break;
      case NotificationType.message:
        if (widget.notification.senderId != null && widget.notification.postId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                chatId: '${widget.notification.senderId}_${widget.notification.postId}',
                otherUserId: widget.notification.senderId,
                postId: widget.notification.postId,
              ),
            ),
          );
        }
        break;
      case NotificationType.system:
        break;
    }
  }

  String _getActionButtonText() {
    switch (widget.notification.type) {
      case NotificationType.property:
        return 'Xem chi tiết bất động sản';
      case NotificationType.appointment:
        return 'Xem lịch hẹn';
      case NotificationType.message:
        return 'Mở tin nhắn';
      case NotificationType.system:
        return '';
    }
  }

  bool _hasAction() {
    return widget.notification.type != NotificationType.system ||
        (widget.notification.postId != null || widget.notification.senderId != null);
  }

  @override
  Widget build(BuildContext context) {
    final color = _getNotificationColor(widget.notification.type);
    final icon = _getNotificationIcon(widget.notification.type);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('Chi tiết thông báo', style: AppTextStyles.h6),
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header với icon và title
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                boxShadow: AppShadows.card,
              ),
              child: Column(
                children: [
                  // Icon
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: FaIcon(
                        icon,
                        color: color,
                        size: 32,
                      ),
                    ),
                  ),
                  const Gap(16),
                  // Title
                  Text(
                    widget.notification.title,
                    style: AppTextStyles.h5.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Gap(8),
                  // Timestamp
                  Text(
                    _formatDateTime(widget.notification.timestamp),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Gap(16),
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nội dung',
                    style: AppTextStyles.labelLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Gap(12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.border,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      widget.notification.message,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const Gap(24),
                  // Action button nếu có
                  if (_hasAction() && _getActionButtonText().isNotEmpty)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _handleAction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FaIcon(
                              widget.notification.type == NotificationType.property
                                  ? FontAwesomeIcons.arrowRight
                                  : widget.notification.type == NotificationType.message
                                      ? FontAwesomeIcons.message
                                      : FontAwesomeIcons.calendarDays,
                              size: 16,
                            ),
                            const Gap(8),
                            Text(
                              _getActionButtonText(),
                              style: AppTextStyles.labelLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

