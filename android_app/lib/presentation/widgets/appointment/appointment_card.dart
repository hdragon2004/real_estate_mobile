import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Widget card hiển thị thông tin lịch hẹn
/// Tái sử dụng để tránh lặp code
class AppointmentCard extends StatelessWidget {
  final Map<String, dynamic> appointment;
  final String status; // 'confirmed', 'pending', 'rejected'
  final VoidCallback? onConfirm;
  final VoidCallback? onReject;
  final VoidCallback? onNavigateToChat; // Callback để nhắn tin
  final VoidCallback? onViewPost; // Callback để xem chi tiết bài post
  final bool isFirstItem; // Item đầu tiên trong danh sách

  const AppointmentCard({
    super.key,
    required this.appointment,
    required this.status,
    this.onConfirm,
    this.onReject,
    this.onNavigateToChat,
    this.onViewPost,
    this.isFirstItem = false,
  });

  /// Lấy status của appointment
  String _getAppointmentStatus() {
    // Thử cả camelCase và PascalCase vì API có thể trả về một trong hai
    final statusValue = appointment['status'] ?? appointment['Status'];
    if (statusValue == null) return 'PENDING';
    
    // Nếu là string, trả về trực tiếp (uppercase)
    if (statusValue is String) {
      return statusValue.toUpperCase();
    }
    
    // Nếu là int (enum value), convert sang string
    if (statusValue is int) {
      switch (statusValue) {
        case 0:
          return 'PENDING';
        case 1:
          return 'ACCEPTED';
        case 2:
          return 'REJECTED';
        default:
          return 'PENDING';
      }
    }
    
    return 'PENDING';
  }

  /// Lấy màu cho trạng thái lịch hẹn
  Color _getStatusColor() {
    final appointmentStatus = _getAppointmentStatus();

    switch (appointmentStatus) {
      case 'REJECTED':
        return AppColors.error; // Màu đỏ cho "Bị từ chối"
      case 'ACCEPTED':
        return AppColors.success; // Màu xanh cho "Đã chấp nhận"
      case 'PENDING':
      default:
        return AppColors.warning; // Màu vàng cho "Chờ xác nhận"
    }
  }

  /// Lấy text cho trạng thái lịch hẹn
  String _getStatusText() {
    final appointmentStatus = _getAppointmentStatus();

    switch (appointmentStatus) {
      case 'REJECTED':
        return 'Bị từ chối';
      case 'ACCEPTED':
        return 'Đã chấp nhận';
      case 'PENDING':
      default:
        return 'Chờ xác nhận';
    }
  }

  /// Lấy icon cho trạng thái lịch hẹn
  IconData _getStatusIcon() {
    final appointmentStatus = _getAppointmentStatus();

    switch (appointmentStatus) {
      case 'REJECTED':
        return FontAwesomeIcons.circleXmark; // Icon X cho "Bị từ chối"
      case 'ACCEPTED':
        return FontAwesomeIcons.circleCheck; // Icon check cho "Đã chấp nhận"
      case 'PENDING':
      default:
        return FontAwesomeIcons.clock; // Icon đồng hồ cho "Chờ xác nhận"
    }
  }

  /// Format datetime
  /// Backend trả về UTC time, cần convert về local time để hiển thị đúng
  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null) return 'N/A';
    try {
      final parsed = DateTime.parse(dateTimeStr);
      // Nếu là UTC time, convert về local; nếu đã là local thì giữ nguyên
      final localTime = parsed.isUtc ? parsed.toLocal() : parsed;
      return DateFormat('dd/MM/yyyy HH:mm').format(localTime);
    } catch (e) {
      return dateTimeStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final statusText = _getStatusText();
    final statusIcon = _getStatusIcon();
    final postId = appointment['postId']?.toString();
    final appointmentStatus = _getAppointmentStatus();
    final showActionButtons =
        status == 'pending' && appointmentStatus == 'PENDING';

    return Padding(
      padding: EdgeInsets.only(
        top: isFirstItem ? 8 : 8,
        bottom: 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            // Header với status và button nhắn tin
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FaIcon(
                        statusIcon,
                        size: 12,
                        color: statusColor,
                      ),
                      const Gap(4),
                      Text(
                        statusText,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Button nhắn tin (bên phải, ngang với status)
                if (onNavigateToChat != null)
                  OutlinedButton.icon(
                    onPressed: onNavigateToChat,
                    icon: const FaIcon(
                      FontAwesomeIcons.message,
                      size: 10,
                    ),
                    label: Text(
                      'Nhắn tin',
                      style: AppTextStyles.labelSmall.copyWith(
                        fontSize: 10,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      minimumSize: const Size(0, 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
              ],
            ),
            const Gap(8),
            // Title - có thể click để xem chi tiết bài viết
            if (onViewPost != null && postId != null)
              InkWell(
                onTap: onViewPost,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    appointment['title'] ?? 'Không có tiêu đề',
                    style: AppTextStyles.h6.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      fontSize: 15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
            else
              Text(
                appointment['title'] ?? 'Không có tiêu đề',
                style: AppTextStyles.h6.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  fontSize: 15,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            if (appointment['description'] != null &&
                appointment['description'].toString().isNotEmpty) ...[
              const Gap(4),
              Text(
                appointment['description'],
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const Gap(8),
            // Thông tin thời gian và nhắc nhở bên trái, button bên phải
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bên trái: Ngày (trên) và nhắc nhở (dưới)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Thông tin thời gian (ngày)
                      Row(
                        children: [
                          const FaIcon(
                            FontAwesomeIcons.calendarDays,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const Gap(6),
                          Flexible(
                            child: Text(
                              _formatDateTime(
                                appointment['appointmentTime']?.toString(),
                              ),
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      // Thông tin nhắc nhở (dưới ngày)
                      if (appointment['reminderMinutes'] != null) ...[
                        const Gap(6),
                        Row(
                          children: [
                            const FaIcon(
                              FontAwesomeIcons.bell,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const Gap(6),
                            Flexible(
                              child: Text(
                                'Nhắc nhở: ${appointment['reminderMinutes']} phút trước',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                // Bên phải: 2 button tròn (Từ chối và Chấp nhận)
                if (showActionButtons && onReject != null && onConfirm != null) ...[
                  const Gap(12),
                  // Button Từ chối (hình tròn, icon X)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onReject,
                      borderRadius: BorderRadius.circular(23),
                      child: Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.error,
                            width: 1.5,
                          ),
                          color: Colors.white,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 23,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ),
                  const Gap(15),
                  // Button Chấp nhận (hình tròn, icon tích)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onConfirm,
                      borderRadius: BorderRadius.circular(23),
                      child: Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.success,
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 23,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
    );
  }
}

