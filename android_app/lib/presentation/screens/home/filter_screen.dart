import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../widgets/common/app_button.dart';
import '../../../core/models/category_model.dart';
import '../../../core/models/location_model.dart';
import '../../../core/repositories/category_repository.dart';
import '../../../core/repositories/location_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_shadows.dart';
import '../home/search_results_screen.dart';

/// Model cho Filter
class FilterModel {
  int? categoryId;
  double? minPrice;
  double? maxPrice;
  double? minArea;
  double? maxArea;
  int? soPhongNgu;
  int? soPhongTam;
  int? cityId;
  int? districtId;
  int? wardId;
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
    this.cityId,
    this.districtId,
    this.wardId,
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
    if (cityId != null) params['cityId'] = cityId;
    if (districtId != null) params['districtId'] = districtId;
    if (wardId != null) params['wardId'] = wardId;
    if (status != null) params['status'] = status;
    if (transactionType != null) params['transactionType'] = transactionType;
    return params;
  }
}

/// Màn hình Bộ lọc nâng cao
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
  final LocationRepository _locationRepository = LocationRepository();
  
  List<CategoryModel> _categories = [];
  List<CityModel> _cities = [];
  List<DistrictModel> _districts = [];
  List<WardModel> _wards = [];
  
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();
  final _minAreaController = TextEditingController();
  final _maxAreaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filters = widget.initialFilters ?? FilterModel();
    _initializeControllers();
    _loadInitialData();
  }

  void _initializeControllers() {
    if (_filters.minPrice != null) _minPriceController.text = _filters.minPrice!.toString();
    if (_filters.maxPrice != null) _maxPriceController.text = _filters.maxPrice!.toString();
    if (_filters.minArea != null) _minAreaController.text = _filters.minArea!.toString();
    if (_filters.maxArea != null) _maxAreaController.text = _filters.maxArea!.toString();
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _minAreaController.dispose();
    _maxAreaController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      final results = await Future.wait([
        _categoryRepository.getActiveCategories(),
        _locationRepository.getCities(),
      ]);
      
      if (mounted) {
        setState(() {
          _categories = results[0] as List<CategoryModel>;
          _cities = results[1] as List<CityModel>;
        });
        
        // Load districts và wards nếu đã chọn
        if (_filters.cityId != null) {
          await _loadDistricts(_filters.cityId!);
        }
        if (_filters.districtId != null) {
          await _loadWards(_filters.districtId!);
        }
      }
    } catch (e) {
      debugPrint('Error loading filter data: $e');
    }
  }

  Future<void> _loadDistricts(int cityId) async {
    try {
      final districts = await _locationRepository.getDistrictsByCity(cityId);
      if (mounted) {
        setState(() {
          _districts = districts;
          if (_filters.districtId != null && 
              !districts.any((d) => d.id == _filters.districtId)) {
            _filters.districtId = null;
            _filters.wardId = null;
            _wards = [];
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading districts: $e');
    }
  }

  Future<void> _loadWards(int districtId) async {
    try {
      final wards = await _locationRepository.getWardsByDistrict(districtId);
      if (mounted) {
        setState(() {
          _wards = wards;
          if (_filters.wardId != null && 
              !wards.any((w) => w.id == _filters.wardId)) {
            _filters.wardId = null;
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading wards: $e');
    }
  }

  void _applyFilters() {
    // Update filters from text fields
    _filters.minPrice = double.tryParse(_minPriceController.text);
    _filters.maxPrice = double.tryParse(_maxPriceController.text);
    _filters.minArea = double.tryParse(_minAreaController.text);
    _filters.maxArea = double.tryParse(_maxAreaController.text);
  }

  void _resetFilters() {
    setState(() {
      _filters = FilterModel();
      _minPriceController.clear();
      _maxPriceController.clear();
      _minAreaController.clear();
      _maxAreaController.clear();
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
        title: Text('Bộ lọc nâng cao', style: AppTextStyles.h6),
        actions: [
          TextButton(
            onPressed: _resetFilters,
            child: Text('Đặt lại', style: AppTextStyles.labelMedium.copyWith(color: AppColors.error)),
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
                  icon: Iconsax.category,
                  title: 'Loại hình',
                  child: _categories.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : Wrap(
                          spacing: 12,
                          runSpacing: 12,
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
                const Gap(24),
                
                // Địa điểm
                _buildSection(
                  icon: Iconsax.location,
                  title: 'Địa điểm',
                  child: Column(
                    children: [
                      // Thành phố
                      _buildDropdown<CityModel>(
                        label: 'Thành phố',
                        value: _cities.firstWhere((c) => c.id == _filters.cityId, orElse: () => _cities.isNotEmpty ? _cities.first : CityModel(id: 0, name: 'Chọn thành phố')),
                        items: _cities,
                        onChanged: (city) {
                          setState(() {
                            _filters.cityId = city?.id;
                            _filters.districtId = null;
                            _filters.wardId = null;
                            _districts = [];
                            _wards = [];
                          });
                          if (city != null) _loadDistricts(city.id);
                        },
                      ),
                      const Gap(12),
                      // Quận/Huyện
                      if (_filters.cityId != null && _districts.isNotEmpty)
                        _buildDropdown<DistrictModel>(
                          label: 'Quận/Huyện',
                          value: _districts.firstWhere((d) => d.id == _filters.districtId, orElse: () => DistrictModel(id: 0, name: 'Chọn quận/huyện', cityId: _filters.cityId!)),
                          items: _districts,
                          onChanged: (district) {
                            setState(() {
                              _filters.districtId = district?.id;
                              _filters.wardId = null;
                              _wards = [];
                            });
                            if (district != null) _loadWards(district.id);
                          },
                        ),
                      if (_filters.districtId != null && _wards.isNotEmpty) ...[
                        const Gap(12),
                        // Phường/Xã
                        _buildDropdown<WardModel>(
                          label: 'Phường/Xã',
                          value: _wards.firstWhere((w) => w.id == _filters.wardId, orElse: () => WardModel(id: 0, name: 'Chọn phường/xã', districtId: _filters.districtId!)),
                          items: _wards,
                          onChanged: (ward) {
                            setState(() {
                              _filters.wardId = ward?.id;
                            });
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                const Gap(24),
                
                // Khoảng giá
                _buildSection(
                  icon: Iconsax.dollar_circle,
                  title: 'Khoảng giá (triệu VNĐ)',
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _minPriceController,
                          label: 'Từ',
                          hint: '0',
                          icon: Iconsax.arrow_down,
                        ),
                      ),
                      const Gap(12),
                      Expanded(
                        child: _buildTextField(
                          controller: _maxPriceController,
                          label: 'Đến',
                          hint: 'Không giới hạn',
                          icon: Iconsax.arrow_up,
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(24),
                
                // Diện tích
                _buildSection(
                  icon: Iconsax.ruler,
                  title: 'Diện tích (m²)',
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _minAreaController,
                          label: 'Từ',
                          hint: '0',
                        ),
                      ),
                      const Gap(12),
                      Expanded(
                        child: _buildTextField(
                          controller: _maxAreaController,
                          label: 'Đến',
                          hint: 'Không giới hạn',
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(24),
                
                // Số phòng ngủ
                _buildSection(
                  icon: Iconsax.home,
                  title: 'Số phòng ngủ',
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
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
                const Gap(24),
                
                // Số phòng tắm
                _buildSection(
                  icon: Iconsax.brush,
                  title: 'Số phòng tắm',
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
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
                const Gap(32),
              ],
            ),
          ),
          // Bottom buttons
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: AppShadows.top,
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _resetFilters,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: AppColors.border),
                    ),
                    child: Text('Đặt lại', style: AppTextStyles.labelLarge),
                  ),
                ),
                const Gap(12),
                Expanded(
                  flex: 2,
                  child: AppButton(
                    text: 'Áp dụng bộ lọc',
                    onPressed: () {
                      _applyFilters();
                      final filters = _filters.toQueryParams();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SearchResultsScreen(
                            query: 'Kết quả tìm kiếm',
                            filters: filters,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
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
            Icon(icon, size: 20, color: AppColors.primary),
            const Gap(8),
            Text(title, style: AppTextStyles.h6),
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? icon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: AppTextStyles.bodyMedium,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon, size: 18) : null,
        filled: true,
        fillColor: AppColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: items.contains(value) ? value : null,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      items: [
        DropdownMenuItem<T>(value: null, child: Text('Tất cả', style: AppTextStyles.bodyMedium)),
        ...items.map((item) {
          final name = item is CityModel ? item.name : 
                      item is DistrictModel ? item.name :
                      item is WardModel ? item.name : '';
          return DropdownMenuItem<T>(
            value: item,
            child: Text(name, style: AppTextStyles.bodyMedium),
          );
        }),
      ],
      onChanged: onChanged,
    );
  }
}

