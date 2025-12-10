import 'package:flutter/material.dart';
import '../../../core/models/post_model.dart';
import '../common/post_card.dart';

/// Card widget cho carousel với hiệu ứng scale theo khoảng cách tới center
class PropertyCarouselCard extends StatefulWidget {
  final PostModel property;
  final PageController pageController;
  final int pageIndex;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteTap;
  final bool isFavorite;

  const PropertyCarouselCard({
    super.key,
    required this.property,
    required this.pageController,
    required this.pageIndex,
    this.onTap,
    this.onFavoriteTap,
    this.isFavorite = false,
  });

  @override
  State<PropertyCarouselCard> createState() => _PropertyCarouselCardState();
}

class _PropertyCarouselCardState extends State<PropertyCarouselCard> {
  double _getScale() {
    if (!widget.pageController.hasClients) return 1.0;

    final page = widget.pageController.page ?? widget.pageIndex.toDouble();
    final difference = (page - widget.pageIndex).abs();
    
    // Scale từ 1.0 (center) xuống 0.9 (card ở xa nhất) - scale nhẹ để mượt hơn
    return (1.0 - (difference * 0.1)).clamp(0.9, 1.0);
  }

  double _getOpacity() {
    if (!widget.pageController.hasClients) return 1.0;

    final page = widget.pageController.page ?? widget.pageIndex.toDouble();
    final difference = (page - widget.pageIndex).abs();
    
    // Opacity từ 1.0 (center) xuống 0.8 (card ở xa nhất)
    return (1.0 - (difference * 0.2)).clamp(0.8, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.pageController,
      builder: (context, child) {
        final scale = _getScale();
        final opacity = _getOpacity();
        final screenWidth = MediaQuery.of(context).size.width;
        final padding = 20.0; // Padding giống như phần "Mới nhất"
        final cardWidth = screenWidth - (padding * 2); // Cùng width với card "Mới nhất"
        
        return Center(
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity,
              child: SizedBox(
                width: cardWidth,
                child: PostCard(
                  property: widget.property,
                  isFavorite: widget.isFavorite,
                  margin: EdgeInsets.zero,
                  onTap: widget.onTap,
                  onFavoriteTap: widget.onFavoriteTap,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

