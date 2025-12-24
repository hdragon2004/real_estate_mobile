import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'appointment_create_dialog.dart';


/// Widget hiển thị phần đặt lịch hẹn trong màn hình chi tiết bài viết
class AppointmentBookingSection extends StatelessWidget {
  final int propertyId;
  final String propertyTitle;
  final String? ownerName;
  final String? ownerPhone;
  final String? ownerEmail;

  const AppointmentBookingSection({
    super.key,
    required this.propertyId,
    required this.propertyTitle,
    this.ownerName,
    this.ownerPhone,
    this.ownerEmail,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 1200;

    // Tính toán padding responsive
    final horizontalPadding = isDesktop
        ? (screenWidth * 0.15).toDouble()
        : (isTablet ? (screenWidth * 0.1).toDouble() : 20.0);
    final verticalPadding = isDesktop ? 32.0 : 24.0;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const FaIcon(
                  FontAwesomeIcons.calendarCheck,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Đặt lịch xem nhà',
                      style: AppTextStyles.h6.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      'Chọn thời gian phù hợp để xem bất động sản',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Gap(20),

          // Benefits
          _buildBenefitItem(
            icon: FontAwesomeIcons.clock,
            title: 'Tiết kiệm thời gian',
            description: 'Chủ động chọn lịch hẹn phù hợp với bạn',
          ),
          const Gap(12),
          _buildBenefitItem(
            icon: FontAwesomeIcons.shieldHalved,
            title: 'An toàn và tin cậy',
            description: 'Lịch hẹn được xác nhận và nhắc nhở tự động',
          ),
          const Gap(12),
          _buildBenefitItem(
            icon: FontAwesomeIcons.userTie,
            title: 'Hỗ trợ chuyên nghiệp',
            description: 'Đội ngũ môi giới hỗ trợ trong suốt quá trình',
          ),
          const Gap(24),

          // Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _navigateToCreateAppointment(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const FaIcon(FontAwesomeIcons.calendarPlus, size: 16),
                  const Gap(8),
                  Text(
                    'Tạo lịch hẹn ngay',
                    style: AppTextStyles.labelLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Contact Info
          if (ownerName != null ||
              ownerPhone != null ||
              ownerEmail != null) ...[
            const Gap(16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Liên hệ trực tiếp',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Gap(12),
                  if (ownerName != null) ...[
                    _buildContactItem(
                      icon: FontAwesomeIcons.user,
                      text: ownerName!,
                    ),
                    const Gap(8),
                  ],
                  if (ownerPhone != null) ...[
                    _buildContactItem(
                      icon: FontAwesomeIcons.phone,
                      text: ownerPhone!,
                      isClickable: true,
                      onTap: () => _launchPhone(context, ownerPhone!),
                    ),
                    const Gap(8),
                  ],
                  if (ownerEmail != null) ...[
                    _buildContactItem(
                      icon: FontAwesomeIcons.envelope,
                      text: ownerEmail!,
                      isClickable: true,
                      onTap: () => _launchEmail(context, ownerEmail!),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: FaIcon(icon, color: AppColors.success, size: 14),
        ),
        const Gap(12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Gap(2),
              Text(
                description,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String text,
    bool isClickable = false,
    VoidCallback? onTap,
  }) {
    return Row(
      children: [
        FaIcon(icon, color: AppColors.primary, size: 14),
        const Gap(8),
        Expanded(
          child: isClickable
              ? GestureDetector(
                  onTap: onTap,
                  child: Text(
                    text,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                )
              : Text(text, style: AppTextStyles.bodySmall),
        ),
      ],
    );
  }

  void _navigateToCreateAppointment(BuildContext context) async {
    // Nếu tạo lịch hẹn thành công, hiển thị thông báo
    final result = await AppointmentCreateDialog.show(
      context,
      propertyId: propertyId,
      propertyTitle: propertyTitle,
    );

    // Nếu tạo lịch hẹn thành công, có thể hiển thị thông báo hoặc cập nhật UI
    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã tạo lịch hẹn thành công!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _launchPhone(BuildContext context, String phone) {
    final uri = Uri(scheme: 'tel', path: phone);
    _launchUrl(context, uri);
  }

  void _launchEmail(BuildContext context, String email) {
    final uri = Uri(scheme: 'mailto', path: email);
    _launchUrl(context, uri);
  }

  void _launchUrl(BuildContext context, Uri uri) async {
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể mở ứng dụng'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
