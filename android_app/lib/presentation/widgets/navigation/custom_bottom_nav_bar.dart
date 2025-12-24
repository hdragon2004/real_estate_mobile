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
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final bottomBarHeight = isTablet ? 80.0 : 70.0;

    return SafeArea(
      top: false,
      child: Container(
        height: bottomBarHeight,
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
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
class _NavItem extends StatefulWidget {
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
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final itemWidth = isTablet ? 80.0 : 64.0;
    final itemHeight = isTablet ? 70.0 : 60.0;
    final iconSize = isTablet ? 28.0 : 24.0;
    final fontSize = isTablet ? 14.0 : 12.0;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: itemWidth,
        height: itemHeight,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Center(
                          child: FaIcon(
                            widget.isActive ? widget.activeIcon : widget.icon,
                            size: iconSize,
                            color: widget.isActive
                                ? AppColors.primary
                                : AppColors.textHint,
                          ),
                        ),
                        if (widget.hasUnreadDot)
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
                );
              },
            ),
            const SizedBox(height: 4),
            Text(
              widget.label,
              style: AppTextStyles.labelSmall.copyWith(
                color: widget.isActive ? AppColors.primary : AppColors.textHint,
                fontWeight: widget.isActive
                    ? FontWeight.w600
                    : FontWeight.normal,
                fontSize: fontSize,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Nút Đăng tin - Floating style
class _PostButton extends StatefulWidget {
  final VoidCallback onTap;

  const _PostButton({required this.onTap});

  @override
  State<_PostButton> createState() => _PostButtonState();
}

class _PostButtonState extends State<_PostButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.85,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final buttonSize = isTablet ? 64.0 : 56.0;
    final iconSize = isTablet ? 28.0 : 24.0;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: buttonSize,
              height: buttonSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: FaIcon(
                  FontAwesomeIcons.plus,
                  color: Colors.white,
                  size: iconSize,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
