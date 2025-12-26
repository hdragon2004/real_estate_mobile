import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/post_model.dart';
import '../../../core/services/post_service.dart';
import '../../../core/services/favorite_service.dart';
import '../../../core/services/auth_storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/image_url_helper.dart';
import '../../widgets/common/user_avatar.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/appointment/appointment_create_dialog.dart';
import 'image_gallery_screen.dart';
import 'post_owner_screen.dart';
import '../chat/chat_screen.dart';

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
  final PostService _postService = PostService();
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

      final property = await _postService.getPostById(id);
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

  /// Navigate đến màn hình chat với chủ bài post
  Future<void> _navigateToChat(PostModel property) async {
    // Kiểm tra đăng nhập trước khi chat
    final currentUserId = await AuthStorageService.getUserId();
    if (currentUserId == null) {
      _showLoginRequiredDialog(
        'Bạn cần đăng nhập để nhắn tin với chủ bài đăng.',
      );
      return;
    }

    // Kiểm tra user có phải là chủ bài post không
    if (property.userId == currentUserId) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bạn không thể nhắn tin với chính mình'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    // Lấy thông tin chủ bài post
    final postOwnerId = property.userId;
    final postOwnerName = property.user?.name;
    final postOwnerAvatar = property.user?.avatarUrl;

    // Tạo địa chỉ đầy đủ từ các thành phần
    final addressParts = <String>[];
    if (property.streetName.isNotEmpty) {
      addressParts.add(property.streetName);
    }
    if (property.wardName != null && property.wardName!.isNotEmpty) {
      addressParts.add(property.wardName!);
    }
    if (property.districtName != null && property.districtName!.isNotEmpty) {
      addressParts.add(property.districtName!);
    }
    if (property.cityName != null && property.cityName!.isNotEmpty) {
      addressParts.add(property.cityName!);
    }
    // Tạo địa chỉ đầy đủ từ các thành phần
    String? fullAddress;
    if (property.fullAddress != null && property.fullAddress!.isNotEmpty) {
      // Ưu tiên dùng fullAddress từ Google Maps nếu có
      fullAddress = property.fullAddress;
    } else {
      // Nếu không có, tạo từ các thành phần
      final addressParts = <String>[];
      if (property.streetName.isNotEmpty) {
        addressParts.add(property.streetName);
      }
      if (property.wardName != null && property.wardName!.isNotEmpty) {
        addressParts.add(property.wardName!);
      }
      if (property.districtName != null && property.districtName!.isNotEmpty) {
        addressParts.add(property.districtName!);
      }
      if (property.cityName != null && property.cityName!.isNotEmpty) {
        addressParts.add(property.cityName!);
      }
      fullAddress = addressParts.isNotEmpty ? addressParts.join(', ') : null;
    }

    // Tạo ConversationId chỉ từ userId (không có postId)
    final minId = currentUserId < postOwnerId 
        ? currentUserId 
        : postOwnerId;
    final maxId = currentUserId > postOwnerId 
        ? currentUserId 
        : postOwnerId;
    final conversationId = '$minId' '_' '$maxId';

    // Navigate đến ChatScreen
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          chatId: conversationId,
          otherUserId: postOwnerId,
          postId: property.id, // Vẫn truyền để hiển thị thông tin post và gửi message tự động
          userName: postOwnerName,
          userAvatar: postOwnerAvatar,
          postTitle: property.title,
          postPrice: property.price,
          postAddress: fullAddress,
        ),
      ),
    );
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
                SliverToBoxAdapter(
                  child: _buildContactAndAppointment(property),
                ),
                const SliverToBoxAdapter(child: Gap(20)),
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
        // Chat button với overlay
        SafeArea(
          child: Container(
            margin: const EdgeInsets.only(right: 8, top: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const FaIcon(
                FontAwesomeIcons.message,
                color: Colors.white,
                size: 18,
              ),
              tooltip: 'Chat',
              onPressed: () => _navigateToChat(property),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryInfo(PostModel property, {Key? key}) {
    return Padding(
      key: key,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: property.transactionType == TransactionType.sale
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  property.transactionType == TransactionType.sale
                      ? 'Bán'
                      : 'Cho thuê',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: property.transactionType == TransactionType.sale
                        ? AppColors.success
                        : AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const Gap(16),
          // Price
          Text(
            '${Formatters.formatCurrency(property.price)} VNĐ',
            style: AppTextStyles.priceLarge.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Gap(16),
          // Key Stats: Bed, Bath, Area, Floors
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              if (property.soPhongNgu != null)
                _KeyStatItem(
                  icon: FontAwesomeIcons.bed,
                  label: '${property.soPhongNgu} PN',
                ),
              if (property.soPhongTam != null)
                _KeyStatItem(
                  icon: FontAwesomeIcons.bath,
                  label: '${property.soPhongTam} WC',
                ),
              if (property.areaSize > 0)
                _KeyStatItem(
                  icon: FontAwesomeIcons.ruler,
                  label: Formatters.formatArea(property.areaSize),
                ),
              if (property.soTang != null)
                _KeyStatItem(
                  icon: FontAwesomeIcons.building,
                  label: '${property.soTang} tầng',
                ),
            ],
          ),
        ],
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


  Widget _buildDetailsSection(PostModel property) {
    // Tính đơn giá theo m² nếu có diện tích (chỉ cho bán)
    // Hoặc hiển thị giá/tháng cho cho thuê
    final pricePerSqft = property.areaSize > 0 && property.transactionType == TransactionType.sale
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
                label: 'Diện tích:',
                value: Formatters.formatArea(property.areaSize),
              ),
              // Đơn giá theo m² cho bán, hoặc giá/tháng cho cho thuê
              if (property.transactionType == TransactionType.sale && pricePerSqft > 0) ...[
                const Gap(12),
                _DetailRow(
                  label: 'Đơn giá:',
                  value: '${Formatters.formatCurrency(pricePerSqft)}/m²',
                ),
              ],
              if (property.transactionType == TransactionType.rent) ...[
                const Gap(12),
                _DetailRow(
                  label: 'Đơn giá:',
                  value: '${Formatters.formatCurrency(property.price)}/tháng',
                ),
              ],
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: _isDetailsExpanded
                    ? Column(
                        children: [
                          if (property.soPhongNgu != null) ...[
                            const Gap(12),
                            _DetailRow(
                              label: 'Số phòng ngủ:',
                              value: '${property.soPhongNgu}',
                            ),
                          ],
                          if (property.soPhongTam != null) ...[
                            const Gap(12),
                            _DetailRow(
                              label: 'Số phòng tắm:',
                              value: '${property.soPhongTam}',
                            ),
                          ],
                          if (property.soTang != null) ...[
                            const Gap(12),
                            _DetailRow(
                              label: 'Số tầng:',
                              value: '${property.soTang}',
                            ),
                          ],
                          if (property.matTien != null) ...[
                            const Gap(12),
                            _DetailRow(
                              label: 'Mặt tiền:',
                              value: '${property.matTien} m',
                            ),
                          ],
                          if (property.duongVao != null) ...[
                            const Gap(12),
                            _DetailRow(
                              label: 'Đường vào:',
                              value: '${property.duongVao} m',
                            ),
                          ],
                          if (property.huongNha != null &&
                              property.huongNha!.isNotEmpty) ...[
                            const Gap(12),
                            _DetailRow(
                              label: 'Hướng nhà:',
                              value: property.huongNha!,
                            ),
                          ],
                          if (property.huongBanCong != null &&
                              property.huongBanCong!.isNotEmpty) ...[
                            const Gap(12),
                            _DetailRow(
                              label: 'Hướng ban công:',
                              value: property.huongBanCong!,
                            ),
                          ],
                          if (property.phapLy != null &&
                              property.phapLy!.isNotEmpty) ...[
                            const Gap(12),
                            _DetailRow(
                              label: 'Pháp lý:',
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

  Widget _buildContactAndAppointment(PostModel property) {
    final user = property.user;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title và Button nằm ngang với nhau
          Row(
            children: [
              Expanded(
                child: Text('Thông tin liên hệ', style: AppTextStyles.h5),
              ),
              ElevatedButton(
                onPressed: () => _navigateToCreateAppointment(property),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const FaIcon(FontAwesomeIcons.calendarPlus, size: 14),
                    const Gap(6),
                    Text(
                      'Đặt lịch hẹn',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Gap(16),
          // Thông tin user
          InkWell(
            onTap: () {
              if (user != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PostOwnerScreen(
                      userId: property.userId,
                      userName: user.name,
                      userAvatar: user.avatarUrl,
                      userEmail: user.email,
                      userPhone: user.phone,
                      userRole: user.role,
                      postId: property.id,
                    ),
                  ),
                );
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Row(
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
          ),
        ],
      ),
    );
  }

  void _navigateToCreateAppointment(PostModel property) async {
    final result = await AppointmentCreateDialog.show(
      context,
      propertyId: property.id,
      propertyTitle: property.title,
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã tạo lịch hẹn thành công!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
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
