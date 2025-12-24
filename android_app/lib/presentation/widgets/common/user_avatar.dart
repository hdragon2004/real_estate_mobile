import 'package:flutter/material.dart';
import '../../../core/utils/image_url_helper.dart';
import '../../../core/theme/app_colors.dart';

/// Widget hiển thị avatar của user với fallback tự động
/// 
/// - Nếu có avatarUrl, hiển thị ảnh từ URL
/// - Nếu không có hoặc load lỗi, hiển thị chữ cái đầu của tên
/// - Backend đã trả về avatar mặc định (/uploads/avatars/avatar.jpg) nếu user không có avatar
class UserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String name;
  final double radius;
  final Color? backgroundColor;
  final double? fontSize;

  const UserAvatar({
    super.key,
    this.avatarUrl,
    required this.name,
    this.radius = 24,
    this.backgroundColor,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = avatarUrl != null && avatarUrl!.isNotEmpty
        ? ImageUrlHelper.resolveImageUrl(avatarUrl!)
        : null;

    final bgColor = backgroundColor ?? AppColors.primary;
    final displayName = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    final textSize = fontSize ?? (radius * 0.6);

    return CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      backgroundImage: resolvedUrl != null
          ? NetworkImage(resolvedUrl)
          : null,
      onBackgroundImageError: (exception, stackTrace) {
        // Nếu load ảnh lỗi, sẽ hiển thị chữ cái đầu (fallback)
      },
      child: resolvedUrl == null
          ? Text(
              displayName,
              style: TextStyle(
                fontSize: textSize,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
    );
  }
}

/// Widget hiển thị avatar với error handling tốt hơn
/// Sử dụng Image widget với errorBuilder để fallback về chữ cái đầu
class UserAvatarWithFallback extends StatelessWidget {
  final String? avatarUrl;
  final String name;
  final double radius;
  final Color? backgroundColor;
  final double? fontSize;

  const UserAvatarWithFallback({
    super.key,
    this.avatarUrl,
    required this.name,
    this.radius = 24,
    this.backgroundColor,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    // Backend đã trả về avatar mặc định (/uploads/avatars/avatar.jpg) nếu user không có avatar
    // Nên avatarUrl sẽ luôn có giá trị (trừ khi backend chưa set)
    final bgColor = backgroundColor ?? AppColors.primary;
    final displayName = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    final textSize = fontSize ?? (radius * 0.6);

    // Nếu không có avatarUrl, hiển thị chữ cái đầu ngay
    if (avatarUrl == null || avatarUrl!.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: bgColor,
        child: Text(
          displayName,
          style: TextStyle(
            fontSize: textSize,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    // Có avatarUrl (có thể là avatar mặc định hoặc avatar của user)
    // Resolve URL và thử load ảnh
    final resolvedUrl = ImageUrlHelper.resolveImageUrl(avatarUrl!);
    
    if (resolvedUrl.isEmpty) {
      // Nếu không resolve được URL, hiển thị chữ cái đầu
      return CircleAvatar(
        radius: radius,
        backgroundColor: bgColor,
        child: Text(
          displayName,
          style: TextStyle(
            fontSize: textSize,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    // Có URL hợp lệ, thử load ảnh
    return CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      child: ClipOval(
        child: Image.network(
          resolvedUrl,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Fallback về chữ cái đầu nếu load ảnh lỗi
            return Container(
              width: radius * 2,
              height: radius * 2,
              color: bgColor,
              child: Center(
                child: Text(
                  displayName,
                  style: TextStyle(
                    fontSize: textSize,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            // Hiển thị loading indicator khi đang load ảnh
            return Container(
              width: radius * 2,
              height: radius * 2,
              color: bgColor,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

