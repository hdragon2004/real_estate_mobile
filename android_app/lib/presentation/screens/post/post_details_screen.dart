import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/post_model.dart';
import '../../../core/repositories/post_repository.dart';
import '../../../core/services/favorite_service.dart';
import '../../../core/services/auth_storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/image_url_helper.dart';
import '../../widgets/common/user_avatar.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/appointment/appointment_booking_section.dart';
import 'image_gallery_screen.dart';

/// Màn hình Chi tiết bất động sản
class PostDetailsScreen extends StatefulWidget {
  final String propertyId;
  final PostModel? initialProperty;

  const PostDetailsScreen({
    super.key,
    required this.propertyId,
    this.initialProperty,
  });

  @override
  State<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  final PostRepository _postRepository = PostRepository();
  final FavoriteService _favoriteService = FavoriteService();
  final PageController _imageController = PageController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _titleKey = GlobalKey();

  PostModel? _property;
  bool _isLoading = false;
  int _currentImageIndex = 0;

  // UI state
  bool _isDetailsExpanded = false;
  bool _isDescriptionExpanded = false;

  @override
  void initState() {
    super.initState();
    _property = widget.initialProperty;
    _isLoading = widget.initialProperty == null;
    _loadPropertyDetail(showLoader: widget.initialProperty == null);
  }

  @override
  void dispose() {
    _imageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPropertyDetail({bool showLoader = false}) async {
    if (showLoader) {
      setState(() => _isLoading = true);
    }

    try {
      final id = int.tryParse(widget.propertyId);
      if (id == null) {
        throw Exception('ID bất động sản không hợp lệ');
      }

      final property = await _postRepository.getPostById(id);
      if (!mounted) return;
      setState(() {
        _property = property;
        _isLoading = false;
      });
      _favoriteService.upsert(property);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể tải chi tiết: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _toggleFavorite(PostModel property) async {
    // Kiểm tra đăng nhập trước khi favorite
    final userId = await AuthStorageService.getUserId();
    if (userId == null) {
      _showLoginRequiredDialog(
        'Bạn cần đăng nhập để thêm vào danh sách yêu thích.',
      );
      return;
    }

    HapticFeedback.lightImpact();
    await _favoriteService.toggleFavorite(property, userId);
    setState(() {});
  }

  Future<void> _showLoginRequiredDialog(String message) async {
    if (!mounted) return;
    final shouldLogin = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Yêu cầu đăng nhập', style: AppTextStyles.h6),
        content: Text(message, style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hủy', style: AppTextStyles.labelLarge),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Đăng nhập',
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldLogin == true && mounted && context.mounted) {
      Navigator.pushNamed(context, '/login');
    }
  }

  void _openImageGallery(List<String> images) {
    if (images.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageGalleryScreen(
          images: images,
          initialIndex: _currentImageIndex,
        ),
      ),
    );
  }

  Future<void> _launchPhone(String? phone) async {
    // Kiểm tra đăng nhập trước khi gọi điện
    final userId = await AuthStorageService.getUserId();
    if (userId == null) {
      _showLoginRequiredDialog(
        'Bạn cần đăng nhập để xem số điện thoại và gọi điện.',
      );
      return;
    }

    if (phone == null || phone.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa có số điện thoại liên hệ.')),
      );
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể mở ứng dụng điện thoại.')),
      );
    }
  }

  Future<void> _launchMail(String? email) async {
    if (email == null || email.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Chưa có email liên hệ.')));
      return;
    }
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể mở ứng dụng email.')),
      );
    }
  }

  /// Mở Google Maps với vị trí của bài post
  Future<void> _openGoogleMaps() async {
    final property = _property;
    if (property == null) return;

    String googleMapsUrl;

    // Ưu tiên 1: Sử dụng tọa độ nếu có (chính xác nhất)
    if (property.latitude != null && property.longitude != null) {
      googleMapsUrl =
          'https://maps.google.com/?q=${property.latitude},${property.longitude}';
    } else {
      // Ưu tiên 2: Sử dụng fullAddress nếu có
      String address = '';
      if (property.fullAddress != null && property.fullAddress!.isNotEmpty) {
        address = property.fullAddress!;
      } else if (property.displayAddress.isNotEmpty) {
        address = property.displayAddress;
      } else {
        // Tạo địa chỉ từ các thành phần
        final parts = <String>[];
        if (property.streetName.isNotEmpty) {
          parts.add(property.streetName);
        }
        if (property.wardName != null && property.wardName!.isNotEmpty) {
          parts.add(property.wardName!);
        }
        if (property.districtName != null &&
            property.districtName!.isNotEmpty) {
          parts.add(property.districtName!);
        }
        if (property.cityName != null && property.cityName!.isNotEmpty) {
          parts.add(property.cityName!);
        }
        address = parts.join(', ');
      }

      if (address.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không có thông tin địa chỉ để hiển thị trên bản đồ'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      // Mở với địa chỉ - dùng format đơn giản
      googleMapsUrl =
          'https://maps.google.com/?q=${Uri.encodeComponent(address)}';
    }

    // Mở Google Maps
    try {
      Uri uri;

      // Nếu có tọa độ, thử dùng geo: URI scheme cho Android (ưu tiên mở Google Maps app)
      if (property.latitude != null && property.longitude != null) {
        try {
          uri = Uri.parse(
            'geo:${property.latitude},${property.longitude}?q=${property.latitude},${property.longitude}',
          );
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            return;
          }
        } catch (e) {
          // Nếu geo: không hoạt động, fallback về https
        }
      }

      // Dùng https URL
      uri = Uri.parse(googleMapsUrl);

      // Thử mở với externalApplication (ưu tiên mở app)
      if (await canLaunchUrl(uri)) {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );

        if (!launched && mounted) {
          // Nếu không mở được app, thử mở trong browser
          await launchUrl(uri, mode: LaunchMode.platformDefault);
        }
      } else {
        // Nếu canLaunchUrl trả về false, vẫn thử mở (có thể do Android 11+ package visibility)
        try {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (e) {
          // Nếu externalApplication không được, thử platformDefault
          try {
            await launchUrl(uri, mode: LaunchMode.platformDefault);
          } catch (e2) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Không thể mở Google Maps. Vui lòng cài đặt Google Maps app.',
                ),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi mở Google Maps: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  List<String> _buildImageList(PostModel property) {
    final List<String> urls = property.images
        .map((image) => ImageUrlHelper.resolveImageUrl(image.url))
        .where((url) => url.isNotEmpty)
        .toList();

    if (urls.isEmpty && property.firstImageUrl.isNotEmpty) {
      urls.add(ImageUrlHelper.resolveImageUrl(property.firstImageUrl));
    }
    return urls;
  }

  @override
  Widget build(BuildContext context) {
    final property = _property;

    if (_isLoading && property == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: LoadingIndicator()),
      );
    }

    if (property == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết bất động sản')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Không tìm thấy bất động sản.'),
              const Gap(12),
              AppButton(
                text: 'Thử lại',
                onPressed: () => _loadPropertyDetail(showLoader: true),
                isOutlined: true,
              ),
            ],
          ),
        ),
      );
    }

    final images = _buildImageList(property);

    final isFavorite = _favoriteService.isFavorite(property.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => _loadPropertyDetail(showLoader: false),
        child: Stack(
          children: [
            CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                _buildImageAppBar(property, images, isFavorite),
                SliverToBoxAdapter(
                  child: _buildPrimaryInfo(property, key: _titleKey),
                ),
                SliverToBoxAdapter(child: _buildDetailsSection(property)),
                SliverToBoxAdapter(child: _buildDescription(property)),
                SliverToBoxAdapter(child: _buildAddressAndMap(property)),
                SliverToBoxAdapter(child: _buildFloorPlanSection(property)),
                SliverToBoxAdapter(child: _buildContactCard(property)),
                SliverToBoxAdapter(
                  child: AppointmentBookingSection(
                    propertyId: property.id,
                    propertyTitle: property.title,
                    ownerName: property.user?.name,
                    ownerPhone: property.user?.phone,
                    ownerEmail: property.user?.email,
                  ),
                ),
                const SliverToBoxAdapter(child: Gap(100)),
              ],
            ),
            // Sticky Bottom Action Bar
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildImageAppBar(
    PostModel property,
    List<String> images,
    bool isFavorite,
  ) {
    final screenHeight = MediaQuery.of(context).size.height;
    final expandedHeight = screenHeight * 0.55; // 55% màn hình

    return SliverAppBar(
      expandedHeight: expandedHeight,
      collapsedHeight: kToolbarHeight,
      pinned: true,
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      leading: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const FaIcon(
              FontAwesomeIcons.arrowLeft,
              color: Colors.white,
              size: 18,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            images.isEmpty
                ? Container(
                    color: AppColors.surfaceVariant,
                    child: const FaIcon(
                      FontAwesomeIcons.image,
                      size: 80,
                      color: AppColors.textHint,
                    ),
                  )
                : PageView.builder(
                    controller: _imageController,
                    onPageChanged: (index) =>
                        setState(() => _currentImageIndex = index),
                    itemCount: images.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => _openImageGallery(images),
                        child: Hero(
                          tag: 'property_${property.id}_image_$index',
                          child: CachedNetworkImage(
                            imageUrl: images[index],
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                Container(color: AppColors.surfaceVariant),
                            errorWidget: (context, url, error) => Container(
                              color: AppColors.surfaceVariant,
                              child: const FaIcon(
                                FontAwesomeIcons.image,
                                size: 48,
                                color: AppColors.textHint,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  if (images.length > 1)
                    SmoothPageIndicator(
                      controller: _imageController,
                      count: images.length,
                      effect: const ExpandingDotsEffect(
                        dotHeight: 6,
                        dotWidth: 6,
                        activeDotColor: Colors.white,
                        dotColor: Color(0x66FFFFFF),
                      ),
                    ),
                  const Gap(12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      property.transactionType == TransactionType.sale
                          ? 'Đang bán'
                          : 'Cho thuê',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        // Favorite button với overlay
        SafeArea(
          child: Container(
            margin: const EdgeInsets.only(right: 8, top: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: FaIcon(
                isFavorite
                    ? FontAwesomeIcons.solidHeart
                    : FontAwesomeIcons.heart,
                color: isFavorite ? AppColors.error : Colors.white,
                size: 18,
              ),
              tooltip: 'Yêu thích',
              onPressed: () => _toggleFavorite(property),
            ),
          ),
        ),
        // Share button với overlay
        SafeArea(
          child: Container(
            margin: const EdgeInsets.only(right: 8, top: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const FaIcon(
                FontAwesomeIcons.share,
                color: Colors.white,
                size: 18,
              ),
              tooltip: 'Chia sẻ',
              onPressed: () {
                // TODO: Implement share functionality
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryInfo(PostModel property, {Key? key}) {
    return AnimatedSlide(
      key: key,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      offset: const Offset(0, 0.2),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 600),
        opacity: 1.0,
        child: Transform.translate(
          offset: const Offset(0, -40), // Overlapping với hero image
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  property.title,
                  style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.bold),
                ),
                const Gap(8),
                // Category và Status
                Row(
                  children: [
                    if ((property.categoryName != null &&
                            property.categoryName!.isNotEmpty) ||
                        (property.category != null &&
                            property.category!.name.isNotEmpty))
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          property.categoryName ??
                              property.category?.name ??
                              '',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if ((property.categoryName != null &&
                            property.categoryName!.isNotEmpty) ||
                        (property.category != null &&
                            property.category!.name.isNotEmpty))
                      const SizedBox(width: 8),
                    Text(
                      property.transactionType == TransactionType.sale
                          ? 'For Sale'
                          : 'For Rent',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const Gap(16),
                // Price
                Text(
                  Formatters.formatPriceWithUnit(
                    property.price,
                    property.priceUnit,
                  ),
                  style: AppTextStyles.priceLarge.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Gap(16),
                // Key Stats: Bed, Bath, Garage
                Row(
                  children: [
                    if (property.soPhongNgu != null)
                      Expanded(
                        child: _KeyStatItem(
                          icon: FontAwesomeIcons.bed,
                          label: '${property.soPhongNgu} Bedrooms',
                        ),
                      ),
                    if (property.soPhongNgu != null &&
                        property.soPhongTam != null)
                      const SizedBox(width: 12),
                    if (property.soPhongTam != null)
                      Expanded(
                        child: _KeyStatItem(
                          icon: FontAwesomeIcons.bath,
                          label: '${property.soPhongTam} Bathrooms',
                        ),
                      ),
                    if (property.soPhongTam != null) const SizedBox(width: 12),
                    Expanded(
                      child: _KeyStatItem(
                        icon: FontAwesomeIcons.car,
                        label: '1 Garages', // TODO: Get from property data
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDescription(PostModel property) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Mô tả', style: AppTextStyles.h5),
              const Spacer(),
              if (!_isDescriptionExpanded)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isDescriptionExpanded = true;
                    });
                  },
                  child: Text(
                    'Xem thêm',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          const Gap(12),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: Text(
              property.description,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.6,
              ),
              maxLines: _isDescriptionExpanded ? null : 3,
              overflow: _isDescriptionExpanded
                  ? TextOverflow.visible
                  : TextOverflow.fade,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressAndMap(PostModel property) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Địa chỉ', style: AppTextStyles.h5),
              const Spacer(),
              // Nút mở Google Maps
              TextButton.icon(
                onPressed: _openGoogleMaps,
                icon: const FaIcon(
                  FontAwesomeIcons.locationArrow,
                  size: 14,
                  color: Colors.white,
                ),
                label: Text(
                  'Mở Google Maps',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF4285F4), // Google Maps blue
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const Gap(12),
          // Full Address
          InkWell(
            onTap: _openGoogleMaps,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                property.fullAddress ?? property.displayAddress,
                style: AppTextStyles.bodyMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloorPlanSection(PostModel property) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Mặt bằng', style: AppTextStyles.h5),
              const Spacer(),
              TextButton(
                onPressed: () => _showFloorPlanSheet(property),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Xem mặt bằng',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const Gap(4),
                    const FaIcon(
                      FontAwesomeIcons.chevronRight,
                      size: 12,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Gap(12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const FaIcon(
                          FontAwesomeIcons.bed,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const Gap(8),
                        Text('670 Sqft', style: AppTextStyles.bodyMedium),
                      ],
                    ),
                    const Gap(12),
                    Row(
                      children: [
                        const FaIcon(
                          FontAwesomeIcons.tag,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const Gap(8),
                        Text('\$1,600', style: AppTextStyles.bodyMedium),
                      ],
                    ),
                  ],
                ),
              ),
              const Gap(24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const FaIcon(
                          FontAwesomeIcons.bath,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const Gap(8),
                        Text('530 Sqft', style: AppTextStyles.bodyMedium),
                      ],
                    ),
                    const Gap(12),
                    Row(
                      children: [
                        const FaIcon(
                          FontAwesomeIcons.ruler,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const Gap(8),
                        Text('1345 Sqft', style: AppTextStyles.bodyMedium),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showFloorPlanSheet(PostModel property) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.2,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text('Floor Plans', style: AppTextStyles.h5),
                ),
                const Gap(16),
                // Content
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      Text('First Floor', style: AppTextStyles.h6),
                      const Gap(12),
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'Floor Plan Image',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const Gap(20),
                      // Add more floor plans here
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailsSection(PostModel property) {
    final hasPerM2 = property.priceUnit == PriceUnit.perM2;
    final pricePerSqft = property.areaSize > 0
        ? property.price / property.areaSize
        : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Chi tiết', style: AppTextStyles.h5),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isDetailsExpanded = !_isDetailsExpanded;
                  });
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Xem chi tiết',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const Gap(4),
                    AnimatedRotation(
                      turns: _isDetailsExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: const FaIcon(
                        FontAwesomeIcons.chevronDown,
                        size: 12,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Gap(12),
          Column(
            children: [
              _DetailRow(
                label: 'Mã bất động sản:',
                value: property.id.toString(),
              ),
              const Gap(12),
              _DetailRow(
                label: 'Giá chính:',
                value: Formatters.formatPriceWithUnit(
                  property.price,
                  property.priceUnit,
                ),
              ),
              if (hasPerM2 || pricePerSqft > 0) ...[
                const Gap(12),
                _DetailRow(
                  label: 'Đơn giá theo diện tích:',
                  value: '\$${pricePerSqft.toStringAsFixed(0)}/sq ft',
                ),
              ],
              const Gap(12),
              _DetailRow(
                label: 'Loại bất động sản:',
                value:
                    property.categoryName ?? property.category?.name ?? 'N/A',
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: _isDetailsExpanded
                    ? Column(
                        children: [
                          const Gap(12),
                          _DetailRow(
                            label: 'Diện tích',
                            value: Formatters.formatArea(property.areaSize),
                          ),
                          if (property.soTang != null) ...[
                            const Gap(12),
                            _DetailRow(
                              label: 'Số tầng',
                              value: '${property.soTang}',
                            ),
                          ],
                          if (property.duongVao != null) ...[
                            const Gap(12),
                            _DetailRow(
                              label: 'Đường vào',
                              value: '${property.duongVao} m',
                            ),
                          ],
                          if (property.huongNha != null &&
                              property.huongNha!.isNotEmpty) ...[
                            const Gap(12),
                            _DetailRow(
                              label: 'Hướng nhà',
                              value: property.huongNha!,
                            ),
                          ],
                          if (property.huongBanCong != null &&
                              property.huongBanCong!.isNotEmpty) ...[
                            const Gap(12),
                            _DetailRow(
                              label: 'Hướng ban công',
                              value: property.huongBanCong!,
                            ),
                          ],
                          if (property.matTien != null) ...[
                            const Gap(12),
                            _DetailRow(
                              label: 'Mặt tiền',
                              value: '${property.matTien} m',
                            ),
                          ],
                          if (property.phapLy != null &&
                              property.phapLy!.isNotEmpty) ...[
                            const Gap(12),
                            _DetailRow(
                              label: 'Pháp lý',
                              value: property.phapLy!,
                            ),
                          ],
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(PostModel property) {
    final user = property.user;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Thông tin liên hệ', style: AppTextStyles.h5),
          const Gap(16),
          Row(
            children: [
              UserAvatarWithFallback(
                avatarUrl: user?.avatarUrl,
                name: user?.name ?? 'Người dùng',
                radius: 32,
                fontSize: 20,
              ),
              const Gap(16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.name ?? 'Môi giới',
                      style: AppTextStyles.h6.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      user?.role ?? 'Môi giới',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _launchMail(user?.email),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const FaIcon(
                    FontAwesomeIcons.envelope,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _launchPhone(user?.phone),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const FaIcon(
                    FontAwesomeIcons.phone,
                    color: AppColors.success,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _KeyStatItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _KeyStatItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(icon, size: 16, color: AppColors.textSecondary),
          const Gap(8),
          Flexible(
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}