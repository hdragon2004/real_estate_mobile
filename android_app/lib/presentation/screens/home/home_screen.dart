import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../widgets/common/post_card.dart';
import '../../widgets/carousel/property_carousel.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'filter_screen.dart';
import '../post/post_details_screen.dart';
import '../notification/notifications_screen.dart';
import 'saved_search_screen.dart';
import '../../../core/models/post_model.dart';
import '../../../core/models/vietnam_address_model.dart';
import '../../../core/services/post_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/favorite_service.dart';
import '../../../core/services/auth_storage_service.dart';
import '../../../core/services/vietnam_address_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Màn hình Home / Dashboard - Thiết kế theo mẫu
class HomeScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;
  final void Function({Map<String, dynamic>? filters})? onSearchTap;
  
  const HomeScreen({
    super.key, 
    this.onMenuTap, 
    this.onSearchTap,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  bool _isLoading = false;
  List<PostModel> _featuredProperties = [];
  List<PostModel> _latestProperties = [];
  final PostService _postService = PostService();
  final FavoriteService _favoriteService = FavoriteService();
  final NotificationService _notificationService = NotificationService();
  VoidCallback? _favoriteListener;
  String _selectedLocation = 'Hồ Chí Minh'; // Default location
  String? _selectedProvinceCode; // Province code từ VietnamAddressService
  bool _hasUnreadNotifications = false;

  // Categories từ API backend
  List<_CategoryItem> _categories = [];

  @override
  void initState() {
    super.initState();
    _favoriteListener = () => setState(() {});
    _favoriteService.favoritesListenable.addListener(_favoriteListener!);
    _loadSelectedLocation();
    _loadCategories();
    _loadProperties();
    _checkUnreadNotifications();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _postService.getActiveCategories();
      if (!mounted) return;
      
      setState(() {
        _categories = categories.map((category) {
          return _CategoryItem(
            icon: _getIconFromString(category.icon ?? 'home'),
            label: category.name,
            color: AppColors.primary,
            categoryId: category.id,
          );
        }).toList();
      });
    } catch (e) {
      debugPrint('Error loading categories: $e');
      // Nếu lỗi, dùng categories mặc định
      setState(() {
        _categories = [
          _CategoryItem(
            icon: FontAwesomeIcons.key,
            label: 'Cho thuê',
            color: AppColors.primary,
            transactionType: TransactionType.rent,
          ),
          _CategoryItem(
            icon: FontAwesomeIcons.house,
            label: 'Bán',
            color: AppColors.primary,
            transactionType: TransactionType.sale,
          ),
          _CategoryItem(
            icon: FontAwesomeIcons.store,
            label: 'Thương mại',
            color: AppColors.primary,
            isCommercial: true,
          ),
          _CategoryItem(
            icon: FontAwesomeIcons.building,
            label: 'Dân cư',
            color: AppColors.primary,
            isResidential: true,
          ),
        ];
      });
    }
  }

  /// Map icon string từ API thành FontAwesomeIcons (chỉ dùng REGULAR/outline)
  IconData _getIconFromString(String iconString) {
    switch (iconString.toLowerCase()) {
      case 'home':
      case 'house':
        return FontAwesomeIcons.house; // REGULAR (outline)
      case 'apartment':
      case 'building':
        return FontAwesomeIcons.building; // REGULAR (outline)
      case 'land':
        // Dùng tag thay vì mountain để đảm bảo outline
        return FontAwesomeIcons.tag; // REGULAR (outline)
      case 'room':
        // Dùng doorOpen nếu có REGULAR, nếu không thì dùng tag
        return FontAwesomeIcons.doorOpen; // REGULAR (outline)
      case 'office':
        return FontAwesomeIcons.briefcase; // REGULAR (outline)
      case 'shop':
      case 'store':
        return FontAwesomeIcons.store; // REGULAR (outline)
      case 'key':
        return FontAwesomeIcons.key; // REGULAR (outline)
      default:
        return FontAwesomeIcons.tag; // REGULAR (outline) - Default icon
    }
  }

  Future<void> _loadSelectedLocation() async {
    try {
      // Dùng flutter_secure_storage để nhất quán với dự án
      const storage = FlutterSecureStorage();
      final savedCityName = await storage.read(key: 'selected_city_name');
      final savedProvinceCode = await storage.read(key: 'selected_province_code');
      
      if (savedCityName != null && savedCityName.isNotEmpty) {
        setState(() {
          _selectedLocation = savedCityName;
          _selectedProvinceCode = savedProvinceCode;
        });
      } else {
        // Mặc định: Hồ Chí Minh hoặc Hà Nội (có thể lấy từ GPS hoặc user profile)
        // Tạm thời dùng Hồ Chí Minh
        setState(() {
          _selectedLocation = 'Hồ Chí Minh';
        });
      }
    } catch (e) {
      debugPrint('Error loading selected location: $e');
    }
  }

  Future<void> _showLocationPicker() async {
    try {
      // Dùng VietnamAddressService giống như create_post_screen.dart
      final selectedProvince = await showModalBottomSheet<VietnamProvince>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => _LocationPickerBottomSheet(
          selectedProvinceCode: _selectedProvinceCode,
        ),
      );

      if (selectedProvince != null) {
        // Lưu lựa chọn bằng flutter_secure_storage để nhất quán
        const storage = FlutterSecureStorage();
        await storage.write(key: 'selected_city_name', value: selectedProvince.name);
        await storage.write(key: 'selected_province_code', value: selectedProvince.code);

        setState(() {
          _selectedLocation = selectedProvince.name;
          _selectedProvinceCode = selectedProvince.code;
        });

        // Reload properties với location mới
    _loadProperties();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tải danh sách thành phố: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _checkUnreadNotifications() async {
    try {
      final userId = await AuthStorageService.getUserId();
      if (userId == null) return;
      
      await _notificationService.initialize();
      final notifications = _notificationService.notifications;
      final hasUnread = notifications.any((n) => !n.isRead);
      
      if (mounted) {
        setState(() {
          _hasUnreadNotifications = hasUnread;
        });
      }
    } catch (e) {
      // Ignore errors, keep default false
    }
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
    // Gọi callback từ MainLayout để chuyển sang tab Search
    widget.onSearchTap?.call();
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

  void _handleCategoryTap(_CategoryItem category) {
    // Điều hướng đến SearchScreen với category đã chọn
    final filters = <String, dynamic>{};
    
    // Nếu có categoryId, thêm vào filters
    if (category.categoryId != null) {
      filters['categoryId'] = category.categoryId;
    }
    
    // Nếu có transactionType, thêm vào filters
    if (category.transactionType != null) {
      filters['status'] = category.transactionType == TransactionType.sale ? 'Sale' : 'Rent';
    }
    
    // Gọi callback để chuyển sang tab Search với filters
    widget.onSearchTap?.call(filters: filters);
  }

  /// Normalize tên thành phố để so sánh (loại bỏ "Thành phố", "Tỉnh", etc.)
  String _normalizeCityName(String cityName) {
    return cityName
        .replaceAll('Thành phố', '')
        .replaceAll('TP.', '')
        .replaceAll('TP', '')
        .replaceAll('Tỉnh', '')
        .trim()
        .toLowerCase();
  }

  /// Lấy cityName từ post (ưu tiên cityName trực tiếp, fallback về nested data)
  String? _getCityNameFromPost(PostModel post) {
    // Ưu tiên dùng cityName trực tiếp từ API
    if (post.cityName != null && post.cityName!.isNotEmpty) {
      return post.cityName;
    }
    // Fallback về nested data
    return post.ward?.district?.city?.name;
  }

  Future<void> _loadProperties() async {
    setState(() => _isLoading = true);
    try {
      final properties = await _postService.getPosts(isApproved: true);
      if (!mounted) return;
      
      debugPrint('[HomeScreen] Total properties loaded: ${properties.length}');
      debugPrint('[HomeScreen] Selected location: $_selectedLocation');
      
      // Featured properties: lấy tất cả posts, sắp xếp theo ngày tạo mới nhất, lấy 5 đầu tiên (KHÔNG filter theo city)
      final allPropertiesSorted = List<PostModel>.from(properties);
      allPropertiesSorted.sort((a, b) => b.created.compareTo(a.created));
      final featured = allPropertiesSorted.take(5).toList();
      
      // Lấy danh sách ID của featured posts để loại trừ khỏi latest
      final featuredIds = featured.map((p) => p.id).toSet();
      
      // Latest properties: filter theo thành phố đã chọn và loại trừ các posts đã có trong featured
      final normalizedSelectedLocation = _normalizeCityName(_selectedLocation);
      debugPrint('[HomeScreen] Normalized selected location: $normalizedSelectedLocation');
      
      final filteredProperties = properties.where((post) {
        // Loại trừ các posts đã có trong featured
        if (featuredIds.contains(post.id)) {
          return false;
        }
        
        // Filter theo thành phố đã chọn
        final postCityName = _getCityNameFromPost(post);
        if (postCityName == null) {
          debugPrint('[HomeScreen] Post ${post.id}: No cityName found');
          return false;
        }
        final normalizedPostCityName = _normalizeCityName(postCityName);
        final matches = normalizedPostCityName == normalizedSelectedLocation;
        if (matches) {
          debugPrint('[HomeScreen] Post ${post.id}: Matches - $postCityName -> $normalizedPostCityName');
        }
        return matches;
      }).toList();
      
      debugPrint('[HomeScreen] Filtered properties count: ${filteredProperties.length}');
      
      // Sắp xếp theo ngày tạo mới nhất
      filteredProperties.sort((a, b) => b.created.compareTo(a.created));
      
      // Latest properties: lấy tất cả properties đã filter (hoặc tối đa 20 properties)
      final latest = filteredProperties.take(20).toList().cast<PostModel>();
      
      debugPrint('[HomeScreen] Featured: ${featured.length}, Latest: ${latest.length}');
      
      setState(() {
        _featuredProperties = featured;
        _latestProperties = latest;
        _isLoading = false;
      });
      
      // Load favorites nếu có userId
      try {
        final userId = await AuthStorageService.getUserId();
        if (userId != null) {
          await _favoriteService.loadFavorites(userId);
        }
      } catch (e) {
        debugPrint('Error loading favorites: $e');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      debugPrint('Error loading properties: $e');
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header cố định - không scroll
            _buildHeader(),
            
            // Phần nội dung có thể scroll (bao gồm search bar)
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadProperties,
                color: AppColors.primary,
                child: CustomScrollView(
                  slivers: [
                    // Search Bar - nằm trong phần scroll
                    SliverToBoxAdapter(
                      child: _buildSearchBar(),
                    ),
                    
                    // Categories - "Bạn đang tìm gì?"
                    SliverToBoxAdapter(
                      child: _buildCategories(),
                    ),
                    
                    // Featured Properties Section
                    SliverToBoxAdapter(
                      child: _buildFeaturedSection(),
                    ),
                    
                    // Latest Properties Section
                    SliverToBoxAdapter(
                      child: _buildLatestSection(),
                    ),
                    
                    // Bottom padding - Giảm khoảng cách với lề dưới
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 4),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      // color: Colors.purple,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 8), // Cùng padding với search bar
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Hamburger menu
          IconButton(
            icon: const FaIcon(
              FontAwesomeIcons.bars,
              size: 18,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: widget.onMenuTap ?? () {
              Scaffold.of(context).openDrawer();
            },
          ),
          const SizedBox(width: 12),
          // Location selector - căn lề bên trái, nằm ngang với hamburger
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // "Current Location" text
              Text(
                'Vị trí hiện tại',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 2),
              // Location selector row
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Location pin icon
                  const FaIcon(
                    FontAwesomeIcons.locationPin,
                    size: 14,
                    color: AppColors.primary,
              ),
                  const SizedBox(width: 4),
                  // Location name - Button để chọn vị trí
                  GestureDetector(
                    onTap: _showLocationPicker,
                    child: Text(
                      _selectedLocation,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          // Button để quản lý khu vực quan tâm
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SavedSearchScreen(),
                ),
              );
            },
            icon: const FaIcon(
              FontAwesomeIcons.mapLocationDot,
              size: 18,
              color: AppColors.primary,
            ),
            tooltip: 'Khu vực quan tâm',
          ),
          const SizedBox(width: 1),
          // Notification icon - chỉ hiển thị chấm đỏ khi có thông báo chưa đọc
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
              // Refresh unread status sau khi quay lại
              _checkUnreadNotifications();
            },
            icon: SizedBox(
              width: 24,
              height: 24,
            child: Stack(
                clipBehavior: Clip.none,
              children: [
                const Center(
                    child: FaIcon(
                      FontAwesomeIcons.bell,
                      size: 18,
                    ),
                  ),
                  // Chỉ hiển thị chấm đỏ khi có thông báo chưa đọc
                  if (_hasUnreadNotifications)
                Positioned(
                      right: -2,
                      top: -2,
                  child: Container(
                        width: 8,
                        height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 4), // Giảm thêm: top từ 4 xuống 2, bottom từ 8 xuống 4
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10), // Bo góc nhẹ
        ),
        child: TextField(
          controller: _searchController,
          onTap: _handleSearch,
          readOnly: true,
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
            suffixIcon: Container(
              alignment: Alignment.center,
              width: 50,
              child: GestureDetector(
                onTap: _handleFilter,
                behavior: HitTestBehavior.opaque,
                child: FaIcon(
                  FontAwesomeIcons.sliders,
                  color: Colors.grey.shade700,
                  size: 18,
                ),
              ),
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
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 2, 20, 4), // Giảm thêm: top từ 4 xuống 2, bottom từ 8 xuống 4
          child: Text(
            'Bạn đang tìm gì?',
            style: AppTextStyles.h5.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              final screenWidth = MediaQuery.of(context).size.width;
              final padding = 20.0;
              final spacing = 12.0;
              final categoryWidth = (screenWidth - (padding * 2) - (spacing * 3)) / 4; // Width cho mỗi category
              
              return GestureDetector(
                onTap: () => _handleCategoryTap(category),
                child: Container(
                  width: categoryWidth,
                  margin: EdgeInsets.only(right: index < _categories.length - 1 ? spacing : 0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: category.color.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: FaIcon(
                        category.icon,
                            size: 22,
                            color: category.color,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        category.label,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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

  Widget _buildFeaturedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 4), // Giảm thêm: top từ 12 xuống 6, bottom từ 8 xuống 4
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bất động sản nổi bật',
                style: AppTextStyles.h5.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        _isLoading
            ? SizedBox(
                height: 160,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 3,
                  itemBuilder: (context, index) {
                    final screenWidth = MediaQuery.of(context).size.width;
                    final padding = 20.0;
                    final cardWidth = screenWidth - (padding * 2);
                    return Container(
                      width: screenWidth,
                      alignment: Alignment.center,
                      child: Container(
                        width: cardWidth,
                        height: 136,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  },
                ),
              )
            : PropertyCarousel(
                properties: _featuredProperties,
                height: 160,
                onTap: (property) {
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
                onFavoriteTap: (property) async {
                  try {
                    final userId = await AuthStorageService.getUserId();
                    await _favoriteService.toggleFavorite(property, userId);
                    if (mounted) {
                      setState(() {}); // Refresh UI
                    }
                  } catch (e) {
                    debugPrint('Error toggling favorite: $e');
                  }
                },
                isFavorite: (postId) => _favoriteService.isFavorite(postId),
              ),
      ],
    );
  }

  Widget _buildLatestSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 4), // Giảm thêm: top từ 12 xuống 6, bottom từ 8 xuống 4
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mới nhất tại $_selectedLocation',
                style: AppTextStyles.h5.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        _isLoading
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
                  children: List.generate(
                    3,
                    (index) => Container(
              height: 120,
                      margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
              ),
                    ),
                  ),
                ),
              )
            : _latestProperties.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Chưa có bất động sản mới nhất',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
                      ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: _latestProperties.asMap().entries.map((entry) {
                        final index = entry.key;
                        final property = entry.value;
                        return Padding(
                          padding: EdgeInsets.only(bottom: index < _latestProperties.length - 1 ? 8 : 0), // Giảm margin giữa các card từ 16 xuống 8
                          child: PostCard(
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
                            onFavoriteTap: () async {
                              try {
                                final userId = await AuthStorageService.getUserId();
                                await _favoriteService.toggleFavorite(property, userId);
                                if (mounted) {
                                  setState(() {}); // Refresh UI
                                }
                              } catch (e) {
                                debugPrint('Error toggling favorite: $e');
                              }
                            },
                          ),
                        );
                      }).toList(),
        ),
      ),
      ],
    );
  }
}

class _CategoryItem {
  final IconData icon;
  final String label;
  final Color color;
  final TransactionType? transactionType;
  final bool isCommercial;
  final bool isResidential;
  final int? categoryId; // ID từ API backend

  _CategoryItem({
    required this.icon,
    required this.label,
    required this.color,
    this.transactionType,
    this.isCommercial = false,
    this.isResidential = false,
    this.categoryId,
  });
}

/// Bottom Sheet để chọn thành phố - Dùng VietnamAddressService
class _LocationPickerBottomSheet extends StatefulWidget {
  final String? selectedProvinceCode;

  const _LocationPickerBottomSheet({
    this.selectedProvinceCode,
  });

  @override
  State<_LocationPickerBottomSheet> createState() => _LocationPickerBottomSheetState();
}

class _LocationPickerBottomSheetState extends State<_LocationPickerBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<VietnamProvince> _provinces = [];
  List<VietnamProvince> _filteredProvinces = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadProvinces();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    
    if (query.isEmpty) {
      setState(() {
        _filteredProvinces = _provinces;
      });
      return;
    }

    setState(() {
      _filteredProvinces = _provinces.where((province) {
        return province.name.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _loadProvinces() async {
    try {
      final provinces = await VietnamAddressService.fetchProvinces();
      if (!mounted) return;
      
      setState(() {
        _provinces = provinces;
        _filteredProvinces = provinces;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading provinces: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tải danh sách thành phố: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final fixedHeight = screenHeight * 0.8; // Chiều cao cố định 80% màn hình
    
    return SizedBox(
      height: fixedHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Chọn thành phố',
                  style: AppTextStyles.h5,
                ),
                IconButton(
                  icon: const FaIcon(FontAwesomeIcons.xmark),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: _searchController,
                autofocus: false,
                style: TextStyle(
                  color: Colors.grey.shade800,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm thành phố...',
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
                  suffixIcon: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _searchController,
                    builder: (context, value, child) {
                      return value.text.isNotEmpty
                          ? IconButton(
                              icon: FaIcon(
                                FontAwesomeIcons.xmark,
                                size: 16,
                                color: Colors.grey.shade700,
                              ),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : const SizedBox.shrink();
                    },
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
                ),
              ),
            ),
          ),
          const Divider(),
          // List provinces - Expanded để luôn chiếm đủ không gian còn lại
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _filteredProvinces.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            _searchController.text.trim().isEmpty
                                ? 'Không có dữ liệu thành phố'
                                : 'Không tìm thấy thành phố',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredProvinces.length,
                        itemBuilder: (context, index) {
                          final province = _filteredProvinces[index];
                          final isSelected = province.code == widget.selectedProvinceCode;
                          
                          return ListTile(
                            leading: FaIcon(
                              FontAwesomeIcons.locationDot,
                              color: isSelected ? AppColors.primary : AppColors.textSecondary,
                              size: 18,
                            ),
                            title: Text(
                              province.name,
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                              ),
                            ),
                            trailing: isSelected
                                ? FaIcon(
                                    FontAwesomeIcons.circleCheck,
                                    color: AppColors.primary,
                                    size: 20,
                                  )
                                : null,
                            onTap: () => Navigator.pop(context, province),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

