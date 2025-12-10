import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/models/post_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/image_url_helper.dart';

/// Widget card hiển thị thông tin bất động sản - Modern UI
class PropertyCard extends StatelessWidget {
  final PostModel property;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteTap;
  final bool isFavorite;
  final bool isCompact;

  const PropertyCard({
    super.key,
    required this.property,
    this.onTap,
    this.onFavoriteTap,
    this.isFavorite = false,
    this.isCompact = false,
  });

  String? _getImageUrl() {
    if (property.images.isNotEmpty) {
      final imageUrl = property.images.first.url;
      return ImageUrlHelper.resolveImageUrl(imageUrl);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _getImageUrl();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Section
              Stack(
                children: [
                  // Property Image
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: imageUrl != null
                        ? Hero(
                            tag: 'property_${property.id}_image_0',
                            child: CachedNetworkImage(
                              imageUrl: imageUrl,
                              height: isCompact ? 140 : 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => _buildShimmer(),
                              errorWidget: (context, url, error) => _buildPlaceholder(),
                            ),
                          )
                        : _buildPlaceholder(),
                  ),
                  
                  // Gradient overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            const Color(0x80000000), // 50% black
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Category Badge
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        property.transactionType == TransactionType.sale ? 'Bán' : 'Cho thuê',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  
                  // Favorite Button
                  Positioned(
                    top: 12,
                    right: 12,
                    child: _FavoriteButton(
                      isFavorite: isFavorite,
                      onTap: onFavoriteTap,
                    ),
                  ),
                  
                  // Price Badge
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: AppShadows.small,
                      ),
                      child: Text(
                        Formatters.formatPriceWithUnit(property.price, property.priceUnit),
                        style: AppTextStyles.priceMedium.copyWith(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
              
              // Content Section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      property.title,
                      style: AppTextStyles.h6,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Location
                    Row(
                      children: [
                        Icon(
                          FontAwesomeIcons.locationDot,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            property.displayAddress,
                            style: AppTextStyles.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Property Features
                    Row(
                      children: [
                        if (property.soPhongNgu != null)
                          _buildFeatureChip(
                            Icons.bed_outlined,
                            '${property.soPhongNgu}',
                          ),
                        if (property.soPhongNgu != null) const SizedBox(width: 12),
                        if (property.soPhongTam != null)
                          _buildFeatureChip(
                            Icons.bathroom_outlined,
                            '${property.soPhongTam}',
                          ),
                        if (property.soPhongTam != null) const SizedBox(width: 12),
                        _buildFeatureChip(
                          FontAwesomeIcons.ruler,
                          '${property.areaSize.toStringAsFixed(0)} m²',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceVariant,
      highlightColor: Colors.white,
      child: Container(
        height: isCompact ? 140 : 180,
        color: AppColors.surfaceVariant,
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: isCompact ? 140 : 180,
      color: AppColors.surfaceVariant,
      child: const Center(
        child: FaIcon(
          FontAwesomeIcons.image,
          size: 48,
          color: AppColors.textHint,
        ),
      ),
    );
  }

  Widget _buildFeatureChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Animated Favorite Button
class _FavoriteButton extends StatefulWidget {
  final bool isFavorite;
  final VoidCallback? onTap;

  const _FavoriteButton({
    required this.isFavorite,
    this.onTap,
  });

  @override
  State<_FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<_FavoriteButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward().then((_) => _controller.reverse());
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: AppShadows.small,
        ),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Icon(
            widget.isFavorite ? Icons.favorite : Icons.favorite_outline,
            size: 20,
            color: widget.isFavorite ? AppColors.error : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// Shimmer Loading Card
class PropertyCardShimmer extends StatelessWidget {
  const PropertyCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.card,
      ),
      child: Shimmer.fromColors(
        baseColor: AppColors.surfaceVariant,
        highlightColor: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 180,
              decoration: const BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 20,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 16,
                    width: 200,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: List.generate(
                      3,
                      (index) => Container(
                        margin: const EdgeInsets.only(right: 12),
                        height: 16,
                        width: 50,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

