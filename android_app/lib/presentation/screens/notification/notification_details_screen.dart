import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/repositories/notification_repository.dart';
import '../../../core/repositories/appointment_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/models/notification_model.dart';
import '../../widgets/common/app_button.dart';
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
  final AppointmentRepository _appointmentRepository = AppointmentRepository();
  bool _isMarkingAsRead = false;
  bool _isProcessing = false;

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

  bool _isAppointmentRequest() {
    // Kiểm tra xem có phải là yêu cầu lịch hẹn cần chấp nhận không
    return widget.notification.type == NotificationType.appointment &&
           widget.notification.appointmentId != null &&
           widget.notification.title.contains('Yêu cầu lịch hẹn');
  }

  Future<void> _confirmAppointment() async {
    if (widget.notification.appointmentId == null || _isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      await _appointmentRepository.confirmAppointment(widget.notification.appointmentId!);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã chấp nhận lịch hẹn'),
          backgroundColor: AppColors.success,
        ),
      );
      
      Navigator.pop(context); // Quay lại màn hình trước
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi chấp nhận lịch hẹn: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _rejectAppointment() async {
    if (widget.notification.appointmentId == null || _isProcessing) return;

    // Xác nhận trước khi từ chối
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xác nhận', style: AppTextStyles.h6),
        content: Text(
          'Bạn có chắc chắn muốn từ chối lịch hẹn này?',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hủy', style: AppTextStyles.labelLarge),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Từ chối',
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);

    try {
      await _appointmentRepository.rejectAppointment(widget.notification.appointmentId!);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã từ chối lịch hẹn'),
          backgroundColor: AppColors.error,
        ),
      );
      
      Navigator.pop(context); // Quay lại màn hình trước
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi từ chối lịch hẹn: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
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
                  // Nút chấp nhận/từ chối cho appointment request
                  if (_isAppointmentRequest())
                    Column(
                      children: [
                        // Nút nhắn tin với user tạo appointment
                        if (widget.notification.senderId != null && widget.notification.postId != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: SizedBox(
                              width: double.infinity,
                              child: AppButton(
                                text: 'Nhắn tin với người đặt lịch',
                                onPressed: () {
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
                                },
                                icon: FontAwesomeIcons.message,
                                isOutlined: true,
                                textColor: AppColors.primary,
                              ),
                            ),
                          ),
                        Row(
                          children: [
                            Expanded(
                              child: AppButton(
                                text: 'Chấp nhận',
                                onPressed: _isProcessing ? null : _confirmAppointment,
                                isLoading: _isProcessing,
                                backgroundColor: AppColors.success,
                              ),
                            ),
                            const Gap(12),
                            Expanded(
                              child: AppButton(
                                text: 'Từ chối',
                                onPressed: _isProcessing ? null : _rejectAppointment,
                                isOutlined: true,
                                textColor: AppColors.error,
                                backgroundColor: Colors.transparent,
                              ),
                            ),
                          ],
                        ),
                        const Gap(16),
                      ],
                    ),
                  // Action button nếu có (cho các loại notification khác)
                  if (!_isAppointmentRequest() && _hasAction() && _getActionButtonText().isNotEmpty)
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

