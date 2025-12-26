import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../widgets/common/post_card.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/empty_state.dart';
import '../../../core/models/post_model.dart';
import '../../../core/services/post_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/services/favorite_service.dart';
import '../post/post_details_screen.dart';
import '../home/filter_screen.dart';
import 'map_search_screen.dart';

/// Màn hình Tìm kiếm - Modern UI với tích hợp API
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => SearchScreenState();
}

// Public state class để MainLayout có thể truy cập
class SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final PostService _postService = PostService();
  final FavoriteService _favoriteService = FavoriteService();
  
  bool _isLoading = false;
  List<PostModel> _allPosts = []; // Tất cả posts từ server (để lấy categories đầy đủ)
  List<PostModel> _results = []; // Posts đã được lọc
  final String _sortBy = 'Mới nhất'; // Sort option hiện tại (có thể mở rộng để user chọn trong tương lai)
  bool _isGridView = false; // Không thể final vì được thay đổi trong setState
  Map<String, dynamic>? _currentFilters; // Lưu filters hiện tại
  bool _isRadiusSearch = false; // Đánh dấu đang tìm kiếm theo bán kính
  
  // Selected filters cho filter chips
  String? _selectedTransactionType; // 'Sale' hoặc 'Rent'
  String? _selectedCategory; // Category name
  String? _selectedLocation; // City name

  // Method để apply filters từ bên ngoài (MainLayout)
  void applyFilters(Map<String, dynamic> filters) {
    _searchController.text = 'Kết quả tìm kiếm';
    _handleSearchWithFilters(filters);
  }

  @override
  void initState() {
    super.initState();
    _searchFocusNode.requestFocus();
    _loadAllPosts(); // Tự động load tất cả posts khi vào trang
  }
  
  /// Load tất cả posts từ server
  Future<void> _loadAllPosts() async {
    setState(() => _isLoading = true);
    try {
      final posts = await _postService.getPosts(isApproved: true);
      if (!mounted) return;
      setState(() {
        _allPosts = posts;
        // Reset filters và hiển thị tất cả posts
        _selectedTransactionType = null;
        _selectedCategory = null;
        _selectedLocation = null;
        _currentFilters = null;
        _isRadiusSearch = false;
        _results = posts; // Hiển thị tất cả posts ban đầu
        _isLoading = false;
      });
      _sortResults();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tải dữ liệu: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
  
  /// Lọc posts từ _allPosts hoặc _results dựa trên filters hiện tại
  void _applyFiltersToResults() {
    // Nếu đang ở chế độ radius search, filter từ _results
    // Nếu không, filter từ _allPosts
    List<PostModel> sourceList = _isRadiusSearch ? List.from(_results) : List.from(_allPosts);
    
    // Nếu không có filter nào, hiển thị tất cả posts từ source
    if (_selectedTransactionType == null && 
        _selectedCategory == null && 
        _selectedLocation == null && 
        _currentFilters == null) {
      setState(() {
        _results = sourceList;
      });
      _sortResults();
      return;
    }
    
    List<PostModel> filtered = sourceList;
    
    // Lọc theo transaction type
    if (_selectedTransactionType != null) {
      filtered = filtered.where((post) {
        final postType = post.transactionType == TransactionType.sale ? 'Sale' : 'Rent';
        return postType == _selectedTransactionType;
      }).toList();
    }
    
    // Lọc theo category
    if (_selectedCategory != null) {
      filtered = filtered.where((post) {
        // Ưu tiên dùng categoryName, nếu null thì dùng category?.name
        final categoryName = post.categoryName ?? post.category?.name;
        return categoryName == _selectedCategory;
      }).toList();
    }
    
    // Lọc theo location (city)
    if (_selectedLocation != null) {
      filtered = filtered.where((post) {
        return post.cityName == _selectedLocation;
      }).toList();
    }
    
    // Lọc theo _currentFilters (từ advanced filter)
    if (_currentFilters != null) {
      if (_currentFilters!.containsKey('status')) {
        final status = _currentFilters!['status'] as String;
        filtered = filtered.where((post) {
          final postType = post.transactionType == TransactionType.sale ? 'Sale' : 'Rent';
          return postType == status;
        }).toList();
      }
      
      if (_currentFilters!.containsKey('categoryId')) {
        final categoryId = _currentFilters!['categoryId'] as int;
        filtered = filtered.where((post) => post.categoryId == categoryId).toList();
      }
      
      if (_currentFilters!.containsKey('cityName')) {
        final cityName = _currentFilters!['cityName'] as String;
        filtered = filtered.where((post) => post.cityName == cityName).toList();
      }
      
      if (_currentFilters!.containsKey('districtName')) {
        final districtName = _currentFilters!['districtName'] as String;
        filtered = filtered.where((post) => post.districtName == districtName).toList();
      }
      
      if (_currentFilters!.containsKey('wardName')) {
        final wardName = _currentFilters!['wardName'] as String;
        filtered = filtered.where((post) => post.wardName == wardName).toList();
      }
      
      if (_currentFilters!.containsKey('soPhongNgu')) {
        final soPhongNgu = _currentFilters!['soPhongNgu'] as int;
        filtered = filtered.where((post) => (post.soPhongNgu ?? 0) >= soPhongNgu).toList();
      }
      
      if (_currentFilters!.containsKey('soPhongTam')) {
        final soPhongTam = _currentFilters!['soPhongTam'] as int;
        filtered = filtered.where((post) => (post.soPhongTam ?? 0) >= soPhongTam).toList();
      }
      
      if (_currentFilters!.containsKey('minPrice')) {
        final minPrice = _currentFilters!['minPrice'] as double;
        filtered = filtered.where((post) => post.price >= minPrice).toList();
      }
      
      if (_currentFilters!.containsKey('maxPrice')) {
        final maxPrice = _currentFilters!['maxPrice'] as double;
        filtered = filtered.where((post) => post.price <= maxPrice).toList();
      }
      
      if (_currentFilters!.containsKey('minArea')) {
        final minArea = _currentFilters!['minArea'] as double;
        filtered = filtered.where((post) => post.areaSize >= minArea).toList();
      }
      
      if (_currentFilters!.containsKey('maxArea')) {
        final maxArea = _currentFilters!['maxArea'] as double;
        filtered = filtered.where((post) => post.areaSize <= maxArea).toList();
      }
    }
    
    setState(() {
      _results = filtered;
    });
    _sortResults();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }


  Future<void> _handleSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _results.clear();
        _currentFilters = null;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final results = await _postService.searchPosts(query: query.trim());
      if (!mounted) return;
      
      setState(() {
        _results = results;
        _currentFilters = null; // Reset filters khi search bằng query
        _isLoading = false;
      });
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


  Future<void> _handleSearchWithFilters(Map<String, dynamic> filters) async {
    setState(() {
      _isLoading = true;
      _currentFilters = filters;
      
      // Cập nhật selected filters từ advanced filter
      if (filters.containsKey('status')) {
        _selectedTransactionType = filters['status'] as String;
      }
      if (filters.containsKey('categoryId') && _allPosts.isNotEmpty) {
        final categoryId = filters['categoryId'] as int;
        final post = _allPosts.firstWhere(
          (p) => p.categoryId == categoryId,
          orElse: () => _allPosts.first,
        );
        // Ưu tiên dùng categoryName, nếu null thì dùng category?.name
        _selectedCategory = post.categoryName ?? post.category?.name;
      }
      if (filters.containsKey('cityName')) {
        _selectedLocation = filters['cityName'] as String;
      }
    });
    
    try {
      List<PostModel> results;
      
      // Kiểm tra nếu có radius search (tìm kiếm theo bản đồ)
      if (filters.containsKey('centerLat') &&
          filters.containsKey('centerLng') &&
          filters.containsKey('radiusInKm')) {
        results = await _postService.searchByRadius(
          centerLat: filters['centerLat'] as double,
          centerLng: filters['centerLng'] as double,
          radiusInKm: filters['radiusInKm'] as double,
        );
        // Đánh dấu đang tìm kiếm theo bán kính
        // KHÔNG thay thế _allPosts để giữ lại categories đầy đủ cho filter chips
        setState(() {
          _isRadiusSearch = true;
          // Cập nhật _results với kết quả radius search
          _results = results;
        });
      } else {
        // Kiểm tra xem có filters quan trọng không (location, price, area)
        final hasImportantFilters = filters.containsKey('cityName') ||
            filters.containsKey('districtName') ||
            filters.containsKey('wardName') ||
            filters.containsKey('minPrice') ||
            filters.containsKey('maxPrice') ||
            filters.containsKey('minArea') ||
            filters.containsKey('maxArea') ||
            filters.containsKey('categoryId');
        
        if (hasImportantFilters && _allPosts.isNotEmpty) {
          // Nếu có filters quan trọng và đã có _allPosts, filter local thay vì gọi API
          // Điều này tránh lỗi 400 khi thiếu q và status
          setState(() {
            _isRadiusSearch = false;
          });
          _applyFiltersToResults();
        } else if (hasImportantFilters) {
          // Nếu có filters nhưng chưa có _allPosts, gọi API search
          results = await _postService.searchPosts(
            categoryId: filters['categoryId'] as int?,
            minPrice: filters['minPrice'] as double?,
            maxPrice: filters['maxPrice'] as double?,
            minArea: filters['minArea'] as double?,
            maxArea: filters['maxArea'] as double?,
            cityName: filters['cityName'] as String?,
            districtName: filters['districtName'] as String?,
            wardName: filters['wardName'] as String?,
            status: filters['status'] as String?,
          );
          setState(() {
            _isRadiusSearch = false;
            _allPosts = results;
            _results = results;
          });
        } else {
          // Nếu không có filters quan trọng, chỉ filter local từ _allPosts
          setState(() {
            _isRadiusSearch = false;
          });
          _applyFiltersToResults();
        }
      }
      
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
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

  Future<void> _handleLocationSearch() async {
    // Mở màn hình tìm kiếm theo bản đồ
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MapSearchScreen(),
      ),
    );
    
    // Nhận kết quả từ MapSearchScreen và hiển thị
    if (result != null && result is Map<String, dynamic>) {
      _searchController.text = 'Tìm kiếm trong bán kính ${result['radiusInKm']}km';
      _handleSearchWithFilters(result);
    }
  }

  Future<void> _handleAdvancedSearch() async {
    final FilterModel filterModel = FilterModel();
    if (_currentFilters != null) {
      filterModel.categoryId = _currentFilters!['categoryId'] as int?;
      filterModel.minPrice = _currentFilters!['minPrice'] as double?;
      filterModel.maxPrice = _currentFilters!['maxPrice'] as double?;
      filterModel.minArea = _currentFilters!['minArea'] as double?;
      filterModel.maxArea = _currentFilters!['maxArea'] as double?;
      filterModel.soPhongNgu = _currentFilters!['soPhongNgu'] as int?;
      filterModel.cityName = _currentFilters!['cityName'] as String?;
      filterModel.districtName = _currentFilters!['districtName'] as String?;
      filterModel.wardName = _currentFilters!['wardName'] as String?;
      filterModel.status = _currentFilters!['status'] as String?;
    }
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FilterScreen(initialFilters: filterModel),
      ),
    );
    
    if (result != null && result is Map<String, dynamic>) {
      _searchController.text = 'Kết quả tìm kiếm';
      _handleSearchWithFilters(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // Không hiển thị back button
        title: Container(
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            style: TextStyle(
              color: Colors.grey.shade800,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: 'Tìm kiếm',
              hintStyle: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
              prefixIcon: Container(
                alignment: Alignment.center,
                width: 50,
                child: FaIcon(
                  FontAwesomeIcons.magnifyingGlass,
                  color: Colors.grey.shade700,
                  size: 18,
                ),
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Button bản đồ (tìm kiếm theo bán kính)
                  IconButton(
                    icon: const FaIcon(
                      FontAwesomeIcons.map,
                      color: Colors.grey,
                      size: 18,
                    ),
                    onPressed: _handleLocationSearch,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Tìm kiếm theo bản đồ',
                  ),
                  const SizedBox(width: 4),
                  // Button bộ lọc
                  GestureDetector(
                    onTap: _handleAdvancedSearch,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: FaIcon(
                        FontAwesomeIcons.sliders,
                        color: Colors.grey.shade700,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 0),
            ),
            onChanged: (value) {
              if (value.isNotEmpty) {
                _handleSearch(value);
              } else {
                // Reset về tất cả posts khi xóa search
                setState(() {
                  _results = _allPosts;
                  _currentFilters = null;
                  _selectedTransactionType = null;
                  _selectedCategory = null;
                  _selectedLocation = null;
                  _isRadiusSearch = false;
                });
                _sortResults();
              }
            },
            onSubmitted: _handleSearch,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : _buildResultsView(),
    );
  }


  void _sortResults() {
    final sorted = List<PostModel>.from(_results);
    switch (_sortBy) {
      case 'Giá thấp đến cao':
        sorted.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Giá cao đến thấp':
        sorted.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'Diện tích':
        sorted.sort((a, b) => b.areaSize.compareTo(a.areaSize));
        break;
      case 'Mới nhất':
      default:
        sorted.sort((a, b) => b.created.compareTo(a.created));
        break;
    }
    setState(() {
      _results = sorted;
    });
  }

  Widget _buildResultsView() {
    return Column(
      children: [
        // Filter Bar - Luôn hiển thị
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.white,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // TransactionType: Cho thuê - Luôn hiển thị
                _buildFilterChip(
                  label: 'Cho thuê',
                  isSelected: _selectedTransactionType == 'Rent',
                  icon: FontAwesomeIcons.circleCheck,
                  onTap: () {
                    setState(() {
                      // Nếu đã chọn thì bỏ chọn, nếu chưa chọn thì chọn
                      if (_selectedTransactionType == 'Rent') {
                        _selectedTransactionType = null;
                      } else {
                        _selectedTransactionType = 'Rent';
                      }
                    });
                    _applyFiltersToResults();
                  },
                ),
                const Gap(8),
                // TransactionType: Bán - Luôn hiển thị
                _buildFilterChip(
                  label: 'Bán',
                  isSelected: _selectedTransactionType == 'Sale',
                  icon: FontAwesomeIcons.circleCheck,
                  onTap: () {
                    setState(() {
                      // Nếu đã chọn thì bỏ chọn, nếu chưa chọn thì chọn
                      if (_selectedTransactionType == 'Sale') {
                        _selectedTransactionType = null;
                      } else {
                        _selectedTransactionType = 'Sale';
                      }
                    });
                    _applyFiltersToResults();
                  },
                ),
                const Gap(8),
                // Categories - Luôn hiển thị tất cả, có thể scroll ngang
                ..._getUniqueCategories().map((category) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildFilterChip(
                      label: category,
                      isSelected: _selectedCategory == category,
                      icon: FontAwesomeIcons.building,
                      onTap: () {
                        setState(() {
                          // Nếu đã chọn thì bỏ chọn, nếu chưa chọn thì chọn
                          if (_selectedCategory == category) {
                            _selectedCategory = null;
                          } else {
                            _selectedCategory = category;
                          }
                        });
                        _applyFiltersToResults();
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        // Results Summary
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_results.length} Results',
                    style: AppTextStyles.h5.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Gap(4),
                  Text(
                    "Showing '$_sortBy' results",
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              // View Toggle
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.grid_view,
                      color: _isGridView ? AppColors.primary : AppColors.textSecondary,
                    ),
                    onPressed: () => setState(() => _isGridView = true),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.view_list,
                      color: !_isGridView ? AppColors.primary : AppColors.textSecondary,
                    ),
                    onPressed: () => setState(() => _isGridView = false),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Results List
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              // Reset tất cả filters và load lại tất cả posts
              await _loadAllPosts();
            },
            color: AppColors.primary,
            child: _results.isEmpty
                ? SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(), // Cho phép pull-to-refresh ngay cả khi empty
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.6, // Chiều cao đủ để pull-to-refresh
                      child: EmptyState(
                        icon: FontAwesomeIcons.magnifyingGlass,
                        title: 'Không tìm thấy kết quả',
                        message: 'Thử thay đổi bộ lọc hoặc từ khóa tìm kiếm\n\nKéo xuống để làm mới',
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final property = _results[index];
                      return PostCard(
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
                        onFavoriteTap: () => _favoriteService.toggleFavorite(property),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  /// Lấy danh sách unique categories từ _allPosts
  List<String> _getUniqueCategories() {
    final categories = <String>{};
    
    for (final post in _allPosts) {
      // Ưu tiên dùng categoryName, nếu null thì dùng category?.name
      final categoryName = post.categoryName ?? post.category?.name;
      if (categoryName != null && categoryName.isNotEmpty) {
        categories.add(categoryName);
      }
    }
    
    final sortedCategories = categories.toList()..sort();
    return sortedCategories;
  }
  

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              icon,
              size: 14,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const Gap(6),
            Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
