import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_shadows.dart';

class StatItem {
  final String label;
  final String value;
  final IconData icon;
  const StatItem({required this.label, required this.value, required this.icon});
}

class StatPillGrid extends StatelessWidget {
  final List<StatItem> items;
  const StatPillGrid({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const spacing = 12.0;
          final maxW = constraints.maxWidth;
          int columns = maxW < 360 ? 2 : (maxW < 600 ? 3 : 4);
          final itemWidth = (maxW - spacing * (columns - 1)) / columns;
          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: items
                .map((i) => _StatPill(item: i, width: itemWidth))
                .toList(),
          );
        },
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final StatItem item;
  final double width;
  const _StatPill({required this.item, required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: AppColors.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, size: 18, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.value, style: AppTextStyles.h6),
                const SizedBox(height: 2),
                Text(item.label, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

