import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../../core/models/post_model.dart';
import '../../../core/repositories/post_repository.dart';
import '../../../core/repositories/appointment_repository.dart';
import '../../../core/services/favorite_service.dart';
import '../../../core/services/auth_storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/image_url_helper.dart';
import '../../widgets/common/user_avatar.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/loading_indicator.dart';
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
  final AppointmentRepository _appointmentRepository = AppointmentRepository();
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
      googleMapsUrl = 'https://maps.google.com/?q=${property.latitude},${property.longitude}';
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
        if (property.districtName != null && property.districtName!.isNotEmpty) {
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
      googleMapsUrl = 'https://maps.google.com/?q=${Uri.encodeComponent(address)}';
    }

    // Mở Google Maps
    try {
      Uri uri;
      
      // Nếu có tọa độ, thử dùng geo: URI scheme cho Android (ưu tiên mở Google Maps app)
      if (property.latitude != null && property.longitude != null) {
        try {
          uri = Uri.parse('geo:${property.latitude},${property.longitude}?q=${property.latitude},${property.longitude}');
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
                content: const Text('Không thể mở Google Maps. Vui lòng cài đặt Google Maps app.'),
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
                SliverToBoxAdapter(child: _buildAppointmentSection(property)),
                SliverToBoxAdapter(child: _buildContactCard(property)),
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
            icon: const FaIcon(FontAwesomeIcons.arrowLeft, color: Colors.white, size: 18),
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
                isFavorite ? FontAwesomeIcons.solidHeart : FontAwesomeIcons.heart,
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
              icon: const FaIcon(FontAwesomeIcons.share, color: Colors.white, size: 18),
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
                style: AppTextStyles.h4.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Gap(8),
              // Category và Status
              Row(
                children: [
                  if ((property.categoryName != null && property.categoryName!.isNotEmpty) ||
                      (property.category != null && property.category!.name.isNotEmpty))
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        property.categoryName ?? property.category?.name ?? '',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if ((property.categoryName != null && property.categoryName!.isNotEmpty) ||
                      (property.category != null && property.category!.name.isNotEmpty))
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
                  if (property.soPhongNgu != null && property.soPhongTam != null)
                    const SizedBox(width: 12),
                  if (property.soPhongTam != null)
                    Expanded(
                      child: _KeyStatItem(
                        icon: FontAwesomeIcons.bath,
                        label: '${property.soPhongTam} Bathrooms',
                      ),
                    ),
                  if (property.soPhongTam != null)
                    const SizedBox(width: 12),
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
              Text('Description', style: AppTextStyles.h5),
              const Spacer(),
              if (!_isDescriptionExpanded)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isDescriptionExpanded = true;
                    });
                  },
                  child: Text(
                    'Read More',
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
              Text('Address', style: AppTextStyles.h5),
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
                  'Google Maps',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF4285F4), // Google Maps blue
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              Text('Floor Plans', style: AppTextStyles.h5),
              const Spacer(),
              TextButton(
                onPressed: () => _showFloorPlanSheet(property),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View Floor Plan',
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
                        Text(
                          '670 Sqft',
                          style: AppTextStyles.bodyMedium,
                        ),
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
                        Text(
                          '\$1,600',
                          style: AppTextStyles.bodyMedium,
                        ),
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
                        Text(
                          '530 Sqft',
                          style: AppTextStyles.bodyMedium,
                        ),
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
                        Text(
                          '1345 Sqft',
                          style: AppTextStyles.bodyMedium,
                        ),
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
                  child: Text(
                    'Floor Plans',
                    style: AppTextStyles.h5,
                  ),
                ),
                const Gap(16),
                // Content
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      Text(
                        'First Floor',
                        style: AppTextStyles.h6,
                      ),
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
              Text('Details', style: AppTextStyles.h5),
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
                      'More Details',
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
              _DetailRow(label: 'Property ID:', value: property.id.toString()),
              const Gap(12),
              _DetailRow(
                label: 'First Price:',
                value: Formatters.formatPriceWithUnit(
                  property.price,
                  property.priceUnit,
                ),
              ),
              if (hasPerM2 || pricePerSqft > 0) ...[
                const Gap(12),
                _DetailRow(
                  label: 'Second Price:',
                  value: '\$${pricePerSqft.toStringAsFixed(0)}/sq ft',
                ),
              ],
              const Gap(12),
              _DetailRow(
                label: 'Property Type:',
                value: property.categoryName ?? property.category?.name ?? 'N/A',
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
                            _DetailRow(label: 'Số tầng', value: '${property.soTang}'),
                          ],
                          if (property.duongVao != null) ...[
                            const Gap(12),
                            _DetailRow(label: 'Đường vào', value: '${property.duongVao} m'),
                          ],
                          if (property.huongNha != null && property.huongNha!.isNotEmpty) ...[
                            const Gap(12),
                            _DetailRow(label: 'Hướng nhà', value: property.huongNha!),
                          ],
                          if (property.huongBanCong != null && property.huongBanCong!.isNotEmpty) ...[
                            const Gap(12),
                            _DetailRow(label: 'Hướng ban công', value: property.huongBanCong!),
                          ],
                          if (property.matTien != null) ...[
                            const Gap(12),
                            _DetailRow(label: 'Mặt tiền', value: '${property.matTien} m'),
                          ],
                          if (property.phapLy != null && property.phapLy!.isNotEmpty) ...[
                            const Gap(12),
                            _DetailRow(label: 'Pháp lý', value: property.phapLy!),
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


  Widget _buildAppointmentSection(PostModel property) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Schedule Appointment', style: AppTextStyles.h5),
          const Gap(12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const FaIcon(
                        FontAwesomeIcons.calendarCheck,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const Gap(12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Đặt lịch xem bất động sản',
                            style: AppTextStyles.h6.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Gap(4),
                          Text(
                            'Chọn thời gian phù hợp để xem trực tiếp',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Gap(16),
                AppButton(
                  text: 'Tạo lịch hẹn',
                  onPressed: () => _showCreateAppointmentDialog(property),
                  icon: FontAwesomeIcons.calendarPlus,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateAppointmentDialog(PostModel property) async {
    // Kiểm tra đăng nhập
    final userId = await AuthStorageService.getUserId();
    if (userId == null) {
      if (!mounted) return;
      _showLoginRequiredDialog(
        'Bạn cần đăng nhập để tạo lịch hẹn.',
      );
      return;
    }

    if (!mounted) return;
    // Lưu context từ widget state để dùng sau khi đóng dialog
    final widgetContextForDialog = context;

    final titleController = TextEditingController(text: 'Xem ${property.title}');
    final descriptionController = TextEditingController();
    DateTime? selectedDate;
    TimeOfDay? selectedTime;
    int reminderMinutes = 30; // Mặc định nhắc nhở 30 phút trước

    if (!mounted) return;
    final dialogContextForShow = context; // Lưu ngay trước await
    await showDialog(
      context: dialogContextForShow,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text('Tạo lịch hẹn', style: AppTextStyles.h5),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Tiêu đề',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const Gap(16),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Ghi chú (tùy chọn)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  maxLines: 3,
                ),
                const Gap(16),
                // Chọn ngày
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 1)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setDialogState(() {
                        selectedDate = date;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const FaIcon(
                          FontAwesomeIcons.calendar,
                          color: AppColors.primary,
                          size: 18,
                        ),
                        const Gap(12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ngày',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const Gap(4),
                              Text(
                                selectedDate != null
                                    ? DateFormat('dd/MM/yyyy').format(selectedDate!)
                                    : 'Chọn ngày',
                                style: AppTextStyles.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Gap(12),
                // Chọn giờ
                InkWell(
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null) {
                      setDialogState(() {
                        selectedTime = time;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const FaIcon(
                          FontAwesomeIcons.clock,
                          color: AppColors.primary,
                          size: 18,
                        ),
                        const Gap(12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Giờ',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const Gap(4),
                              Text(
                                selectedTime != null
                                    ? selectedTime!.format(context)
                                    : 'Chọn giờ',
                                style: AppTextStyles.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Gap(16),
                // Chọn thời gian nhắc nhở
                Text(
                  'Nhắc nhở trước',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Gap(8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('15 phút'),
                        selected: reminderMinutes == 15,
                        onSelected: (selected) {
                          if (selected) {
                            setDialogState(() => reminderMinutes = 15);
                          }
                        },
                      ),
                    ),
                    const Gap(8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('30 phút'),
                        selected: reminderMinutes == 30,
                        onSelected: (selected) {
                          if (selected) {
                            setDialogState(() => reminderMinutes = 30);
                          }
                        },
                      ),
                    ),
                    const Gap(8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('1 giờ'),
                        selected: reminderMinutes == 60,
                        onSelected: (selected) {
                          if (selected) {
                            setDialogState(() => reminderMinutes = 60);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Hủy', style: AppTextStyles.labelLarge),
            ),
            AppButton(
              text: 'Tạo lịch hẹn',
              onPressed: () async {
                // Lưu context từ builder để sử dụng trong dialog
                final builderContext = context;
                // Lưu widgetContext từ widget state (đã được lưu ở hàm cha) để dùng sau khi đóng dialog
                final currentWidgetContext = widgetContextForDialog;
                
                if (selectedDate == null || selectedTime == null) {
                  ScaffoldMessenger.of(builderContext).showSnackBar(
                    const SnackBar(
                      content: Text('Vui lòng chọn ngày và giờ'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                // Kết hợp ngày và giờ
                final appointmentDateTime = DateTime(
                  selectedDate!.year,
                  selectedDate!.month,
                  selectedDate!.day,
                  selectedTime!.hour,
                  selectedTime!.minute,
                );

                // Kiểm tra thời gian phải trong tương lai
                if (appointmentDateTime.isBefore(DateTime.now())) {
                  ScaffoldMessenger.of(builderContext).showSnackBar(
                    const SnackBar(
                      content: Text('Thời gian phải trong tương lai'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                Navigator.pop(builderContext);

                // Hiển thị loading - lưu context ngay trước khi sử dụng
                if (!mounted) return;
                final loadingDialogContext = currentWidgetContext;
                showDialog(
                  context: loadingDialogContext,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: LoadingIndicator(),
                  ),
                );

                try {
                  await _appointmentRepository.createAppointment(
                    postId: property.id,
                    title: titleController.text.trim(),
                    description: descriptionController.text.trim().isEmpty
                        ? null
                        : descriptionController.text.trim(),
                    appointmentTime: appointmentDateTime,
                    reminderMinutes: reminderMinutes,
                  );

                  // Lưu context ngay trước khi sử dụng sau async
                  if (!mounted) return;
                  final successContext = currentWidgetContext;
                  Navigator.pop(successContext); // Đóng loading

                  if (!mounted) return;
                  ScaffoldMessenger.of(successContext).showSnackBar(
                    const SnackBar(
                      content: Text('Đã tạo lịch hẹn thành công'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                } catch (e) {
                  // Lưu context ngay trước khi sử dụng sau async
                  if (!mounted) return;
                  final errorContext = currentWidgetContext;
                  Navigator.pop(errorContext); // Đóng loading

                  if (!mounted) return;
                  ScaffoldMessenger.of(errorContext).showSnackBar(
                    SnackBar(
                      content: Text('Lỗi tạo lịch hẹn: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
            ),
          ],
        ),
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
          Text('Contact Information', style: AppTextStyles.h5),
          const Gap(16),
          Row(
              children: [
                UserAvatarWithFallback(
                  avatarUrl: user?.avatarUrl,
                  name: user?.name ?? 'User',
                  radius: 32,
                  fontSize: 20,
                ),
                const Gap(16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'Agent',
                        style: AppTextStyles.h6.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Gap(4),
                      Text(
                        user?.role ?? 'Agent',
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
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _KeyStatItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _KeyStatItem({
    required this.icon,
    required this.label,
  });

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
          FaIcon(
            icon,
            size: 16,
            color: AppColors.textSecondary,
          ),
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

