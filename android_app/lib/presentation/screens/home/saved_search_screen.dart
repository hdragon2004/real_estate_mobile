import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/empty_state.dart';
import '../../../core/models/saved_search_model.dart';
import '../../../core/services/saved_search_service.dart';
import '../../../core/services/auth_storage_service.dart';
import '../../../core/services/nominatim_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_shadows.dart';

/// Màn hình quản lý khu vực quan tâm
class SavedSearchScreen extends StatefulWidget {
  const SavedSearchScreen({super.key});

  @override
  State<SavedSearchScreen> createState() => _SavedSearchScreenState();
}

class _SavedSearchScreenState extends State<SavedSearchScreen> {
  final SavedSearchService _savedSearchService = SavedSearchService();
  bool _isLoading = false;
  List<SavedSearchModel> _savedSearches = [];
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadSavedSearches();
  }

  Future<void> _loadSavedSearches() async {
    try {
      _currentUserId = await AuthStorageService.getUserId();
      if (_currentUserId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng đăng nhập để quản lý khu vực quan tâm'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    } catch (e) {
      debugPrint('Error getting user ID: $e');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final data = await _savedSearchService.getUserSavedSearches();
      if (!mounted) return;

      setState(() {
        _savedSearches = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      debugPrint('Error loading saved searches: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tải khu vực quan tâm: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _deleteSavedSearch(SavedSearchModel savedSearch, int index) async {
    try {
      await _savedSearchService.deleteSavedSearch(savedSearch.id);
      if (!mounted) return;

      setState(() {
        _savedSearches.removeAt(index);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã xóa khu vực quan tâm'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi xóa khu vực quan tâm: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _showAddSavedSearchDialog() async {
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đăng nhập'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddSavedSearchBottomSheet(
        userId: _currentUserId!,
        onSaved: () {
          _loadSavedSearches();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Khu vực quan tâm'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            onPressed: _showAddSavedSearchDialog,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: AppShadows.floatingButton,
              ),
              child: const FaIcon(
                FontAwesomeIcons.plus,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : _savedSearches.isEmpty
              ? EmptyState(
                  icon: FontAwesomeIcons.mapLocationDot,
                  title: 'Chưa có khu vực quan tâm',
                  message: 'Thêm khu vực quan tâm để nhận thông báo khi có bài đăng mới',
                  buttonText: 'Thêm khu vực',
                  onButtonTap: _showAddSavedSearchDialog,
                )
              : RefreshIndicator(
                  onRefresh: _loadSavedSearches,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _savedSearches.length,
                    itemBuilder: (context, index) {
                      final savedSearch = _savedSearches[index];
                      return _SavedSearchCard(
                        savedSearch: savedSearch,
                        onDelete: () => _deleteSavedSearch(savedSearch, index),
                      );
                    },
                  ),
                ),
   );
  }
}

/// Card hiển thị một khu vực quan tâm
class _SavedSearchCard extends StatelessWidget {
  final SavedSearchModel savedSearch;
  final VoidCallback onDelete;

  const _SavedSearchCard({
    required this.savedSearch,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppShadows.card,
        border: Border.all(
          color: savedSearch.enableNotification
              ? AppColors.primary.withValues(alpha: 0.3)
              : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FaIcon(
                FontAwesomeIcons.mapLocationDot,
                size: 20,
                color: AppColors.primary,
              ),
              const Gap(8),
              Expanded(
                child: Text(
                  savedSearch.locationName ?? 
                  '${savedSearch.centerLatitude.toStringAsFixed(4)}, ${savedSearch.centerLongitude.toStringAsFixed(4)}',
                  style: AppTextStyles.h6.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const FaIcon(
                  FontAwesomeIcons.trash,
                  size: 16,
                  color: AppColors.error,
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Xóa khu vực quan tâm'),
                      content: const Text('Bạn có chắc chắn muốn xóa khu vực này?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Hủy'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            onDelete();
                          },
                          child: const Text(
                            'Xóa',
                            style: TextStyle(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          const Gap(12),
          Row(
            children: [
              _InfoChip(
                icon: FontAwesomeIcons.circleDot,
                label: 'Bán kính: ${savedSearch.radiusKm.toStringAsFixed(1)} km',
              ),
              const Gap(8),
              _InfoChip(
                icon: FontAwesomeIcons.handHoldingDollar,
                label: savedSearch.transactionType == 'Sale' ? 'Mua bán' : 'Cho thuê',
              ),
            ],
          ),
          if (savedSearch.minPrice != null || savedSearch.maxPrice != null) ...[
            const Gap(8),
            _InfoChip(
              icon: FontAwesomeIcons.moneyBill,
              label: _formatPriceRange(savedSearch.minPrice, savedSearch.maxPrice),
            ),
          ],
          const Gap(12),
          Row(
            children: [
              FaIcon(
                savedSearch.enableNotification
                    ? FontAwesomeIcons.bell
                    : FontAwesomeIcons.bellSlash,
                size: 14,
                color: savedSearch.enableNotification
                    ? AppColors.primary
                    : Colors.grey,
              ),
              const Gap(6),
              Text(
                savedSearch.enableNotification
                    ? 'Đang nhận thông báo'
                    : 'Đã tắt thông báo',
                style: AppTextStyles.bodySmall.copyWith(
                  color: savedSearch.enableNotification
                      ? AppColors.primary
                      : Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatPriceRange(double? minPrice, double? maxPrice) {
    if (minPrice != null && maxPrice != null) {
      return '${_formatPrice(minPrice)} - ${_formatPrice(maxPrice)}';
    } else if (minPrice != null) {
      return 'Từ ${_formatPrice(minPrice)}';
    } else if (maxPrice != null) {
      return 'Đến ${_formatPrice(maxPrice)}';
    }
    return '';
  }

  String _formatPrice(double price) {
    if (price >= 1000000000) {
      return '${(price / 1000000000).toStringAsFixed(1)} tỷ';
    } else if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(0)} triệu';
    }
    return price.toStringAsFixed(0);
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(icon, size: 12, color: AppColors.primary),
          const Gap(4),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet để thêm khu vực quan tâm mới
class _AddSavedSearchBottomSheet extends StatefulWidget {
  final int userId;
  final VoidCallback onSaved;

  const _AddSavedSearchBottomSheet({
    required this.userId,
    required this.onSaved,
  });

  @override
  State<_AddSavedSearchBottomSheet> createState() => _AddSavedSearchBottomSheetState();
}

class _AddSavedSearchBottomSheetState extends State<_AddSavedSearchBottomSheet> {
  final MapController _mapController = MapController();
  final SavedSearchService _savedSearchService = SavedSearchService();
  final TextEditingController _radiusController = TextEditingController(text: '5');
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  LatLng? _selectedLocation; // Chỉ có giá trị khi user chọn vị trí
  LatLng _currentLocation = const LatLng(10.8231, 106.6297); // Default: HCM
  String _transactionType = 'Sale';
  bool _enableNotification = true;
  bool _isLoading = false;
  String? _locationName;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    // Listen to radius changes để update circle trên map
    _radiusController.addListener(() {
      if (_selectedLocation != null) {
        setState(() {}); // Rebuild để update circle
      }
    });
  }

  /// Lấy vị trí GPS hiện tại của user (chạy ngầm, không block UI)
  Future<void> _getCurrentLocation() async {
    try {
      // Kiểm tra quyền location
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      // Kiểm tra permission đã được cấp
      if (permission != LocationPermission.whileInUse && 
          permission != LocationPermission.always) {
        return;
      }

      // Lấy vị trí hiện tại với timeout
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Timeout getting current position');
        },
      );

      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
        
        // Move map đến vị trí hiện tại sau khi FlutterMap đã render
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _mapController.move(_currentLocation, 14.0); // Zoom level 14 để thấy rõ khu vực
          }
        });
      }
    } on TimeoutException {
      // Timeout, thử dùng last known position
      try {
        Position? lastPosition = await Geolocator.getLastKnownPosition();
        if (lastPosition != null && mounted) {
          setState(() {
            _currentLocation = LatLng(lastPosition.latitude, lastPosition.longitude);
          });
          
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _mapController.move(_currentLocation, 14.0);
            }
          });
          return;
        }
      } catch (e) {
        // Ignore error
      }
    } catch (e) {
      // Lỗi khi lấy vị trí, thử dùng last known position
      try {
        Position? lastPosition = await Geolocator.getLastKnownPosition();
        if (lastPosition != null && mounted) {
          setState(() {
            _currentLocation = LatLng(lastPosition.latitude, lastPosition.longitude);
          });
          
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _mapController.move(_currentLocation, 14.0);
            }
          });
          return;
        }
      } catch (e2) {
        // Ignore error
      }
    }
  }

  @override
  void dispose() {
    _radiusController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  /// Tính toán các điểm để vẽ hình tròn chính xác trên map (dùng Haversine)
  List<LatLng> _generateCirclePoints(LatLng center, double radiusInKm) {
    const int points = 64;
    final List<LatLng> circlePoints = [];
    final double radiusInMeters = radiusInKm * 1000;
    
    for (int i = 0; i <= points; i++) {
      double angle = (i * 360 / points) * math.pi / 180;
      // Công thức tính toán chính xác dựa trên latitude
      // 111320m = khoảng cách 1 độ latitude tại xích đạo
      double lat = center.latitude + (radiusInMeters / 111320) * math.cos(angle);
      double lng = center.longitude + (radiusInMeters / (111320 * math.cos(center.latitude * math.pi / 180))) * math.sin(angle);
      
      circlePoints.add(LatLng(lat, lng));
    }
    
    return circlePoints;
  }

  Future<void> _reverseGeocode(LatLng location) async {
    try {
      final result = await NominatimService.reverseGeocode(
        location.latitude,
        location.longitude,
      );
      if (result != null && mounted) {
        setState(() {
          _locationName = result;
        });
      }
    } catch (e) {
      debugPrint('Error reverse geocoding: $e');
    }
  }

  Future<void> _saveSavedSearch() async {
    // Kiểm tra user đã chọn vị trí chưa
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn vị trí trên bản đồ'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final radius = double.tryParse(_radiusController.text);
    if (radius == null || radius < 0.1 || radius > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bán kính phải từ 0.1 đến 100 km'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final minPrice = _minPriceController.text.isEmpty
        ? null
        : double.tryParse(_minPriceController.text.replaceAll(',', ''));
    final maxPrice = _maxPriceController.text.isEmpty
        ? null
        : double.tryParse(_maxPriceController.text.replaceAll(',', ''));

    if (minPrice != null && maxPrice != null && minPrice > maxPrice) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Giá tối thiểu phải nhỏ hơn giá tối đa'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final savedSearch = SavedSearchModel(
        id: 0,
        userId: widget.userId,
        centerLatitude: _selectedLocation!.latitude,
        centerLongitude: _selectedLocation!.longitude,
        radiusKm: radius,
        transactionType: _transactionType,
        minPrice: minPrice,
        maxPrice: maxPrice,
        enableNotification: _enableNotification,
        createdAt: DateTime.now(),
        locationName: _locationName,
      );

      await _savedSearchService.createSavedSearch(savedSearch);
      if (!mounted) return;

      Navigator.pop(context);
      widget.onSaved();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã thêm khu vực quan tâm'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi thêm khu vực quan tâm: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Thêm khu vực quan tâm',
                  style: AppTextStyles.h6,
                ),
                const Spacer(),
                IconButton(
                  icon: const FaIcon(FontAwesomeIcons.xmark),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Map
                  Container(
                    height: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        children: [
                          FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: _currentLocation, // Vị trí GPS hiện tại
                              initialZoom: 14.0, // Zoom in để thấy rõ khu vực xung quanh
                              onTap: (tapPosition, point) {
                                setState(() {
                                  _selectedLocation = point;
                                });
                                _reverseGeocode(point);
                                // Zoom in khi user chọn vị trí
                                _mapController.move(point, 15.0);
                              },
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.realestatehub.app',
                              ),
                              // Chỉ hiển thị marker và circle khi user đã chọn vị trí
                              if (_selectedLocation != null) ...[
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: _selectedLocation!,
                                      width: 40,
                                      height: 40,
                                      child: const FaIcon(
                                        FontAwesomeIcons.locationPin,
                                        color: AppColors.primary,
                                        size: 40,
                                      ),
                                    ),
                                  ],
                                ),
                                // Chỉ vẽ circle khi có bán kính hợp lệ (> 0)
                                if (_radiusController.text.isNotEmpty)
                                  Builder(
                                    builder: (context) {
                                      final radius = double.tryParse(_radiusController.text);
                                      if (radius != null && radius > 0) {
                                        return PolygonLayer(
                                          polygons: [
                                            Polygon(
                                              points: _generateCirclePoints(
                                                _selectedLocation!,
                                                radius,
                                              ),
                                              color: AppColors.primary.withValues(alpha: 0.15),
                                              borderColor: AppColors.primary,
                                              borderStrokeWidth: 2,
                                            ),
                                          ],
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    },
                                  ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Gap(16),
                  Text(
                    _locationName ?? 'Chạm vào bản đồ để chọn vị trí',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const Gap(24),
                  // Bán kính
                  Text('Bán kính (km)', style: AppTextStyles.labelLarge),
                  const Gap(8),
                  TextField(
                    controller: _radiusController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Nhập bán kính',
                      suffixText: 'km',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {}); // Refresh map circle
                    },
                  ),
                  const Gap(16),
                  // Loại giao dịch
                  Text('Loại giao dịch', style: AppTextStyles.labelLarge),
                  const Gap(8),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Mua bán'),
                          selected: _transactionType == 'Sale',
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _transactionType = 'Sale');
                            }
                          },
                        ),
                      ),
                      const Gap(8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Cho thuê'),
                          selected: _transactionType == 'Rent',
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _transactionType = 'Rent');
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const Gap(16),
                  // Khoảng giá
                  Text('Khoảng giá (tùy chọn)', style: AppTextStyles.labelLarge),
                  const Gap(8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _minPriceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Từ',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const Gap(8),
                      Expanded(
                        child: TextField(
                          controller: _maxPriceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Đến',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Gap(16),
                  // Bật thông báo
                  SwitchListTile(
                    title: const Text('Nhận thông báo khi có bài đăng mới'),
                    value: _enableNotification,
                    onChanged: (value) {
                      setState(() => _enableNotification = value);
                    },
                  ),
                ],
              ),
            ),
          ),
          // Footer button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveSavedSearch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Lưu khu vực quan tâm',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

