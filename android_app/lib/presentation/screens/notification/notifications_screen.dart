import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/empty_state.dart';
import '../../../core/models/notification_model.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/auth_storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_shadows.dart';
import 'notification_details_screen.dart';

/// Màn hình Danh sách thông báo
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  bool _isLoading = true; // Bắt đầu với loading = true để hiển thị loading ngay
  bool _isInitialLoad = true; // Flag để phân biệt lần load đầu và refresh
  List<NotificationModel> _notifications = [];
  int? _currentUserId;
  StreamSubscription<NotificationModel>? _notificationStreamSubscription;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    // Lắng nghe thông báo real-time
    _notificationStreamSubscription = _notificationService.notificationStream.listen((notification) {
      if (mounted) {
        setState(() {
          // Kiểm tra xem thông báo đã tồn tại chưa (theo ID) để tránh duplicate
          final existingIndex = _notifications.indexWhere((n) => n.id == notification.id);
          if (existingIndex == -1) {
            // Chỉ thêm nếu chưa tồn tại
            _notifications.insert(0, notification);
          } else {
            // Nếu đã tồn tại, cập nhật thông báo đó
            _notifications[existingIndex] = notification;
          }
          // Sắp xếp lại theo timestamp
          _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        });
      }
    });
  }

  @override
  void dispose() {
    _notificationStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    // Set loading ngay từ đầu (trừ khi đang refresh)
    if (_isInitialLoad) {
      setState(() => _isLoading = true);
    }
    
    // Lấy userId từ AuthStorageService
    try {
      _currentUserId = await AuthStorageService.getUserId();
      if (_currentUserId == null) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _isInitialLoad = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng đăng nhập để xem thông báo'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    } catch (e) {
      debugPrint('Error getting user ID: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isInitialLoad = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi xác thực: $e'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    try {
      await _notificationService.initialize();
      final notifications = _notificationService.notifications;
      if (!mounted) return;
      
      setState(() {
        _notifications = List.from(notifications)
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
        _isLoading = false;
        _isInitialLoad = false; // Đánh dấu đã load xong lần đầu
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      debugPrint('Error loading notifications: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tải thông báo: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _deleteNotification(NotificationModel notification, int index) async {
    try {
      await _notificationService.deleteNotification(notification.id);
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

  void _handleNotificationTap(NotificationModel notification) async {
    // Điều hướng đến màn hình chi tiết thông báo
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationDetailsScreen(
          notification: notification,
        ),
      ),
    );
    
    // Khi quay lại, cập nhật danh sách từ NotificationService
    // để đảm bảo sync với state đã được cập nhật (isRead, etc.)
    if (mounted) {
      setState(() {
        final updatedNotifications = _notificationService.notifications;
        _notifications = List.from(updatedNotifications)
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      });
    }
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.property:
        return FontAwesomeIcons.house;
      case NotificationType.appointment:
        return FontAwesomeIcons.calendar;
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
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Đang tải thông báo...')
          : _notifications.isEmpty
              ? EmptyState(
                  icon: FontAwesomeIcons.bell,
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
                          child: const FaIcon(FontAwesomeIcons.trash, color: Colors.white),
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
                              child: Center(
                                child: FaIcon(
                                _getNotificationIcon(notification.type),
                                color: color,
                                size: 24,
                                ),
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

