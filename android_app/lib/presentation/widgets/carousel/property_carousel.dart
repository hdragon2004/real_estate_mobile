import 'package:flutter/material.dart';
import '../../../core/models/post_model.dart';
import 'property_carousel_card.dart';

/// Carousel widget hiển thị danh sách properties với hiệu ứng scale và peek
/// 
/// Features:
/// - Scroll ngang với PageView
/// - Card ở giữa được căn giữa chính xác
/// - Card hai bên lộ ra một phần (peek effect)
/// - Snap vào giữa khi scroll
/// - Card scale nhẹ theo khoảng cách tới center
class PropertyCarousel extends StatefulWidget {
  final List<PostModel> properties;
  final double height;
  final Function(PostModel)? onTap;
  final Function(PostModel)? onFavoriteTap;
  final Function(int)? isFavorite;

  const PropertyCarousel({
    super.key,
    required this.properties,
    this.height = 160.0,
    this.onTap,
    this.onFavoriteTap,
    this.isFavorite,
  });

  @override
  State<PropertyCarousel> createState() => _PropertyCarouselState();
}

class _PropertyCarouselState extends State<PropertyCarousel> {
  late PageController _pageController;
  int _currentPage = 0;
  static const double _viewportFraction = 0.85;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: _viewportFraction,
      initialPage: _currentPage,
    );
    _pageController.addListener(_onPageChanged);
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageChanged);
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged() {
    final page = _pageController.page?.round() ?? 0;
    if (page != _currentPage) {
      setState(() {
        _currentPage = page;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.properties.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: Center(
          child: Text(
            'Chưa có bất động sản',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: widget.height,
      child: PageView.builder(
        controller: _pageController,
        itemCount: widget.properties.length,
        itemBuilder: (context, index) {
          return PropertyCarouselCard(
            property: widget.properties[index],
            pageController: _pageController,
            pageIndex: index,
            onTap: widget.onTap != null
                ? () => widget.onTap!(widget.properties[index])
                : null,
            onFavoriteTap: widget.onFavoriteTap != null
                ? () => widget.onFavoriteTap!(widget.properties[index])
                : null,
            isFavorite: widget.isFavorite != null
                ? widget.isFavorite!(widget.properties[index].id) ?? false
                : false,
          );
        },
      ),
    );
  }
}

