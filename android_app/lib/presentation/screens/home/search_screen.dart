import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../widgets/common/property_card.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/empty_state.dart';
import '../../../core/models/post_model.dart';
import '../../../core/repositories/post_repository.dart';
import '../../../core/repositories/category_repository.dart';
import '../../../core/models/category_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/services/favorite_service.dart';
import '../property/property_detail_screen.dart';
import '../home/search_results_screen.dart';
import '../home/filter_screen.dart';

/// Màn hình Tìm kiếm - Modern UI với tích hợp API
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final PostRepository _postRepository = PostRepository();
  final CategoryRepository _categoryRepository = CategoryRepository();
  final FavoriteService _favoriteService = FavoriteService();
  
  bool _isLoading = false;
  List<PostModel> _results = [];
  List<CategoryModel> _categories = [];
  
  // Recent searches - có thể lưu vào SharedPreferences sau
  final List<String> _recentSearches = [];

  @override
  void initState() {
    super.initState();
    _searchFocusNode.requestFocus();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      final categories = await _categoryRepository.getActiveCategories();
      
      if (mounted) {
        setState(() {
          _categories = categories;
        });
      }
    } catch (e) {
      debugPrint('Error loading initial data: $e');
    }
  }

  Future<void> _handleSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _results.clear());
      return;
    }

    setState(() => _isLoading = true);

    try {
      final results = await _postRepository.searchPosts(query: query.trim());
      if (!mounted) return;
      
      setState(() {
        _results = results;
        _isLoading = false;
      });
      
      // Lưu vào recent searches
      if (query.trim().isNotEmpty && !_recentSearches.contains(query.trim())) {
        setState(() {
          _recentSearches.insert(0, query.trim());
          if (_recentSearches.length > 10) {
            _recentSearches.removeLast();
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tìm kiếm: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _handleRecentSearch(String query) {
    _searchController.text = query;
    _handleSearch(query);
  }

  void _handleCategorySearch(CategoryModel category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchResultsScreen(
          query: category.name,
          filters: {'categoryId': category.id},
        ),
      ),
    );
  }

  void _handleLocationSearch() {
    // Mở màn hình tìm kiếm theo bản đồ
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MapSearchScreen(),
      ),
    );
  }

  void _handleAdvancedSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FilterScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            style: AppTextStyles.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm địa điểm, loại hình...',
              hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
              prefixIcon: const Icon(Iconsax.search_normal_1, color: AppColors.textSecondary),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      color: AppColors.textSecondary,
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _results.clear();
                        });
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) {
              setState(() {});
              if (value.isNotEmpty) {
                _handleSearch(value);
              } else {
                setState(() => _results.clear());
              }
            },
            onSubmitted: _handleSearch,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.map_1, color: AppColors.textPrimary),
            tooltip: 'Tìm kiếm theo bản đồ',
            onPressed: _handleLocationSearch,
          ),
          IconButton(
            icon: const Icon(Iconsax.filter, color: AppColors.textPrimary),
            tooltip: 'Bộ lọc nâng cao',
            onPressed: _handleAdvancedSearch,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: LoadingIndicator());
    }

    if (_searchController.text.isEmpty) {
      return _buildRecentSearches();
    }

    if (_results.isEmpty) {
      return EmptyState(
        icon: Iconsax.search_normal_1,
        title: 'Không tìm thấy kết quả',
        message: 'Thử tìm kiếm với từ khóa khác hoặc sử dụng bộ lọc',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final property = _results[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
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
        );
      },
    );
  }

  Widget _buildRecentSearches() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Actions
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  icon: Iconsax.map_1,
                  title: 'Tìm theo bản đồ',
                  subtitle: 'Chọn địa điểm',
                  color: AppColors.primary,
                  onTap: _handleLocationSearch,
                ),
              ),
              const Gap(12),
              Expanded(
                child: _buildQuickActionCard(
                  icon: Iconsax.filter,
                  title: 'Bộ lọc nâng cao',
                  subtitle: 'Lọc chi tiết',
                  color: AppColors.accent,
                  onTap: _handleAdvancedSearch,
                ),
              ),
            ],
          ),
          const Gap(32),
          
          // Loại hình
          Text('Tìm theo loại hình', style: AppTextStyles.h5),
          const Gap(16),
          if (_categories.isEmpty)
            const Center(child: CircularProgressIndicator())
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _categories.map((category) {
                return _buildCategoryCard(category);
              }).toList(),
            ),
          
          // Tìm kiếm gần đây
          if (_recentSearches.isNotEmpty) ...[
            const Gap(32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tìm kiếm gần đây', style: AppTextStyles.h5),
                TextButton(
                  onPressed: () => setState(() => _recentSearches.clear()),
                  child: Text('Xóa', style: AppTextStyles.labelMedium.copyWith(color: AppColors.error)),
                ),
              ],
            ),
            const Gap(12),
            ..._recentSearches.map((search) => _buildRecentSearchItem(search)),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const Gap(12),
            Text(title, style: AppTextStyles.labelLarge),
            const Gap(4),
            Text(subtitle, style: AppTextStyles.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(CategoryModel category) {
    return GestureDetector(
      onTap: () => _handleCategorySearch(category),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.small,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.category, size: 20, color: AppColors.primary),
            const Gap(8),
            Text(category.name, style: AppTextStyles.labelMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSearchItem(String search) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        leading: Icon(Iconsax.clock, color: AppColors.textSecondary),
        title: Text(search, style: AppTextStyles.bodyMedium),
        trailing: Icon(Iconsax.arrow_right_3, size: 18, color: AppColors.textSecondary),
        onTap: () => _handleRecentSearch(search),
      ),
    );
  }
}

/// Màn hình tìm kiếm theo bản đồ (Placeholder - cần tích hợp Google Maps)
class MapSearchScreen extends StatelessWidget {
  const MapSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tìm kiếm theo bản đồ'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.map_1, size: 80, color: AppColors.textHint),
            const Gap(16),
            Text('Tính năng đang phát triển', style: AppTextStyles.h5),
            const Gap(8),
            Text(
              'Tích hợp Google Maps để tìm kiếm theo địa điểm',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

