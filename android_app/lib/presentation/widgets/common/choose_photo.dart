import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Widget dùng chung để hiển thị bottom sheet chọn nguồn ảnh (camera hoặc thư viện)
/// 
/// Trả về:
/// - 'camera' nếu chọn chụp ảnh
/// - 'gallery' nếu chọn từ thư viện
/// - null nếu đóng dialog
Future<String?> showImageSourceDialog(BuildContext context) async {
  return showModalBottomSheet<String>(
    context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textHint,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: FaIcon(
                  FontAwesomeIcons.camera,
                  color: AppColors.primary,
                ),
                title: Text('Chụp ảnh', style: AppTextStyles.labelLarge),
                subtitle: Text(
                  'Chụp ảnh mới từ camera',
                  style: AppTextStyles.bodySmall,
                ),
                onTap: () => Navigator.pop(context, 'camera'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: FaIcon(
                  FontAwesomeIcons.images,
                  color: AppColors.primary,
                ),
                title: Text(
                  'Chọn từ thư viện',
                  style: AppTextStyles.labelLarge,
                ),
                subtitle: Text(
                  'Chọn nhiều ảnh từ thư viện',
                  style: AppTextStyles.bodySmall,
                ),
                onTap: () => Navigator.pop(context, 'gallery'),
              ),
              const Gap(8),
            ],
          ),
        );
      },
    );
  }
