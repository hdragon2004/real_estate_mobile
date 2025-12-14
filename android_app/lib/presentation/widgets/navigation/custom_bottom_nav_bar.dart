import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_shadows.dart';

/// Custom Bottom Navigation Bar - Modern UI
class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onPostTap;
  final bool isScrolling;
  final bool hasUnreadMessages;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onPostTap,
    this.isScrolling = false,
    this.hasUnreadMessages = false,
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
          border: Border(
            top: BorderSide(
              color: AppColors.primary.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _NavItem(
              icon: FontAwesomeIcons.house,
              activeIcon: FontAwesomeIcons.solidHouse,
              label: 'Trang chủ',
              isActive: currentIndex == 0,
              onTap: () => onTap(0),
            ),
            _NavItem(
              icon: FontAwesomeIcons.magnifyingGlass,
              activeIcon: FontAwesomeIcons.magnifyingGlass,
              label: 'Tìm kiếm',
              isActive: currentIndex == 1,
              onTap: () => onTap(1),
            ),
            _PostButton(onTap: onPostTap),
            _NavItem(
              icon: FontAwesomeIcons.message,
              activeIcon: FontAwesomeIcons.solidMessage,
              label: 'Tin nhắn',
              isActive: currentIndex == 2,
              onTap: () => onTap(2),
              hasUnreadDot: hasUnreadMessages,
            ),
            _NavItem(
              icon: FontAwesomeIcons.heart,
              activeIcon: FontAwesomeIcons.solidHeart,
              label: 'Yêu thích',
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
  final bool hasUnreadDot;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.hasUnreadDot = false,
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
                    child: FaIcon(
                      isActive ? activeIcon : icon,
                      size: 24,
                      color: isActive ? AppColors.primary : AppColors.textHint,
                    ),
                  ),
                  if (hasUnreadDot)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
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
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.primary,
            width: 2.0,
          ),
        ),
        child: Center(
          child: FaIcon(
            FontAwesomeIcons.plus,
            color: AppColors.primary,
            size: 24,
          ),
        ),
      ),
    );
  }
}
