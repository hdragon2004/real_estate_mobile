import 'package:flutter/material.dart';
import '../../../core/models/post_model.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_colors.dart';
import '../common/property_card.dart';

class ProfileListings extends StatelessWidget {
  final List<PostModel> posts;
  final VoidCallback? onSeeAll;
  const ProfileListings({super.key, required this.posts, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    final preview = posts.length > 3 ? posts.sublist(0, 3) : posts;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Bài đăng của bạn', style: AppTextStyles.h6),
              const Spacer(),
              if (posts.isNotEmpty)
                TextButton(
                  onPressed: onSeeAll,
                  child: Text('Xem tất cả', style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (preview.isEmpty)
            Text('Chưa có bài đăng', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary))
          else
            Column(
              children: preview
                  .map((p) => PropertyCard(property: p, isCompact: true))
                  .toList(),
            ),
        ],
      ),
    );
  }
}

