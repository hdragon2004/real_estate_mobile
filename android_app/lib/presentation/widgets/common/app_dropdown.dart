import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Reusable Dropdown Widget
/// 
/// Dùng chung cho tất cả dropdowns trong app để tránh trùng lặp code
/// 
/// Example:
/// ```dart
/// AppDropdown<VietnamProvince>(
///   label: 'Tỉnh/Thành phố',
///   value: selectedProvince,
///   items: provinces,
///   displayText: (p) => p.name,
///   onChanged: (province) => setState(() => selectedProvince = province),
/// )
/// ```
class AppDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<T> items;
  final String Function(T) displayText;
  final void Function(T?)? onChanged;
  final bool enabled;
  final bool isLoading;
  final bool allowNull;
  final String? nullLabel;
  final String? hintText;
  final IconData? icon;

  const AppDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.displayText,
    required this.onChanged,
    this.enabled = true,
    this.isLoading = false,
    this.allowNull = false,
    this.nullLabel,
    this.hintText,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: enabled ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
        const Gap(8),
        Container(
          decoration: BoxDecoration(
            color: enabled ? AppColors.surface : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: enabled ? AppColors.border : AppColors.border.withValues(alpha: 0.5),
            ),
          ),
          child: DropdownButtonFormField<T>(
            // ignore: deprecated_member_use
            value: value,
            items: [
              if (allowNull)
                DropdownMenuItem<T>(
                  value: null,
                  child: Text(
                    nullLabel ?? 'Không chọn',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ...items.map((item) {
                return DropdownMenuItem<T>(
                  value: item,
                  child: Row(
                    children: [
                      if (icon != null) ...[
                        FaIcon(
                          icon,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const Gap(8),
                      ],
                      Expanded(
                        child: Text(
                          displayText(item),
                          style: AppTextStyles.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
            onChanged: enabled && !isLoading ? onChanged : null,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: InputBorder.none,
              hintText: isLoading 
                  ? 'Đang tải...' 
                  : (hintText ?? 'Chọn $label'),
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textHint,
              ),
              prefixIcon: icon != null
                  ? Padding(
                      padding: const EdgeInsets.only(left: 12, right: 8),
                      child: FaIcon(
                        icon,
                        size: 18,
                        color: enabled 
                            ? AppColors.primary 
                            : AppColors.textHint,
                      ),
                    )
                  : null,
            ),
            style: AppTextStyles.bodyMedium,
            icon: isLoading
                ? const Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : const Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: FaIcon(
                      FontAwesomeIcons.chevronDown,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
            isExpanded: true,
          ),
        ),
      ],
    );
  }
}

