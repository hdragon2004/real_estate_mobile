import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../widgets/common/property_card.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/empty_state.dart';
import '../../../core/models/post_model.dart';
import '../../../core/repositories/post_repository.dart';
import '../../../core/services/favorite_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../post/post_details_screen.dart';
import 'filter_screen.dart';

/// Màn hình Kết quả tìm kiếm
class SearchResultsScreen extends StatefulWidget {
  final String query;
  final Map<String, dynamic>? filters;

  const SearchResultsScreen({
    super.key,
    required this.query,
    this.filters,
  });

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  final PostRepository _postRepository = PostRepository();
  final FavoriteService _favoriteService = FavoriteService();
  
  bool _isLoading = false;
  List<PostModel> _results = [];
  String _sortBy = 'Mới nhất';
  Map<String, dynamic>? _currentFilters;

  @override
  void initState() {
    super.initState();
    _currentFilters = widget.filters;
    _loadResults();
  }

  Future<void> _loadResults() async {
    setState(() => _isLoading = true);
    try {
      List<PostModel> results;
      
      if (_currentFilters != null && _currentFilters!.isNotEmpty) {
        // Tìm kiếm với filters - truyền các tham số riêng lẻ
        results = await _postRepository.searchPosts(
          categoryId: _currentFilters!['categoryId'] as int?,
          minPrice: _currentFilters!['minPrice'] as double?,
          maxPrice: _currentFilters!['maxPrice'] as double?,
          minArea: _currentFilters!['minArea'] as double?,
          maxArea: _currentFilters!['maxArea'] as double?,
          cityId: _currentFilters!['cityId'] as int?,
          districtId: _currentFilters!['districtId'] as int?,
          wardId: _currentFilters!['wardId'] as int?,
          status: _currentFilters!['status'] as String?,
        );
      } else if (widget.query.isNotEmpty && widget.query != 'Kết quả tìm kiếm') {
        // Tìm kiếm với query
        results = await _postRepository.searchPosts(query: widget.query);
      } else {
        // Load tất cả
        results = await _postRepository.getPosts(isApproved: true);
      }
      
      // Sort results
      _sortResults(results);
      
      if (!mounted) return;
      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tải kết quả: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _sortResults(List<PostModel> results) {
    switch (_sortBy) {
      case 'Giá thấp đến cao':
        results.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Giá cao đến thấp':
        results.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'Diện tích':
        results.sort((a, b) {
          return b.areaSize.compareTo(a.areaSize);
        });
        break;
      case 'Mới nhất':
      default:
        // Giữ nguyên thứ tự (mới nhất trước)
        break;
    }
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Sắp xếp theo', style: AppTextStyles.h6),
            const Gap(20),
            ...['Mới nhất', 'Giá thấp đến cao', 'Giá cao đến thấp', 'Diện tích']
                .map((option) => ListTile(
                      title: Text(option, style: AppTextStyles.bodyMedium),
                      trailing: _sortBy == option
                          ? FaIcon(FontAwesomeIcons.circleCheck, color: AppColors.primary)
                          : null,
                      onTap: () {
                        setState(() => _sortBy = option);
                        Navigator.pop(context);
                        _sortResults(_results);
                        setState(() {});
                      },
                    )),
          ],
        ),
      ),
    );
  }

  Future<void> _openFilter() async {
    final filterModel = FilterModel();
    if (_currentFilters != null) {
      filterModel.categoryId = _currentFilters!['categoryId'] as int?;
      filterModel.minPrice = _currentFilters!['minPrice'] as double?;
      filterModel.maxPrice = _currentFilters!['maxPrice'] as double?;
      filterModel.minArea = _currentFilters!['minArea'] as double?;
      filterModel.maxArea = _currentFilters!['maxArea'] as double?;
      filterModel.soPhongNgu = _currentFilters!['soPhongNgu'] as int?;
      filterModel.cityId = _currentFilters!['cityId'] as int?;
      filterModel.districtId = _currentFilters!['districtId'] as int?;
      filterModel.wardId = _currentFilters!['wardId'] as int?;
    }
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FilterScreen(initialFilters: filterModel),
      ),
    );
    
    if (result != null && result is FilterModel) {
      setState(() {
        _currentFilters = result.toQueryParams();
      });
      _loadResults();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('Kết quả tìm kiếm', style: AppTextStyles.h6),
        actions: [
          IconButton(
            icon: FaIcon(FontAwesomeIcons.filter, color: AppColors.textPrimary),
            onPressed: _openFilter,
            tooltip: 'Bộ lọc',
          ),
          IconButton(
            icon: FaIcon(FontAwesomeIcons.arrowDownWideShort, color: AppColors.textPrimary),
            onPressed: _showSortOptions,
            tooltip: 'Sắp xếp',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : _results.isEmpty
              ? EmptyState(
                  icon: FontAwesomeIcons.magnifyingGlass,
                  title: 'Không tìm thấy kết quả',
                  message: 'Thử thay đổi từ khóa hoặc bộ lọc',
                  buttonText: 'Thử lại',
                  onButtonTap: _loadResults,
                )
              : Column(
                  children: [
                    // Results count
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      color: AppColors.surfaceVariant,
                      child: Row(
                        children: [
                          Text(
                            'Tìm thấy ${_results.length} kết quả',
                            style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    // Results list
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadResults,
                        color: AppColors.primary,
                        child: ListView.builder(
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
                                      builder: (context) => PostDetailsScreen(
                                        propertyId: property.id.toString(),
                                        initialProperty: property,
                                      ),
                                    ),
                                  );
                                },
                                onFavoriteTap: () {
                                  // TODO: Cần userId từ auth
                                  // _favoriteService.toggleFavorite(property, userId);
                                  _favoriteService.toggleFavorite(property);
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

