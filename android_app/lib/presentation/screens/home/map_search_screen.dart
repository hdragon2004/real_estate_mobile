import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/models/post_model.dart';
import '../../../core/services/post_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/utils/formatters.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/carousel/property_carousel.dart';
import '../post/post_details_screen.dart';


class MapSearchScreen extends StatefulWidget {
  const MapSearchScreen({super.key});

  @override
  State<MapSearchScreen> createState() => _MapSearchScreenState();
}

class _MapSearchScreenState extends State<MapSearchScreen> {
  final MapController _mapController = MapController();
  final PostService _postService = PostService();
  
  // Vị trí được chọn trên map (cho search)
  LatLng? _selectedCenter;
  
  // Vị trí hiện tại của user
  LatLng? _userLocation;
  
  // Radius options: 1km, 3km, 5km, 10km
  final List<double> _radiusOptions = [1.0, 3.0, 5.0, 10.0];
  double _selectedRadius = 3.0; // Default 3km
  
  // Map center (mặc định: Hà Nội - fallback nếu không lấy được vị trí)
  final LatLng _defaultCenter = const LatLng(21.0285, 105.8542);
  LatLng _currentCenter = const LatLng(21.0285, 105.8542);
  
  // Posts
  List<PostModel> _displayedPosts = []; // Posts đang hiển thị trên map
  
  bool _isSearching = false;
  bool _isLoadingLocation = true;
  bool _isLoadingPosts = false;
  bool _isSearchMode = false; // false = hiển thị posts cùng thành phố, true = hiển thị posts trong radius

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  /// Lấy vị trí hiện tại của user
  /// Sử dụng geolocator để lấy GPS location (FREE, không cần Google Maps API)
  Future<void> _getCurrentLocation() async {
    try {
      // Kiểm tra quyền location
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setMapCenter(_defaultCenter);
        _loadPostsForCity(null);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _setMapCenter(_defaultCenter);
          _loadPostsForCity(null);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _setMapCenter(_defaultCenter);
        _loadPostsForCity(null);
        return;
      }

      // Kiểm tra permission đã được cấp
      if (permission != LocationPermission.whileInUse && 
          permission != LocationPermission.always) {
        _setMapCenter(_defaultCenter);
        _loadPostsForCity(null);
        return;
      }

      // Lấy vị trí hiện tại với timeout
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Timeout getting current position');
        },
      );

      final currentLocation = LatLng(position.latitude, position.longitude);
      _userLocation = currentLocation;
      _setMapCenter(currentLocation);
      _loadPostsForCity(currentLocation);
    } on TimeoutException {
      // Timeout, thử dùng last known position
      try {
        Position? lastPosition = await Geolocator.getLastKnownPosition();
        if (lastPosition != null) {
          final lastLocation = LatLng(lastPosition.latitude, lastPosition.longitude);
          _userLocation = lastLocation;
          _setMapCenter(lastLocation);
          _loadPostsForCity(lastLocation);
          return;
        }
      } catch (e) {
        // Ignore error
      }
      _setMapCenter(_defaultCenter);
      _loadPostsForCity(null);
    } catch (e) {
      // Lỗi khi lấy vị trí, thử dùng last known position
      try {
        Position? lastPosition = await Geolocator.getLastKnownPosition();
        if (lastPosition != null) {
          final lastLocation = LatLng(lastPosition.latitude, lastPosition.longitude);
          _userLocation = lastLocation;
          _setMapCenter(lastLocation);
          _loadPostsForCity(lastLocation);
          return;
        }
      } catch (e2) {
        // Ignore error
      }
      _setMapCenter(_defaultCenter);
      _loadPostsForCity(null);
    }
  }

  void _setMapCenter(LatLng center) {
    if (!mounted) return;
    setState(() {
      _currentCenter = center;
      _isLoadingLocation = false;
    });
    // Center map
    _mapController.move(center, 13.0);
  }

  /// Load posts cùng thành phố với user (mặc định)
  /// Nếu không có cityName, dùng radius 50km từ vị trí user
  Future<void> _loadPostsForCity(LatLng? userLocation) async {
    setState(() => _isLoadingPosts = true);
    try {
      // Load tất cả posts có tọa độ
      final posts = await _postService.getPosts(isApproved: true);
      final postsWithLocation = posts.where((post) => 
        post.latitude != null && post.longitude != null
      ).toList();
      
      if (!mounted) return;
      
      List<PostModel> filteredPosts;
      
      if (userLocation != null) {
        // Lọc posts trong radius 50km từ vị trí user (bao gồm cùng thành phố)
        filteredPosts = postsWithLocation.where((post) {
          final distance = _calculateDistance(
            userLocation.latitude,
            userLocation.longitude,
            post.latitude!,
            post.longitude!,
          );
          return distance <= 50.0; // 50km radius
        }).toList();
      } else {
        // Nếu không có vị trí user, hiển thị tất cả posts
        filteredPosts = postsWithLocation;
      }
      
      setState(() {
        _displayedPosts = filteredPosts;
        _isLoadingPosts = false;
        _isSearchMode = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingPosts = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tải dữ liệu: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  /// Tính khoảng cách giữa 2 điểm bằng Haversine formula (km)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371; // Bán kính Trái Đất (km)
    
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    final distance = R * c;
    
    return distance;
  }

  double _toRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    // Không cho phép tap khi đang search
    if (_isSearching) return;
    
    setState(() {
      _selectedCenter = point;
    });
    // Tự động tìm kiếm khi chọn vị trí
    _performSearch();
  }

  /// Tạo các điểm để vẽ hình tròn
  List<LatLng> _generateCirclePoints(LatLng center, double radiusInMeters) {
    const int points = 64;
    final List<LatLng> circlePoints = [];
    
    for (int i = 0; i <= points; i++) {
      double angle = (i * 360 / points) * math.pi / 180;
      double lat = center.latitude + (radiusInMeters / 111320) * math.cos(angle);
      double lng = center.longitude + (radiusInMeters / (111320 * math.cos(center.latitude * math.pi / 180))) * math.sin(angle);
      circlePoints.add(LatLng(lat, lng));
    }
    
    return circlePoints;
  }

  /// Tìm kiếm posts trong radius đã chọn
  /// Tự động được gọi khi user chọn vị trí trên map
  Future<void> _performSearch() async {
    if (_selectedCenter == null) return;

    setState(() => _isSearching = true);

    try {
      // Tìm kiếm posts trong radius
      final results = await _postService.searchByRadius(
        centerLat: _selectedCenter!.latitude,
        centerLng: _selectedCenter!.longitude,
        radiusInKm: _selectedRadius,
      );

      if (!mounted) return;

      setState(() {
        _displayedPosts = results;
        _isSearchMode = true;
        _isSearching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSearching = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tìm kiếm: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  /// Reset về chế độ hiển thị posts cùng thành phố
  void _resetToDefault() {
    setState(() {
      _selectedCenter = null;
      _isSearchMode = false;
    });
    _loadPostsForCity(_userLocation);
  }

  /// Format giá ngắn gọn cho marker
  // Sử dụng Formatters.formatCurrency thay vì _formatPriceShort

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('Bản đồ', style: AppTextStyles.h6),
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Button hủy chọn vị trí
          if (_selectedCenter != null)
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.xmark, color: AppColors.textPrimary),
              onPressed: () {
                setState(() {
                  _selectedCenter = null;
                });
                // Nếu đang ở search mode, reset về chế độ mặc định
                if (_isSearchMode) {
                  _resetToDefault();
                }
              },
              tooltip: 'Hủy chọn vị trí',
            ),
          // Button reset về chế độ mặc định
          if (_isSearchMode)
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.rotateLeft, color: AppColors.textPrimary),
              onPressed: _resetToDefault,
              tooltip: 'Hiển thị tất cả',
            ),
        ],
      ),
      body: (_isLoadingLocation || _isLoadingPosts)
          ? const Center(child: LoadingIndicator())
          : Stack(
              children: [
                // Map - Full screen
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentCenter,
                    initialZoom: 13.0,
                    onTap: _onMapTap,
                  ),
                  children: [
                    // OpenStreetMap tiles
                    TileLayer(
                      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.android_app',
                      subdomains: const ['a', 'b', 'c'],
                    ),
                    // Markers cho posts
                          MarkerLayer(
                            markers: _displayedPosts.map((post) {
                              return Marker(
                                point: LatLng(post.latitude!, post.longitude!),
                                width: 80,
                                height: 40,
                                child: GestureDetector(
                                  onTap: () {
                                    // Navigate to post details
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PostDetailsScreen(
                                          propertyId: post.id.toString(),
                                          initialProperty: post,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.red, // Màu đỏ như trong ảnh
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                      boxShadow: AppShadows.medium,
                                    ),
                                    child: Text(
                                      Formatters.formatCurrency(post.price),
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                    // Marker tại điểm được chọn (cho search)
                    if (_selectedCenter != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selectedCenter!,
                            width: 50,
                            height: 50,
                            child: const FaIcon(
                              FontAwesomeIcons.locationPin,
                              color: AppColors.error,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                    // Circle hiển thị radius
                    if (_selectedCenter != null)
                      PolygonLayer(
                        polygons: [
                          Polygon(
                            points: _generateCirclePoints(
                              _selectedCenter!,
                              _selectedRadius * 1000,
                            ),
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderColor: AppColors.primary,
                            borderStrokeWidth: 3,
                          ),
                        ],
                      ),
                  ],
                ),
                
                // Radius selector - Top right
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: AppShadows.medium,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Bán kính: ',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        DropdownButton<double>(
                          value: _selectedRadius,
                          underline: const SizedBox.shrink(),
                          icon: const FaIcon(
                            FontAwesomeIcons.chevronDown,
                            size: 12,
                            color: AppColors.textSecondary,
                          ),
                          style: AppTextStyles.labelMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          items: _radiusOptions.map((radius) {
                            return DropdownMenuItem<double>(
                              value: radius,
                              child: Text(
                                '${radius.toStringAsFixed(0)} km',
                                style: AppTextStyles.bodyMedium,
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedRadius = value;
                              });
                              // Tự động tìm kiếm lại nếu đã chọn vị trí
                              if (_selectedCenter != null) {
                                _mapController.move(_selectedCenter!, _mapController.camera.zoom);
                                _performSearch();
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Info card - Top left
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: AppShadows.medium,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const FaIcon(
                              FontAwesomeIcons.locationDot,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${_displayedPosts.length} bài đăng',
                              style: AppTextStyles.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        if (_selectedCenter != null) ...[
                          const Gap(8),
                          Text(
                            'Bán kính: ${_selectedRadius.toStringAsFixed(0)} km',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                
                // Property cards - Bottom (scrollable, no background, directly on map)
                // Sử dụng PropertyCarousel với hiệu ứng snap và căn giữa như home screen
                if (_displayedPosts.isNotEmpty)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: PropertyCarousel(
                      properties: _displayedPosts,
                      height: 200,
                      onTap: (post) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PostDetailsScreen(
                              propertyId: post.id.toString(),
                              initialProperty: post,
                            ),
                          ),
                        );
                      },
                      // Không truyền onFavoriteTap và isFavorite để ẩn icon trái tim
                    ),
                  ),
              ],
            ),
    );
  }
}
