import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models/post_model.dart';
import '../../../core/repositories/post_repository.dart';
import '../../../core/services/favorite_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/image_url_helper.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/loading_indicator.dart';
import '../chat/chat_screen.dart';
import 'image_gallery_screen.dart';
import 'map_screen.dart';

/// Màn hình Chi tiết bất động sản
class PropertyDetailScreen extends StatefulWidget {
  final String propertyId;
  final PostModel? initialProperty;

  const PropertyDetailScreen({
    super.key,
    required this.propertyId,
    this.initialProperty,
  });

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  final PostRepository _postRepository = PostRepository();
  final FavoriteService _favoriteService = FavoriteService();
  final PageController _imageController = PageController();

  PostModel? _property;
  bool _isLoading = false;
  int _currentImageIndex = 0;

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

  void _toggleFavorite(PostModel property) {
    HapticFeedback.lightImpact();
    _favoriteService.toggleFavorite(property);
    setState(() {});
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
    if (phone == null || phone.isEmpty) {
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa có email liên hệ.')),
      );
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

  void _contactOwner(PostModel property) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          chatId: 'owner_${property.id}',
          userName: property.user?.name ?? 'Chủ tin',
          userAvatar: property.user?.avatarUrl,
        ),
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
        appBar: AppBar(
          title: const Text('Chi tiết bất động sản'),
        ),
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
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            _buildImageAppBar(property, images, isFavorite),
            SliverToBoxAdapter(child: _buildPrimaryInfo(property)),
            SliverToBoxAdapter(child: _buildQuickStats(property)),
            SliverToBoxAdapter(child: _buildDescription(property)),
            SliverToBoxAdapter(child: _buildLocation(property)),
            SliverToBoxAdapter(child: _buildContactCard(property)),
            const SliverToBoxAdapter(child: Gap(100)),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(property),
    );
  }

  SliverAppBar _buildImageAppBar(PostModel property, List<String> images, bool isFavorite) {
    return SliverAppBar(
      expandedHeight: 360,
      pinned: true,
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      title: Text(property.categoryName ?? 'Chi tiết', style: AppTextStyles.h6.copyWith(color: Colors.white)),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            images.isEmpty
                ? Container(
                    color: AppColors.surfaceVariant,
                    child: const Icon(Icons.image, size: 80, color: AppColors.textHint),
                  )
                : PageView.builder(
                    controller: _imageController,
                    onPageChanged: (index) => setState(() => _currentImageIndex = index),
                    itemCount: images.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => _openImageGallery(images),
                        child: Hero(
                          tag: 'property_${property.id}_image_$index',
                          child: CachedNetworkImage(
                            imageUrl: images[index],
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(color: AppColors.surfaceVariant),
                            errorWidget: (context, url, error) => Container(
                              color: AppColors.surfaceVariant,
                              child: const Icon(Icons.broken_image, size: 48, color: AppColors.textHint),
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      property.transactionType == TransactionType.sale ? 'Đang bán' : 'Cho thuê',
                      style: AppTextStyles.labelSmall.copyWith(color: Colors.white),
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
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_outline,
            color: isFavorite ? AppColors.error : Colors.white,
          ),
          onPressed: () => _toggleFavorite(property),
        ),
      ],
    );
  }

  Widget _buildPrimaryInfo(PostModel property) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(property.title, style: AppTextStyles.h4),
          const Gap(12),
          Row(
            children: [
              _InfoPill(
                icon: Icons.location_on,
                label: property.area?.ward?.name ?? 'Không xác định',
              ),
              const Gap(8),
              _InfoPill(
                icon: Icons.category_outlined,
                label: property.categoryName ?? 'Danh mục',
              ),
            ],
          ),
          const Gap(16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Formatters.formatPriceWithUnit(property.price, property.priceUnit),
                style: AppTextStyles.priceLarge,
              ),
              const Gap(12),
              Text(
                Formatters.formatRelative(property.created),
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(PostModel property) {
    final stats = <_QuickStat>[
      _QuickStat(label: 'Diện tích', value: Formatters.formatArea(property.areaSize), icon: Icons.square_foot),
      if (property.soPhongNgu != null)
        _QuickStat(label: 'Phòng ngủ', value: '${property.soPhongNgu}', icon: Icons.bed_outlined),
      if (property.soPhongTam != null)
        _QuickStat(label: 'Phòng tắm', value: '${property.soPhongTam}', icon: Icons.bathtub_outlined),
      if (property.soTang != null)
        _QuickStat(label: 'Số tầng', value: '${property.soTang}', icon: Icons.landscape_outlined),
      if (property.huongNha != null)
        _QuickStat(label: 'Hướng nhà', value: property.huongNha!, icon: Icons.explore_outlined),
      if (property.phapLy != null)
        _QuickStat(label: 'Pháp lý', value: property.phapLy!, icon: Icons.gavel_outlined),
    ];

    if (stats.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: stats.map((stat) => _QuickStatCard(stat: stat)).toList(),
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
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.6),
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
                    const Icon(Icons.location_on, color: AppColors.primary),
                    const Gap(8),
                    Expanded(
                      child: Text(
                        property.fullAddress,
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
                  icon: Icons.map,
                ),
              ],
            ),
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
          Text('Liên hệ', style: AppTextStyles.h5),
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
                      radius: 28,
                      backgroundImage: user?.avatarUrl != null ? NetworkImage(user!.avatarUrl!) : null,
                      child: user?.avatarUrl == null
                          ? Text((user?.name ?? 'U')[0].toUpperCase(), style: AppTextStyles.h5.copyWith(color: Colors.white))
                          : null,
                    ),
                    const Gap(12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user?.name ?? 'Chủ tin', style: AppTextStyles.h6),
                          const Gap(4),
                          Text(user?.email ?? '-', style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _launchMail(user?.email),
                      icon: const Icon(Icons.email_outlined),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        text: 'Gọi điện',
                        onPressed: () => _launchPhone(user?.phone),
                        isOutlined: true,
                        icon: Icons.phone,
                      ),
                    ),
                    const Gap(12),
                    Expanded(
                      child: AppButton(
                        text: 'Nhắn tin',
                        onPressed: () => _contactOwner(property),
                        icon: Icons.chat_bubble_outline,
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

  Widget _buildBottomBar(PostModel property) {
    final user = property.user;
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: 12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: AppShadows.bottomNav,
      ),
      child: Row(
        children: [
          Expanded(
            child: AppButton(
              text: 'Gọi ngay',
              onPressed: () => _launchPhone(user?.phone),
              isOutlined: true,
              icon: Icons.call,
            ),
          ),
          const Gap(12),
          Expanded(
            child: AppButton(
              text: 'Đặt lịch xem',
              onPressed: () => _contactOwner(property),
              icon: Icons.calendar_month,
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
          Icon(icon, size: 16, color: AppColors.textSecondary),
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

  const _QuickStatCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(stat.icon, color: AppColors.primary, size: 20),
          const Gap(8),
          Text(stat.value, style: AppTextStyles.h6),
          const Gap(4),
          Text(stat.label, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}

