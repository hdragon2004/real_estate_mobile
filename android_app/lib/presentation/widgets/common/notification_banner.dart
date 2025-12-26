import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/models/notification_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Widget hiển thị banner thông báo ở phía trên màn hình
/// - Tự động ẩn sau 3 giây
/// - Có thể vuốt lên để tắt
/// - Click vào banner để xem chi tiết
class NotificationBanner extends StatefulWidget {
  final NotificationModel notification;
  final VoidCallback? onView;
  final VoidCallback? onDismiss;

  const NotificationBanner({
    super.key,
    required this.notification,
    this.onView,
    this.onDismiss,
  });

  @override
  State<NotificationBanner> createState() => _NotificationBannerState();
}

class _NotificationBannerState extends State<NotificationBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  bool _isDismissed = false;

  @override
  void initState() {
    super.initState();
    
    // Animation controller cho slide up/down
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1), // Bắt đầu từ trên (ẩn)
      end: Offset.zero, // Hiển thị ở vị trí bình thường
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    // Bắt đầu animation hiển thị
    _controller.forward();

    // Tự động ẩn sau 3 giây
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && !_isDismissed) {
        _dismiss();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    if (_isDismissed) return;
    _isDismissed = true;
    
    // Animation ẩn (slide lên trên)
    _controller.reverse().then((_) {
      if (mounted) {
        widget.onDismiss?.call();
      }
    });
  }

  /// Lấy icon tương ứng với loại thông báo
  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.appointment:
        return FontAwesomeIcons.calendarDays;
      case NotificationType.property:
        return FontAwesomeIcons.house;
      case NotificationType.message:
        return FontAwesomeIcons.message;
      default:
        return FontAwesomeIcons.bell;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: GestureDetector(
        // Click vào banner để xem chi tiết
        onTap: () {
          widget.onView?.call();
          _dismiss();
        },
        // Cho phép vuốt lên để tắt
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null && details.primaryVelocity! < -500) {
            // Vuốt lên (velocity < 0) với tốc độ đủ nhanh
            _dismiss();
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon thông báo
              FaIcon(
                _getNotificationIcon(widget.notification.type),
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              // Nội dung thông báo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.notification.title,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.notification.message.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.notification.message,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

