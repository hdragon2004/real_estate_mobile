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
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/image_url_helper.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/loading_indicator.dart';
import 'image_gallery_screen.dart';
import 'map_screen.dart';

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
  bool _showFloatingButtons = true;

  @override
  void initState() {
    super.initState();
    _property = widget.initialProperty;
    _isLoading = widget.initialProperty == null;
    _loadPropertyDetail(showLoader: widget.initialProperty == null);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _imageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_titleKey.currentContext == null) {
      setState(() {
        _showFloatingButtons = true;
      });
      return;
    }

    final RenderBox? titleBox =
        _titleKey.currentContext?.findRenderObject() as RenderBox?;
    if (titleBox == null) {
      setState(() {
        _showFloatingButtons = true;
      });
      return;
    }

    final titlePosition = titleBox.localToGlobal(Offset.zero);
    final screenHeight = MediaQuery.of(context).size.height;
    final imageHeight = screenHeight * 0.3;
    final appBarHeight = kToolbarHeight + MediaQuery.of(context).padding.top;
    final threshold = imageHeight + appBarHeight;

    // Ẩn floating buttons khi scroll qua tiêu đề (khi tiêu đề đã lên trên cùng)
    final shouldShow = titlePosition.dy > threshold;

    if (shouldShow != _showFloatingButtons) {
      setState(() {
        _showFloatingButtons = !shouldShow;
      });
    }
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

  void _openMap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapScreen(propertyId: widget.propertyId),
      ),
    );
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
                SliverToBoxAdapter(child: _buildQuickStats(property)),
                SliverToBoxAdapter(child: _buildDetailsSection(property)),
                SliverToBoxAdapter(child: _buildDescription(property)),
                SliverToBoxAdapter(child: _buildLocation(property)),
                SliverToBoxAdapter(child: _buildContactCard(property)),
                const SliverToBoxAdapter(child: Gap(100)),
              ],
            ),
            // Floating buttons (message, call) - chỉ hiển thị khi ở trên
            if (_showFloatingButtons) _buildFloatingButtons(property),
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
    final imageHeight = screenHeight * 0.3; // 30% màn hình

    return SliverAppBar(
      expandedHeight: imageHeight,
      pinned: true,
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const FaIcon(FontAwesomeIcons.arrowLeft, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        property.categoryName ?? 'Chi tiết',
        style: AppTextStyles.h6.copyWith(color: Colors.white),
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
        IconButton(
          icon: FaIcon(
            isFavorite ? FontAwesomeIcons.solidHeart : FontAwesomeIcons.heart,
            color: isFavorite ? AppColors.error : Colors.white,
          ),
          tooltip: 'Yêu thích',
          onPressed: () => _toggleFavorite(property),
        ),
        IconButton(
          icon: const FaIcon(FontAwesomeIcons.share, color: Colors.white),
          tooltip: 'Chia sẻ',
          onPressed: () {
            // TODO: Implement share functionality
          },
        ),
      ],
    );
  }

  Widget _buildFloatingButtons(PostModel property) {
    final user = property.user;
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Row(
        children: [
          Expanded(
            child: AppButton(
              text: 'Email',
              icon: FontAwesomeIcons.envelope,
              onPressed: () => _launchMail(user?.email),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppButton(
              text: 'Gọi điện',
              icon: FontAwesomeIcons.phone,
              backgroundColor: Colors.green,
              onPressed: () => _launchPhone(user?.phone),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryInfo(PostModel property, {Key? key}) {
    return Padding(
      key: key,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(property.title, style: AppTextStyles.h4),
          const Gap(12),
          Row(
            children: [
              _InfoPill(
                icon: FontAwesomeIcons.locationDot,
                label:
                    property.ward?.name ??
                    property.wardName ??
                    'Không xác định',
              ),
              const Gap(8),
              _InfoPill(
                icon: FontAwesomeIcons.tag,
                label: property.categoryName ?? 'Danh mục',
              ),
            ],
          ),
          const Gap(16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Formatters.formatPriceWithUnit(
                  property.price,
                  property.priceUnit,
                ),
                style: AppTextStyles.priceLarge,
              ),
              const Gap(12),
              Text(
                Formatters.formatRelative(property.created),
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
          const Gap(16),
          _buildFeaturesRow(property),
        ],
      ),
    );
  }

  Widget _buildQuickStats(PostModel property) {
    final stats = <_QuickStat>[
      _QuickStat(
        label: 'Diện tích',
        value: Formatters.formatArea(property.areaSize),
        icon: FontAwesomeIcons.ruler,
      ),
      if (property.soPhongNgu != null)
        _QuickStat(
          label: 'Phòng ngủ',
          value: '${property.soPhongNgu}',
          icon: FontAwesomeIcons.bed,
        ),
      if (property.soPhongTam != null)
        _QuickStat(
          label: 'Phòng tắm',
          value: '${property.soPhongTam}',
          icon: FontAwesomeIcons.bath,
        ),
      if (property.soTang != null)
        _QuickStat(
          label: 'Số tầng',
          value: '${property.soTang}',
          icon: FontAwesomeIcons.layerGroup,
        ),
      if (property.huongNha != null)
        _QuickStat(
          label: 'Hướng nhà',
          value: property.huongNha!,
          icon: FontAwesomeIcons.compass,
        ),
      if (property.phapLy != null)
        _QuickStat(
          label: 'Pháp lý',
          value: property.phapLy!,
          icon: FontAwesomeIcons.gavel,
        ),
    ];

    if (stats.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const spacing = 12.0;
          final maxW = constraints.maxWidth;
          int columns = 3;
          if (maxW < 360) {
            columns = 2;
          } else if (maxW >= 360 && maxW < 600) {
            columns = 3;
          } else {
            columns = 4;
          }
          final itemWidth = (maxW - spacing * (columns - 1)) / columns;
          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: stats
                .map((stat) => _QuickStatCard(stat: stat, width: itemWidth))
                .toList(),
          );
        },
      ),
    );
  }

  Widget _buildDescription(PostModel property) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mô tả chi tiết', style: AppTextStyles.h5),
          const Gap(12),
          Text(
            property.description,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocation(PostModel property) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Vị trí', style: AppTextStyles.h5),
          const Gap(12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const FaIcon(
                      FontAwesomeIcons.locationDot,
                      color: AppColors.primary,
                    ),
                    const Gap(8),
                    Expanded(
                      child: Text(
                        property.displayAddress,
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                  ],
                ),
                const Gap(12),
                AppButton(
                  text: 'Xem trên bản đồ',
                  onPressed: _openMap,
                  isOutlined: true,
                  icon: FontAwesomeIcons.map,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection(PostModel property) {
    final hasPerM2 = property.priceUnit == PriceUnit.perM2;
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
                onPressed: () => _showMoreDetails(property),
                child: Text(
                  'Xem thêm',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const Gap(8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              children: [
                _DetailRow(label: 'Mã tin', value: property.id.toString()),
                _DetailRow(
                  label: 'Giá',
                  value: Formatters.formatPriceWithUnit(
                    property.price,
                    property.priceUnit,
                  ),
                ),
                if (hasPerM2)
                  _DetailRow(
                    label: 'Đơn giá',
                    value: Formatters.formatPriceWithUnit(
                      property.price,
                      property.priceUnit,
                    ),
                  ),
                _DetailRow(
                  label: 'Loại bất động sản',
                  value: property.categoryName ?? 'Không xác định',
                ),
                _DetailRow(
                  label: 'Diện tích',
                  value: Formatters.formatArea(property.areaSize),
                ),
                if (property.soTang != null)
                  _DetailRow(label: 'Số tầng', value: '${property.soTang}'),
                if (property.huongNha != null)
                  _DetailRow(label: 'Hướng nhà', value: property.huongNha!),
                if (property.phapLy != null)
                  _DetailRow(label: 'Pháp lý', value: property.phapLy!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showMoreDetails(PostModel property) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Thông tin chi tiết', style: AppTextStyles.h5),
                const Gap(12),
                _DetailRow(label: 'Mã tin', value: property.id.toString()),
                _DetailRow(label: 'Tiêu đề', value: property.title),
                _DetailRow(
                  label: 'Danh mục',
                  value: property.categoryName ?? 'Không xác định',
                ),
                _DetailRow(label: 'Địa chỉ', value: property.displayAddress),
                _DetailRow(
                  label: 'Diện tích',
                  value: Formatters.formatArea(property.areaSize),
                ),
                if (property.soPhongNgu != null)
                  _DetailRow(
                    label: 'Phòng ngủ',
                    value: '${property.soPhongNgu}',
                  ),
                if (property.soPhongTam != null)
                  _DetailRow(
                    label: 'Phòng tắm',
                    value: '${property.soPhongTam}',
                  ),
                if (property.soTang != null)
                  _DetailRow(label: 'Số tầng', value: '${property.soTang}'),
                if (property.matTien != null)
                  _DetailRow(label: 'Mặt tiền', value: '${property.matTien} m'),
                if (property.duongVao != null)
                  _DetailRow(
                    label: 'Đường vào',
                    value: '${property.duongVao} m',
                  ),
                if (property.huongNha != null)
                  _DetailRow(label: 'Hướng nhà', value: property.huongNha!),
                if (property.huongBanCong != null)
                  _DetailRow(
                    label: 'Hướng ban công',
                    value: property.huongBanCong!,
                  ),
                if (property.phapLy != null)
                  _DetailRow(label: 'Pháp lý', value: property.phapLy!),
              ],
            ),
          ),
        );
      },
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
          const Gap(12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: user?.avatarUrl != null
                          ? NetworkImage(
                              ImageUrlHelper.resolveImageUrl(user!.avatarUrl!),
                            )
                          : null,
                      child: user?.avatarUrl == null
                          ? Text(
                              (user?.name ?? 'U')[0].toUpperCase(),
                              style: AppTextStyles.h5.copyWith(
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                    const Gap(12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'Chủ tin',
                            style: AppTextStyles.h6,
                          ),
                          const Gap(4),
                          Text(
                            'Người đăng',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _launchMail(user?.email),
                      icon: const FaIcon(
                        FontAwesomeIcons.envelope,
                        color: AppColors.primary,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _launchPhone(user?.phone),
                      icon: const FaIcon(
                        FontAwesomeIcons.phone,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        text: 'Email',
                        icon: FontAwesomeIcons.envelope,
                        onPressed: () => _launchMail(user?.email),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppButton(
                        text: 'Gọi điện',
                        icon: FontAwesomeIcons.phone,
                        backgroundColor: Colors.green,
                        onPressed: () => _launchPhone(user?.phone),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(icon, size: 16, color: AppColors.textSecondary),
          const Gap(6),
          Text(label, style: AppTextStyles.labelSmall),
        ],
      ),
    );
  }
}

class _QuickStat {
  final String label;
  final String value;
  final IconData icon;

  _QuickStat({required this.label, required this.value, required this.icon});
}

class _QuickStatCard extends StatelessWidget {
  final _QuickStat stat;
  final double? width;

  const _QuickStatCard({required this.stat, this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FaIcon(stat.icon, color: AppColors.primary, size: 20),
          const Gap(8),
          Text(stat.value, style: AppTextStyles.h6),
          const Gap(4),
          Text(stat.label, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}

Widget _buildFeaturesRow(PostModel property) {
  final items = <_FeatureItem>[];
  if (property.soPhongNgu != null) {
    items.add(
      _FeatureItem(
        icon: FontAwesomeIcons.bed,
        label: '${property.soPhongNgu} Phòng ngủ',
      ),
    );
  }
  if (property.soPhongTam != null) {
    items.add(
      _FeatureItem(
        icon: FontAwesomeIcons.bath,
        label: '${property.soPhongTam} Phòng tắm',
      ),
    );
  }
  items.add(
    _FeatureItem(
      icon: FontAwesomeIcons.ruler,
      label: Formatters.formatArea(property.areaSize),
    ),
  );
  if (property.soTang != null) {
    items.add(
      _FeatureItem(
        icon: FontAwesomeIcons.layerGroup,
        label: '${property.soTang} Tầng',
      ),
    );
  }
  if (items.isEmpty) return const SizedBox.shrink();
  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          if (i != 0) const SizedBox(width: 12),
          items[i],
        ],
      ],
    ),
  );
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppShadows.small,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: FaIcon(icon, size: 16, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 8),
          Text(label, style: AppTextStyles.labelLarge),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(value, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}
