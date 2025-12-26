import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/models/notification_model.dart';
import '../post/post_details_screen.dart';
import '../chat/chat_screen.dart';
import '../appointment/appointments_list_screen.dart';

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
  final NotificationService _notificationService = NotificationService();
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
      // Sử dụng NotificationService để đảm bảo state được cập nhật đúng
      await _notificationService.markAsRead(widget.notification.id);
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
        // Navigate đến màn hình lịch hẹn nếu có appointmentId
        if (widget.notification.appointmentId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AppointmentsListScreen(),
            ),
          );
        }
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
                  // Action button nếu có (cho các loại notification khác, không bao gồm appointment)
                  if (widget.notification.type != NotificationType.appointment && 
                      _hasAction() && 
                      _getActionButtonText().isNotEmpty) ...[
                    const Gap(24),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _handleAction,
                        icon: FaIcon(
                          widget.notification.type == NotificationType.property
                              ? FontAwesomeIcons.arrowRight
                              : widget.notification.type == NotificationType.message
                                  ? FontAwesomeIcons.message
                                  : FontAwesomeIcons.calendarDays,
                          size: 16,
                          color: color,
                        ),
                        label: Text(
                          _getActionButtonText(),
                          style: AppTextStyles.labelLarge.copyWith(
                            color: color,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: color,
                          side: BorderSide(
                            color: color,
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

