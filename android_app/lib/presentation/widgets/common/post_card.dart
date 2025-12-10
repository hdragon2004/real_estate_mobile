import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/models/post_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/image_url_helper.dart';

/// Widget PostCard dùng chung trong app
/// Design horizontal: ảnh bên trái, content bên phải
class PostCard extends StatelessWidget {
  final PostModel property;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteTap;
  final bool isFavorite;
  final EdgeInsets? margin;

  const PostCard({
    super.key,
    required this.property,
    this.onTap,
    this.onFavoriteTap,
    this.isFavorite = false,
    this.margin,
  });

  String? _getImageUrl() {
    if (property.images.isNotEmpty) {
      final imageUrl = property.images.first.url;
      return ImageUrlHelper.resolveImageUrl(imageUrl);
    }
    return null;
  }

  String _formatPrice(double price, PriceUnit unit) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)} tỷ';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)} triệu';
    }
    return '${price.toStringAsFixed(0)} đ';
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _getImageUrl();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin ?? const EdgeInsets.only(bottom: 16),
        constraints: const BoxConstraints(
          minHeight: 136, // 8px padding top + 120px image + 8px padding bottom
          maxHeight: 136, // Giới hạn chiều cao tối đa
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card nhỏ chứa ảnh - bên trái
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 120,
                            height: 120,
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 120,
                            height: 120,
                            color: Colors.grey.shade200,
                            child: const FaIcon(FontAwesomeIcons.image, color: Colors.grey),
                          ),
                        )
                      : Container(
                          width: 120,
                          height: 120,
                          color: Colors.grey.shade200,
                          child: const FaIcon(FontAwesomeIcons.image, color: Colors.grey),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              // Content - tự động mở rộng - bên phải
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                    // Title và Favorite button
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            property.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (onFavoriteTap != null)
                          GestureDetector(
                            onTap: onFavoriteTap,
                            child: FaIcon(
                              isFavorite ? FontAwesomeIcons.solidHeart : FontAwesomeIcons.heart,
                              size: isFavorite ? 22 : 20,
                              color: isFavorite ? Colors.red : Colors.grey,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Transaction type tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        property.transactionType == TransactionType.sale ? 'Bán' : 'Cho thuê',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Location
                    Row(
                      children: [
                        FaIcon(FontAwesomeIcons.locationDot, size: 12, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            property.displayAddress,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Property features (bedrooms, bathrooms, area)
                    Row(
                      children: [
                        if (property.soPhongNgu != null) ...[
                          FaIcon(FontAwesomeIcons.bed, size: 12, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            '${property.soPhongNgu}',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (property.soPhongTam != null) ...[
                          FaIcon(FontAwesomeIcons.bath, size: 12, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            '${property.soPhongTam}',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                          const SizedBox(width: 8),
                        ],
                        FaIcon(FontAwesomeIcons.ruler, size: 12, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${property.areaSize.toStringAsFixed(0)} m²',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Category và Price
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              property.categoryName?.toUpperCase() ?? 'BẤT N/A',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            _formatPrice(property.price, property.priceUnit),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

