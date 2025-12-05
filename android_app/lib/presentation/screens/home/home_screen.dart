import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../widgets/common/property_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_shadows.dart';
import 'search_screen.dart';
import 'filter_screen.dart';
import '../property/property_detail_screen.dart';
import '../../../core/models/post_model.dart';
import '../../../core/repositories/post_repository.dart';
import '../../../core/services/favorite_service.dart';

/// Màn hình Home / Dashboard - Modern UI
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  bool _isLoading = false;
  List<PostModel> _allProperties = []; // Lưu tất cả properties
  List<PostModel> _filteredProperties = []; // Properties đã lọc theo category
  final PostRepository _postRepository = PostRepository();
  final FavoriteService _favoriteService = FavoriteService();
  VoidCallback? _favoriteListener;
  int _selectedCategoryIndex = 0;

  // Category với categoryId tương ứng trong database
  // Database: 1=Căn hộ, 2=Nhà riêng, 3=Biệt thự, 4=Đất nền, 5=Văn phòng, 6=Mặt bằng
  final List<_CategoryItem> _categories = [
    _CategoryItem(icon: Iconsax.category, label: 'Tất cả', color: AppColors.primary, categoryId: null),
    _CategoryItem(icon: Iconsax.building_4, label: 'Căn hộ', color: AppColors.apartment, categoryId: 1, categoryName: 'Căn hộ chung cư'),
    _CategoryItem(icon: Iconsax.house, label: 'Nhà riêng', color: AppColors.house, categoryId: 2, categoryName: 'Nhà riêng'),
    _CategoryItem(icon: Iconsax.house_2, label: 'Biệt thự', color: AppColors.villa, categoryId: 3, categoryName: 'Biệt thự'),
    _CategoryItem(icon: Iconsax.map, label: 'Đất nền', color: AppColors.land, categoryId: 4, categoryName: 'Đất nền'),
    _CategoryItem(icon: Iconsax.buildings, label: 'Văn phòng', color: AppColors.commercial, categoryId: 5, categoryName: 'Văn phòng'),
    _CategoryItem(icon: Iconsax.shop, label: 'Mặt bằng', color: AppColors.office, categoryId: 6, categoryName: 'Mặt bằng kinh doanh'),
  ];

  @override
  void initState() {
    super.initState();
    _favoriteListener = () => setState(() {});
    _favoriteService.favoritesListenable.addListener(_favoriteListener!);
    _loadProperties();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
    if (_favoriteListener != null) {
      _favoriteService.favoritesListenable.removeListener(_favoriteListener!);
    }
  }

  void _handleSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SearchScreen()),
    );
  }

  void _handleFilter() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FilterScreen()),
    );

    if (result != null) {
      _loadProperties();
    }
  }

  void _handleCategorySelect(int index) {
    setState(() => _selectedCategoryIndex = index);
    _filterProperties();
  }

  /// Lọc properties theo category đã chọn
  void _filterProperties() {
    final selectedCategory = _categories[_selectedCategoryIndex];
    
    if (selectedCategory.categoryId == null) {
      // "Tất cả" được chọn - hiển thị tất cả
      setState(() {
        _filteredProperties = List.from(_allProperties);
      });
    } else {
      // Lọc theo categoryId
      setState(() {
        _filteredProperties = _allProperties
            .where((p) => p.categoryId == selectedCategory.categoryId)
            .toList();
      });
    }
  }

  Future<void> _loadProperties() async {
    setState(() => _isLoading = true);
    try {
      final properties = await _postRepository.getPosts(isApproved: true);
      if (!mounted) return;
      setState(() {
        _allProperties = properties;
        _isLoading = false;
      });
      // Áp dụng filter sau khi load xong
      _filterProperties();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể tải danh sách: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadProperties,
          color: AppColors.primary,
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: _buildHeader(),
              ),
              
              // Search Bar
              SliverToBoxAdapter(
                child: _buildSearchBar()
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 400.ms)
                    .slideY(begin: 0.2, end: 0, delay: 100.ms, duration: 400.ms),
              ),
              
              // Categories
              SliverToBoxAdapter(
                child: _buildCategories()
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 400.ms)
                    .slideY(begin: 0.2, end: 0, delay: 200.ms, duration: 400.ms),
              ),
              
              // Section Header - Hiển thị category đang chọn và số lượng
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _categories[_selectedCategoryIndex].categoryId == null
                                ? 'Tất cả bất động sản'
                                : _categories[_selectedCategoryIndex].label,
                            style: AppTextStyles.h5,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_filteredProperties.length} bất động sản',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      // Sort/Filter chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Iconsax.sort,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Mới nhất',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 400.ms),
              ),
              
              // Property List
              _isLoading
                  ? SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => const PropertyCardShimmer(),
                          childCount: 3,
                        ),
                      ),
                    )
                  : _filteredProperties.isEmpty
                      ? SliverToBoxAdapter(
                          child: _buildEmptyState(),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final property = _filteredProperties[index];
                                return AnimationConfiguration.staggeredList(
                                  position: index,
                                  duration: const Duration(milliseconds: 400),
                                  child: SlideAnimation(
                                    verticalOffset: 50,
                                    child: FadeInAnimation(
                                      child: PropertyCard(
                                        property: property,
                                        isFavorite: _favoriteService.isFavorite(property.id),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => PropertyDetailScreen(
                                                propertyId: property.id.toString(),
                                                initialProperty: property,
                                              ),
                                            ),
                                          );
                                        },
                                        onFavoriteTap: () => _favoriteService.toggleFavorite(property),
                                      ),
                                    ),
                                  ),
                                );
                              },
                              childCount: _filteredProperties.length,
                            ),
                          ),
                        ),
              
              // Bottom padding
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Xin chào! 👋',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tìm ngôi nhà mơ ước',
                style: AppTextStyles.h4,
              ),
            ],
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Stack(
              children: [
                const Center(
                  child: Icon(
                    Iconsax.notification,
                    color: AppColors.textPrimary,
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: -0.2, end: 0, duration: 400.ms);
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppShadows.small,
        ),
        child: TextField(
          controller: _searchController,
          onTap: _handleSearch,
          readOnly: true,
          decoration: InputDecoration(
            hintText: 'Tìm kiếm địa điểm, loại hình...',
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textHint,
            ),
            prefixIcon: const Icon(
              Iconsax.search_normal_1,
              color: AppColors.textSecondary,
            ),
            suffixIcon: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: IconButton(
                icon: const Icon(
                  Iconsax.setting_4,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: _handleFilter,
              ),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Text(
            'Loại hình bất động sản',
            style: AppTextStyles.h6,
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              final isSelected = _selectedCategoryIndex == index;
              
              return GestureDetector(
                onTap: () => _handleCategorySelect(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? category.color : AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: isSelected ? AppShadows.small : null,
                    border: Border.all(
                      color: isSelected ? category.color : AppColors.border,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        category.icon,
                        size: 28,
                        color: isSelected ? Colors.white : category.color,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        category.label,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final selectedCategory = _categories[_selectedCategoryIndex];
    final isFiltered = selectedCategory.categoryId != null;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: isFiltered 
                    ? selectedCategory.color.withAlpha(25)
                    : AppColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isFiltered ? selectedCategory.icon : Iconsax.home_2,
                size: 60,
                color: isFiltered ? selectedCategory.color : AppColors.textHint,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isFiltered 
                  ? 'Không có ${selectedCategory.label.toLowerCase()}'
                  : 'Chưa có bất động sản',
              style: AppTextStyles.h5,
            ),
            const SizedBox(height: 8),
            Text(
              isFiltered
                  ? 'Hiện tại không có ${selectedCategory.label.toLowerCase()} nào. Hãy thử chọn danh mục khác.'
                  : 'Hãy thử tìm kiếm hoặc thay đổi bộ lọc để khám phá',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (isFiltered) ...[
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: () => _handleCategorySelect(0), // Chọn "Tất cả"
                icon: const Icon(Iconsax.refresh),
                label: const Text('Xem tất cả'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoryItem {
  final IconData icon;
  final String label;
  final Color color;
  final int? categoryId; // ID trong database, null = tất cả
  final String? categoryName; // Tên đầy đủ trong database

  _CategoryItem({
    required this.icon,
    required this.label,
    required this.color,
    this.categoryId,
    this.categoryName,
  });
}
