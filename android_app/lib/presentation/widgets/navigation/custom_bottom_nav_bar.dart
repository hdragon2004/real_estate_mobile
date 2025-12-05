import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_shadows.dart';

/// Custom Bottom Navigation Bar - Modern UI
class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onPostTap;
  final bool isScrolling;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onPostTap,
    this.isScrolling = false,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: AppShadows.bottomNav,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _NavItem(
              icon: Iconsax.home_2,
              activeIcon: Iconsax.home,
              label: 'Trang chủ',
              isActive: currentIndex == 0,
              onTap: () => onTap(0),
            ),
            _NavItem(
              icon: Iconsax.heart,
              activeIcon: Iconsax.heart,
              label: 'Yêu thích',
              isActive: currentIndex == 1,
              onTap: () => onTap(1),
            ),
            _PostButton(onTap: onPostTap),
            _NavItem(
              icon: Iconsax.message,
              activeIcon: Iconsax.message,
              label: 'Tin nhắn',
              isActive: currentIndex == 2,
              onTap: () => onTap(2),
              badgeCount: 3,
            ),
            _NavItem(
              icon: Iconsax.profile_circle,
              activeIcon: Iconsax.profile_circle,
              label: 'Tài khoản',
              isActive: currentIndex == 3,
              onTap: () => onTap(3),
            ),
          ],
        ),
      ),
    );
  }
}

/// Navigation Item - Modern style
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final int? badgeCount;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        height: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Center(
                    child: Icon(
                      isActive ? activeIcon : icon,
                      size: 24,
                      color: isActive ? AppColors.primary : AppColors.textHint,
                    ),
                  ),
                  if (badgeCount != null && badgeCount! > 0)
                    Positioned(
                      right: -6,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$badgeCount',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: Colors.white,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: isActive ? AppColors.primary : AppColors.textHint,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Nút Đăng tin - Floating style
class _PostButton extends StatelessWidget {
  final VoidCallback onTap;

  const _PostButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          shape: BoxShape.circle,
          boxShadow: AppShadows.floatingButton,
        ),
        child: const Icon(
          Iconsax.add,
          color: Colors.white,
          size: 26,
        ),
      ),
    );
  }
}
