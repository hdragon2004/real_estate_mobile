import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:gap/gap.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/models/vietnam_address_model.dart';
import '../../../core/models/address_data_model.dart';
import '../../../core/services/vietnam_address_service.dart';
import '../../../core/services/nominatim_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_shadows.dart';
import '../../widgets/common/app_dropdown.dart';

/// Widget chọn địa chỉ với bản đồ OpenStreetMap (FREE)
/// 
/// TẠI SAO DÙNG OpenStreetMap thay vì Google Maps?
/// - Google Maps API có phí và cần API key
/// - OpenStreetMap hoàn toàn FREE, không cần API key
/// - Đủ tốt cho việc hiển thị bản đồ và chọn vị trí
/// 
/// TẠI SAO TỌA ĐỘ LẤY TỪ MAP TAP thay vì tự động?
/// - Độ chính xác: User biết chính xác vị trí của bất động sản
/// - Tránh lỗi: Geocoding có thể sai, đặc biệt với địa chỉ Việt Nam
/// - User control: User có quyền kiểm soát vị trí chính xác
class AddressSelectionWidget extends StatefulWidget {
  /// Callback khi user chọn địa chỉ xong
  final Function(AddressData)? onAddressSelected;
  
  /// Địa chỉ ban đầu (nếu có)
  final AddressData? initialAddress;

  const AddressSelectionWidget({
    super.key,
    this.onAddressSelected,
    this.initialAddress,
  });

  @override
  State<AddressSelectionWidget> createState() => _AddressSelectionWidgetState();
}

class _AddressSelectionWidgetState extends State<AddressSelectionWidget> {
  // Form controllers
  final _streetController = TextEditingController();
  
  // Selected values
  VietnamProvince? _selectedProvince;
  VietnamDistrict? _selectedDistrict;
  VietnamWard? _selectedWard;
  
  // Data lists
  List<VietnamProvince> _provinces = [];
  List<VietnamDistrict> _districts = [];
  List<VietnamWard> _wards = [];
  
  // Map state
  final MapController _mapController = MapController();
  LatLng? _selectedLocation;
  LatLng? _mapCenter;
  bool _isLoadingMapCenter = false;
  
  // UI state
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProvinces();
    _loadInitialData();
  }

  @override
  void dispose() {
    _streetController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _loadInitialData() {
    if (widget.initialAddress != null) {
      _streetController.text = widget.initialAddress!.street;
      // Load province/district/ward từ initialAddress (dùng objects, không duplicate)
      _selectedProvince = widget.initialAddress!.province;
      _selectedDistrict = widget.initialAddress!.district;
      _selectedWard = widget.initialAddress!.ward;
      
      if (widget.initialAddress!.latitude != 0 && 
          widget.initialAddress!.longitude != 0) {
        _selectedLocation = LatLng(
          widget.initialAddress!.latitude,
          widget.initialAddress!.longitude,
        );
        _mapCenter = _selectedLocation;
      }
      
      // Load districts và wards nếu có initial data
      if (_selectedProvince != null) {
        _loadDistricts(_selectedProvince!.code);
      }
      if (_selectedDistrict != null) {
        _loadWards(_selectedDistrict!.code);
      }
    }
  }

  Future<void> _loadProvinces() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final provinces = await VietnamAddressService.fetchProvinces();
      if (!mounted) return;

      setState(() {
        _provinces = provinces;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Lỗi tải danh sách tỉnh/thành phố: $e';
      });
    }
  }

  Future<void> _loadDistricts(String provinceCode) async {
    try {
      final districts = await VietnamAddressService.fetchDistricts(provinceCode);
      if (!mounted) return;

      setState(() {
        _districts = districts;
        _selectedDistrict = null;
        _selectedWard = null;
        _wards = [];
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tải quận/huyện: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _loadWards(String districtCode) async {
    try {
      final wards = await VietnamAddressService.fetchWards(districtCode);
      if (!mounted) return;

      setState(() {
        _wards = wards;
        _selectedWard = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tải phường/xã: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  /// Center map dựa trên địa chỉ đã chọn
  /// CHỈ dùng để center map, KHÔNG dùng để lấy tọa độ
  // ignore: unused_element
  Future<void> _centerMapOnAddress() async {
    if (_selectedWard == null && _selectedDistrict == null) {
      // Default center: Việt Nam
      _mapCenter = const LatLng(16.0544, 108.2022);
      _mapController.move(_mapCenter!, 10.0);
      return;
    }

    setState(() {
      _isLoadingMapCenter = true;
    });

    try {
      // Tạo địa chỉ để geocode
      final addressParts = <String>[];
      if (_selectedWard != null) {
        addressParts.add(_selectedWard!.name);
      }
      if (_selectedDistrict != null) {
        addressParts.add(_selectedDistrict!.name);
      }
      if (_selectedProvince != null) {
        addressParts.add(_selectedProvince!.name);
      }
      
      final address = addressParts.join(', ');
      
      // Dùng Nominatim để center map (FREE, không cần Google API)
      final coordinates = await NominatimService.geocodeAddress(address);
      
      if (!mounted) return;
      
      if (coordinates != null) {
        final center = LatLng(coordinates['lat']!, coordinates['lon']!);
        setState(() {
          _mapCenter = center;
          _isLoadingMapCenter = false;
        });
        
        // Move map to center
        _mapController.move(center, 15.0);
      } else {
        // Fallback: center on Vietnam
        setState(() {
          _mapCenter = const LatLng(16.0544, 108.2022);
          _isLoadingMapCenter = false;
        });
        _mapController.move(_mapCenter!, 10.0);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingMapCenter = false;
      });
      // Fallback: center on Vietnam
      _mapCenter = const LatLng(16.0544, 108.2022);
      _mapController.move(_mapCenter!, 10.0);
    }
  }

  /// Mở bottom sheet để chọn vị trí trên map
  Future<void> _openMapSelector() async {
    // Center map trước khi mở
    await _centerMapOnAddress();
    
    if (!mounted) return;
    
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MapSelectorBottomSheet(
        mapController: _mapController,
        initialCenter: _mapCenter ?? const LatLng(16.0544, 108.2022),
        selectedLocation: _selectedLocation,
        onLocationSelected: (location) {
          setState(() {
            _selectedLocation = location;
          });
        },
      ),
    );
  }

  /// Validate và lưu địa chỉ
  void _saveAddress() {
    // Validation
    if (_selectedProvince == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn tỉnh/thành phố'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedDistrict == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn quận/huyện'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedWard == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn phường/xã'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final street = _streetController.text.trim();
    if (street.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập tên đường'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn vị trí trên bản đồ'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Tạo AddressData - Dùng factory method từ objects (không duplicate)
    final addressData = AddressData.fromVietnamAddress(
      province: _selectedProvince!,
      district: _selectedDistrict!,
      ward: _selectedWard!,
      street: street,
      latitude: _selectedLocation!.latitude,
      longitude: _selectedLocation!.longitude,
    );

    // Callback
    widget.onAddressSelected?.call(addressData);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            'Địa chỉ bất động sản',
            style: AppTextStyles.h5.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Gap(8),
          Text(
            'Chọn địa chỉ và vị trí trên bản đồ',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const Gap(24),

          // Error message
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error),
              ),
              child: Row(
                children: [
                  const FaIcon(
                    FontAwesomeIcons.circleExclamation,
                    color: AppColors.error,
                    size: 16,
                  ),
                  const Gap(8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Gap(16),
          ],

          // Province dropdown - Dùng AppDropdown thay vì _buildDropdown
          AppDropdown<VietnamProvince>(
            label: 'Tỉnh/Thành phố *',
            value: _selectedProvince,
            items: _provinces,
            displayText: (p) => p.name,
            onChanged: (province) {
              setState(() {
                _selectedProvince = province;
                _selectedDistrict = null;
                _selectedWard = null;
                _districts = [];
                _wards = [];
                _selectedLocation = null; // Reset location khi đổi tỉnh
              });
              if (province != null) {
                _loadDistricts(province.code);
              }
            },
            enabled: !_isLoading,
            isLoading: _isLoading,
            icon: Icons.location_city,
          ),
          const Gap(16),

          // District dropdown - Dùng AppDropdown
          AppDropdown<VietnamDistrict>(
            label: 'Quận/Huyện *',
            value: _selectedDistrict,
            items: _districts,
            displayText: (d) => d.name,
            onChanged: (district) {
              setState(() {
                _selectedDistrict = district;
                _selectedWard = null;
                _wards = [];
                _selectedLocation = null; // Reset location khi đổi quận
              });
              if (district != null) {
                _loadWards(district.code);
              }
            },
            enabled: _selectedProvince != null,
            icon: Icons.location_on,
          ),
          const Gap(16),

          // Ward dropdown - Dùng AppDropdown
          AppDropdown<VietnamWard>(
            label: 'Phường/Xã *',
            value: _selectedWard,
            items: _wards,
            displayText: (w) => w.name,
            onChanged: (ward) {
              setState(() {
                _selectedWard = ward;
                _selectedLocation = null; // Reset location khi đổi phường
              });
            },
            enabled: _selectedDistrict != null,
            icon: Icons.place,
          ),
          const Gap(16),

          // Street input
          TextFormField(
            controller: _streetController,
            decoration: InputDecoration(
              labelText: 'Tên đường/Số nhà *',
              hintText: 'Ví dụ: 123 Nguyễn Văn A',
              prefixIcon: const FaIcon(
                FontAwesomeIcons.road,
                size: 18,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: AppColors.surface,
            ),
            style: AppTextStyles.bodyMedium,
            textCapitalization: TextCapitalization.words,
          ),
          const Gap(24),

          // Map section
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      const FaIcon(
                        FontAwesomeIcons.mapLocationDot,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const Gap(12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Chọn vị trí trên bản đồ',
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (_selectedLocation != null) ...[
                              const Gap(4),
                              Text(
                                'Lat: ${_selectedLocation!.latitude.toStringAsFixed(6)}, '
                                'Lng: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (_isLoadingMapCenter)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                ),
                
                // Map preview (small)
                GestureDetector(
                  onTap: _openMapSelector,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(16),
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Map
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(16),
                          ),
                          child: FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: _mapCenter ?? const LatLng(16.0544, 108.2022),
                              initialZoom: _mapCenter != null ? 15.0 : 10.0,
                              interactionOptions: const InteractionOptions(
                                flags: InteractiveFlag.none,
                              ),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.example.android_app',
                              ),
                              if (_selectedLocation != null)
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: _selectedLocation!,
                                      width: 40,
                                      height: 40,
                                      child: const FaIcon(
                                        FontAwesomeIcons.locationPin,
                                        color: AppColors.error,
                                        size: 32,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        
                        // Overlay
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(16),
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const FaIcon(
                                  FontAwesomeIcons.handPointer,
                                  color: Colors.white,
                                  size: 32,
                                ),
                                const Gap(8),
                                Text(
                                  'Tap để chọn vị trí',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Gap(24),

          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveAddress,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const FaIcon(FontAwesomeIcons.check, size: 18),
                  const Gap(8),
                  Text(
                    'Xác nhận địa chỉ',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
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

  // Đã xóa _buildDropdown - dùng AppDropdown thay thế
}

/// Bottom sheet để chọn vị trí trên map
class _MapSelectorBottomSheet extends StatefulWidget {
  final MapController mapController;
  final LatLng initialCenter;
  final LatLng? selectedLocation;
  final Function(LatLng) onLocationSelected;

  const _MapSelectorBottomSheet({
    required this.mapController,
    required this.initialCenter,
    this.selectedLocation,
    required this.onLocationSelected,
  });

  @override
  State<_MapSelectorBottomSheet> createState() => _MapSelectorBottomSheetState();
}

class _MapSelectorBottomSheetState extends State<_MapSelectorBottomSheet> {
  LatLng? _currentSelection;

  @override
  void initState() {
    super.initState();
    _currentSelection = widget.selectedLocation;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const FaIcon(
                      FontAwesomeIcons.mapLocationDot,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const Gap(12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chọn vị trí trên bản đồ',
                            style: AppTextStyles.h6.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_currentSelection != null) ...[
                            const Gap(4),
                            Text(
                              'Lat: ${_currentSelection!.latitude.toStringAsFixed(6)}, '
                              'Lng: ${_currentSelection!.longitude.toStringAsFixed(6)}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const FaIcon(
                        FontAwesomeIcons.xmark,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(16),
              
              // Map
              Expanded(
                child: FlutterMap(
                  mapController: widget.mapController,
                  options: MapOptions(
                    initialCenter: widget.initialCenter,
                    initialZoom: 15.0,
                    onTap: (tapPosition, point) {
                      setState(() {
                        _currentSelection = point;
                      });
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.android_app',
                    ),
                    if (_currentSelection != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _currentSelection!,
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
                  ],
                ),
              ),
              
              // Confirm button
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  boxShadow: AppShadows.top,
                ),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _currentSelection != null
                          ? () {
                              widget.onLocationSelected(_currentSelection!);
                              Navigator.pop(context);
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const FaIcon(FontAwesomeIcons.check, size: 18),
                          const Gap(8),
                          Text(
                            'Xác nhận vị trí',
                            style: AppTextStyles.labelLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

