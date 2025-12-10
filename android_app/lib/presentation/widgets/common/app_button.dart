import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_shadows.dart';

/// Widget button dùng chung với scale animation cho mobile
class AppButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double height;
  final IconData? icon;
  final bool useGradient;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height = 54,
    this.icon,
    this.useGradient = false,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  void _onTap() {
    if (widget.onPressed != null && !widget.isLoading) {
      HapticFeedback.lightImpact();
      widget.onPressed!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDisabled = widget.onPressed == null || widget.isLoading;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: _onTap,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: isDisabled ? 0.6 : 1.0,
                child: Container(
                  width: widget.width,
                  height: widget.height,
                  decoration: _buildDecoration(theme),
                  child: Center(child: _buildContent(theme)),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  BoxDecoration _buildDecoration(ThemeData theme) {
    if (widget.isOutlined) {
      final baseColor = widget.textColor ?? AppColors.primary;
      final bg = _isHovered
          ? (widget.backgroundColor ?? baseColor.withValues(alpha: 0.06))
          : (widget.backgroundColor ?? Colors.transparent);
      return BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: baseColor,
          width: 1.5,
        ),
      );
    }

    if (widget.useGradient) {
      return BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: _isHovered ? AppShadows.card : AppShadows.small,
      );
    }

    final base = widget.backgroundColor ?? AppColors.primary;
    final hover = HSLColor.fromColor(base).withLightness(
      (HSLColor.fromColor(base).lightness + 0.06).clamp(0.0, 1.0),
    );
    return BoxDecoration(
      color: _isHovered ? hover.toColor() : base,
      borderRadius: BorderRadius.circular(14),
      boxShadow: _isHovered ? AppShadows.card : AppShadows.small,
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (widget.isLoading) {
      return SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(
            widget.isOutlined
                ? (widget.textColor ?? AppColors.primary)
                : Colors.white,
          ),
        ),
      );
    }

    final textColor = widget.isOutlined
        ? (widget.textColor ?? AppColors.primary)
        : (widget.textColor ?? Colors.white);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.icon != null) ...[
          FaIcon(widget.icon, size: 20, color: textColor),
          const SizedBox(width: 8),
        ],
        Text(
          widget.text,
          style: AppTextStyles.buttonLarge.copyWith(color: textColor),
        ),
      ],
    );
  }
}

