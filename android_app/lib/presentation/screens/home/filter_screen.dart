import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';
import '../../../core/models/category_model.dart';
import '../../../core/models/vietnam_address_model.dart';
import '../../../core/repositories/category_repository.dart';
import '../../../core/services/vietnam_address_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Model cho Filter
class FilterModel {
  int? categoryId;
  double? minPrice;
  double? maxPrice;
  double? minArea;
  double? maxArea;
  int? soPhongNgu;
  int? soPhongTam;
  String? cityName; 
  String? districtName; 
  String? wardName; 
  String? status;
  String? transactionType;

  FilterModel({
    this.categoryId,
    this.minPrice,
    this.maxPrice,
    this.minArea,
    this.maxArea,
    this.soPhongNgu,
    this.soPhongTam,
    this.cityName,
    this.districtName,
    this.wardName,
    this.status,
    this.transactionType,
  });

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};
    if (categoryId != null) params['categoryId'] = categoryId;
    if (minPrice != null) params['minPrice'] = minPrice;
    if (maxPrice != null) params['maxPrice'] = maxPrice;
    if (minArea != null) params['minArea'] = minArea;
    if (maxArea != null) params['maxArea'] = maxArea;
    if (soPhongNgu != null) params['soPhongNgu'] = soPhongNgu;
    if (cityName != null && cityName!.isNotEmpty) params['cityName'] = cityName;
    if (districtName != null && districtName!.isNotEmpty) params['districtName'] = districtName;
    if (wardName != null && wardName!.isNotEmpty) params['wardName'] = wardName;
    if (status != null) params['status'] = status;
    if (transactionType != null) params['transactionType'] = transactionType;
    return params;
  }
}

/// Màn hình Bộ lọc nâng cao - Modern Design
class FilterScreen extends StatefulWidget {
  final FilterModel? initialFilters;

  const FilterScreen({
    super.key,
    this.initialFilters,
  });

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  late FilterModel _filters;
  final CategoryRepository _categoryRepository = CategoryRepository();
  
  List<CategoryModel> _categories = [];
  
  // Location data từ VietnamAddressService
  VietnamProvince? _selectedProvince;
  VietnamDistrict? _selectedDistrict;
  VietnamWard? _selectedWard;
  List<VietnamProvince> _provinces = [];
  List<VietnamDistrict> _districts = [];
  List<VietnamWard> _wards = [];
  
  // Range values for sliders
  SfRangeValues _priceRange = const SfRangeValues(0.0, 10000.0); // triệu VNĐ
  SfRangeValues _areaRange = const SfRangeValues(0.0, 500.0); // m²

  @override
  void initState() {
    super.initState();
    _filters = widget.initialFilters ?? FilterModel();
    _initializeControllers();
    _loadInitialData();
  }

  void _initializeControllers() {
    if (_filters.minPrice != null) _priceRange = SfRangeValues(_filters.minPrice!, _priceRange.end);
    if (_filters.maxPrice != null) _priceRange = SfRangeValues(_priceRange.start, _filters.maxPrice!);
    if (_filters.minArea != null) _areaRange = SfRangeValues(_filters.minArea!, _areaRange.end);
    if (_filters.maxArea != null) _areaRange = SfRangeValues(_areaRange.start, _filters.maxArea!);
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      final results = await Future.wait([
        _categoryRepository.getActiveCategories(),
        VietnamAddressService.fetchProvinces(),
      ]);
      
      if (mounted) {
        setState(() {
          _categories = results[0] as List<CategoryModel>;
          _provinces = results[1] as List<VietnamProvince>;
        });
      }
    } catch (e) {
      debugPrint('Error loading filter data: $e');
    }
  }

  Future<void> _loadDistricts(String provinceCode) async {
    try {
      final districts = await VietnamAddressService.fetchDistricts(provinceCode);
      if (mounted) {
        setState(() {
          _districts = districts;
          _selectedDistrict = null;
          _selectedWard = null;
          _wards = [];
        });
      }
    } catch (e) {
      debugPrint('Error loading districts: $e');
    }
  }

  Future<void> _loadWards(String districtCode) async {
    try {
      final wards = await VietnamAddressService.fetchWards(districtCode);
      if (mounted) {
        setState(() {
          _wards = wards;
          _selectedWard = null;
        });
      }
    } catch (e) {
      debugPrint('Error loading wards: $e');
    }
  }


  void _applyFilters() {
    // Update filters from sliders
    _filters.minPrice = _priceRange.start > 0 ? _priceRange.start : null;
    _filters.maxPrice = _priceRange.end < 10000 ? _priceRange.end : null;
    _filters.minArea = _areaRange.start > 0 ? _areaRange.start : null;
    _filters.maxArea = _areaRange.end < 500 ? _areaRange.end : null;
    
    // Update location filters từ VietnamAddressService - dùng name thay vì ID
    if (_selectedProvince != null) {
      _filters.cityName = _selectedProvince!.name;
    } else {
      _filters.cityName = null;
    }
    if (_selectedDistrict != null) {
      _filters.districtName = _selectedDistrict!.name;
    } else {
      _filters.districtName = null;
    }
    if (_selectedWard != null) {
      _filters.wardName = _selectedWard!.name;
    } else {
      _filters.wardName = null;
    }
  }

  void _resetFilters() {
    setState(() {
      _filters = FilterModel();
      _priceRange = const SfRangeValues(0.0, 10000.0);
      _areaRange = const SfRangeValues(0.0, 500.0);
      _selectedProvince = null;
      _selectedDistrict = null;
      _selectedWard = null;
      _districts = [];
      _wards = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Bộ lọc nâng cao', style: AppTextStyles.h6.copyWith(fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: _resetFilters,
            child: Text(
              'Đặt lại',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Loại hình
                _buildSection(
                  icon: FontAwesomeIcons.tag,
                  title: 'Loại hình',
                  child: _categories.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _categories.map((category) {
                            final isSelected = _filters.categoryId == category.id;
                            return _buildFilterChip(
                              label: category.name,
                              isSelected: isSelected,
                              onTap: () {
                                setState(() {
                                  _filters.categoryId = isSelected ? null : category.id;
                                });
                              },
                            );
                          }).toList(),
                        ),
                ),
                const Gap(28),
                
                // Địa điểm
                _buildSection(
                  icon: FontAwesomeIcons.locationDot,
                  title: 'Địa điểm',
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        // Tỉnh/Thành phố
                        _buildDropdown<VietnamProvince>(
                          label: 'Thành phố',
                          value: _selectedProvince,
                          items: _provinces,
                          displayText: (province) => province.name,
                          onChanged: (province) {
                            setState(() {
                              _selectedProvince = province;
                              _selectedDistrict = null;
                              _selectedWard = null;
                              _districts = [];
                              _wards = [];
                            });
                            if (province != null) {
                              _loadDistricts(province.code);
                            }
                          },
                        ),
                        if (_selectedProvince != null && _districts.isNotEmpty) ...[
                          const Gap(12),
                          // Quận/Huyện
                          _buildDropdown<VietnamDistrict>(
                            label: 'Quận/Huyện',
                            value: _selectedDistrict,
                            items: _districts,
                            displayText: (district) => district.name,
                            onChanged: (district) {
                              setState(() {
                                _selectedDistrict = district;
                                _selectedWard = null;
                                _wards = [];
                              });
                              if (district != null) {
                                _loadWards(district.code);
                              }
                            },
                          ),
                        ],
                        if (_selectedDistrict != null && _wards.isNotEmpty) ...[
                          const Gap(12),
                          // Phường/Xã
                          _buildDropdown<VietnamWard>(
                            label: 'Phường/Xã',
                            value: _selectedWard,
                            items: _wards,
                            displayText: (ward) => ward.name,
                            onChanged: (ward) => setState(() => _selectedWard = ward),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const Gap(28),
                
                // Khoảng giá
                _buildSection(
                  icon: FontAwesomeIcons.dollarSign,
                  title: 'Khoảng giá',
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        // Hiển thị giá trị đã chọn
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: _buildPriceDisplay(
                                label: 'Từ',
                                value: _priceRange.start,
                              ),
                            ),
                            const Gap(16),
                            Expanded(
                              child: _buildPriceDisplay(
                                label: 'Đến',
                                value: _priceRange.end,
                              ),
                            ),
                          ],
                        ),
                        const Gap(20),
                        _buildRangeSlider(
                          values: _priceRange,
                          min: 0.0,
                          max: 10000.0,
                          onChanged: (SfRangeValues newValues) {
                            setState(() {
                              _priceRange = newValues;
                            });
                          },
                          formatValue: (double value) {
                            if (value >= 1000) {
                              return '${(value / 1000).toStringAsFixed(1)} tỷ';
                            }
                            return '${value.toStringAsFixed(0)} triệu';
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const Gap(28),
                
                // Diện tích
                _buildSection(
                  icon: FontAwesomeIcons.ruler,
                  title: 'Diện tích',
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        // Hiển thị giá trị đã chọn
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: _buildAreaDisplay(
                                label: 'Từ',
                                value: _areaRange.start,
                              ),
                            ),
                            const Gap(16),
                            Expanded(
                              child: _buildAreaDisplay(
                                label: 'Đến',
                                value: _areaRange.end,
                              ),
                            ),
                          ],
                        ),
                        const Gap(20),
                        _buildRangeSlider(
                          values: _areaRange,
                          min: 0.0,
                          max: 500.0,
                          onChanged: (SfRangeValues newValues) {
                            setState(() {
                              _areaRange = newValues;
                            });
                          },
                          formatValue: (double value) {
                            return '${value.toStringAsFixed(0)} m²';
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const Gap(28),
                
                // Số phòng ngủ
                _buildSection(
                  icon: FontAwesomeIcons.bed,
                  title: 'Số phòng ngủ',
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: List.generate(5, (index) {
                      final count = index + 1;
                      final isSelected = _filters.soPhongNgu == count;
                      return _buildFilterChip(
                        label: '$count+',
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            _filters.soPhongNgu = isSelected ? null : count;
                          });
                        },
                      );
                    }),
                  ),
                ),
                const Gap(28),
                
                // Số phòng tắm
                _buildSection(
                  icon: FontAwesomeIcons.bath,
                  title: 'Số phòng tắm',
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: List.generate(4, (index) {
                      final count = index + 1;
                      final isSelected = _filters.soPhongTam == count;
                      return _buildFilterChip(
                        label: '$count+',
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            _filters.soPhongTam = isSelected ? null : count;
                          });
                        },
                      );
                    }),
                  ),
                ),
                const Gap(40),
              ],
            ),
          ),
          // Bottom buttons - Simplified design
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(20),
              color: AppColors.surface,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _resetFilters,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: AppColors.border, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Đặt lại',
                        style: AppTextStyles.labelLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        _applyFilters();
                        final filters = _filters.toQueryParams();
                        // Luôn trả về filters (kể cả khi rỗng) để đảm bảo chuyển đến SearchScreen
                        Navigator.pop(context, filters);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Áp dụng bộ lọc',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.textOnPrimary,
                          fontWeight: FontWeight.w600,
                        ),
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

  Widget _buildSection({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            FaIcon(icon, size: 20, color: AppColors.primary),
            const Gap(12),
            Text(
              title,
              style: AppTextStyles.h6.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const Gap(16),
        child,
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildRangeSlider({
    required SfRangeValues values,
    required double min,
    required double max,
    required Function(SfRangeValues) onChanged,
    required String Function(double) formatValue,
  }) {
    return SfRangeSlider(
      min: min,
      max: max,
      values: values,
      onChanged: onChanged,
      activeColor: AppColors.error, // Màu đỏ cho track
      inactiveColor: AppColors.border,
      tooltipShape: const SfPaddleTooltipShape(), // Bubble shape
      tooltipTextFormatterCallback: (dynamic actualValue, String formattedText) {
        return formatValue(actualValue as double);
      },
      enableTooltip: true,
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T) displayText,
    required void Function(T?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonFormField<T>(
            initialValue: value != null && items.contains(value) ? value : null,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 16),
            ),
            items: [
              DropdownMenuItem<T>(
                value: null,
                child: Text('Tất cả', style: AppTextStyles.bodyMedium),
              ),
              ...items.map((item) => DropdownMenuItem<T>(
                value: item,
                child: Text(displayText(item), style: AppTextStyles.bodyMedium),
              )),
            ],
            onChanged: onChanged,
            style: AppTextStyles.bodyMedium,
            isExpanded: true,
            icon: const Padding(
              padding: EdgeInsets.only(right: 8),
              child: FaIcon(
                FontAwesomeIcons.chevronDown,
                size: 14,
                color: AppColors.textHint,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Widget hiển thị giá trị giá đã chọn
  Widget _buildPriceDisplay({
    required String label,
    required double value,
  }) {
    String displayText;
    if (value >= 1000) {
      displayText = '${(value / 1000).toStringAsFixed(1)} tỷ';
    } else if (value == 0) {
      displayText = '0 triệu';
    } else {
      displayText = '${value.toStringAsFixed(0)} triệu';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            displayText,
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  /// Widget hiển thị giá trị diện tích đã chọn
  Widget _buildAreaDisplay({
    required String label,
    required double value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${value.toStringAsFixed(0)} m²',
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
