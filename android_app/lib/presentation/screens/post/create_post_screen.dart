import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../core/models/post_model.dart';
import '../../../core/models/category_model.dart';
import '../../../core/models/area_model.dart';
import '../../../core/repositories/post_repository.dart';
import '../../../core/repositories/category_repository.dart';
import '../../../core/repositories/area_repository.dart';
import '../../../core/services/image_picker_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_shadows.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/loading_indicator.dart';
import 'google_places_search_screen.dart';
import '../../../core/services/google_places_service.dart';
import '../../../config/app_config.dart';

/// Màn hình đăng tin bất động sản - Modern UI với Multi-step Form
class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final PageController _pageController = PageController();
  final PostRepository _postRepository = PostRepository();
  final CategoryRepository _categoryRepository = CategoryRepository();
  final AreaRepository _areaRepository = AreaRepository();
  
  int _currentStep = 0;
  final int _totalSteps = 5;
  bool _isLoading = false;
  bool _isSubmitting = false;

  // Form Controllers
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _areaController = TextEditingController();
  final _streetController = TextEditingController();
  final _soPhongNguController = TextEditingController();
  final _soPhongTamController = TextEditingController();
  final _soTangController = TextEditingController();
  final _matTienController = TextEditingController();
  final _duongVaoController = TextEditingController();
  final _phapLyController = TextEditingController();

  // Form Data
  TransactionType _transactionType = TransactionType.sale;
  PriceUnit _priceUnit = PriceUnit.total;
  String _status = 'available';
  CategoryModel? _selectedCategory;
  CityModel? _selectedCity;
  DistrictModel? _selectedDistrict;
  WardModel? _selectedWard;
  String? _huongNha;
  String? _huongBanCong;
  List<File> _selectedImages = [];

  // Data Lists
  List<CategoryModel> _categories = [];
  List<CityModel> _cities = [];
  List<DistrictModel> _districts = [];
  List<DistrictModel> _filteredDistricts = [];
  List<WardModel> _wards = [];
  List<WardModel> _filteredWards = [];

  // Hướng nhà options
  final List<String> _huongNhaOptions = [
    'Đông', 'Tây', 'Nam', 'Bắc', 'Đông Nam', 'Đông Bắc', 'Tây Nam', 'Tây Bắc'
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _areaController.dispose();
    _streetController.dispose();
    _soPhongNguController.dispose();
    _soPhongTamController.dispose();
    _soTangController.dispose();
    _matTienController.dispose();
    _duongVaoController.dispose();
    _phapLyController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _categoryRepository.getActiveCategories(),
        _areaRepository.getCities(),
      ]);
      
      if (mounted) {
        setState(() {
          _categories = results[0] as List<CategoryModel>;
          _cities = results[1] as List<CityModel>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
        );
      }
    }
  }

  Future<void> _loadDistricts(int cityId) async {
    try {
      final districts = await _areaRepository.getDistrictsByCity(cityId);
      if (mounted) {
        setState(() {
          _filteredDistricts = districts;
          _selectedDistrict = null;
          _selectedWard = null;
          _filteredWards = [];
        });
      }
    } catch (e) {
      debugPrint('Error loading districts: $e');
    }
  }

  Future<void> _loadWards(int districtId) async {
    try {
      final wards = await _areaRepository.getWardsByDistrict(districtId);
      if (mounted) {
        setState(() {
          _filteredWards = wards;
          _selectedWard = null;
        });
      }
    } catch (e) {
      debugPrint('Error loading wards: $e');
    }
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      if (_validateCurrentStep()) {
        setState(() => _currentStep++);
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0: // Thông tin cơ bản
        if (_titleController.text.trim().isEmpty) {
          _showError('Vui lòng nhập tiêu đề');
          return false;
        }
        if (_descriptionController.text.trim().isEmpty) {
          _showError('Vui lòng nhập mô tả');
          return false;
        }
        if (_selectedCategory == null) {
          _showError('Vui lòng chọn loại hình');
          return false;
        }
        return true;
      case 1: // Địa điểm
        if (_selectedCity == null) {
          _showError('Vui lòng chọn thành phố');
          return false;
        }
        if (_selectedDistrict == null) {
          _showError('Vui lòng chọn quận/huyện');
          return false;
        }
        if (_selectedWard == null) {
          _showError('Vui lòng chọn phường/xã');
          return false;
        }
        if (_streetController.text.trim().isEmpty) {
          _showError('Vui lòng nhập tên đường');
          return false;
        }
        return true;
      case 2: // Giá và diện tích
        if (_priceController.text.trim().isEmpty) {
          _showError('Vui lòng nhập giá');
          return false;
        }
        if (double.tryParse(_priceController.text) == null || 
            double.parse(_priceController.text) <= 0) {
          _showError('Giá không hợp lệ');
          return false;
        }
        if (_areaController.text.trim().isEmpty) {
          _showError('Vui lòng nhập diện tích');
          return false;
        }
        if (double.tryParse(_areaController.text) == null || 
            double.parse(_areaController.text) <= 0) {
          _showError('Diện tích không hợp lệ');
          return false;
        }
        return true;
      case 3: // Thông tin chi tiết
        return true; // Optional fields
      case 4: // Hình ảnh
        if (_selectedImages.isEmpty) {
          _showError('Vui lòng chọn ít nhất 1 hình ảnh');
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  Future<void> _pickImages() async {
    final images = await ImagePickerService.pickMultipleImagesFromGallery(context);
    if (images.isNotEmpty && mounted) {
      setState(() {
        _selectedImages.addAll(images);
        if (_selectedImages.length > 10) {
          _selectedImages = _selectedImages.take(10).toList();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Chỉ được tối đa 10 ảnh')),
          );
        }
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  /// Mở màn hình tìm kiếm Google Places
  Future<void> _openGooglePlacesSearch() async {
    final result = await Navigator.push<PlaceDetails>(
      context,
      MaterialPageRoute(
        builder: (context) => GooglePlacesSearchScreen(
          initialQuery: _streetController.text,
        ),
      ),
    );

    if (result != null && mounted) {
      await _handleGooglePlaceSelected(result);
    }
  }

  /// Xử lý khi chọn địa điểm từ Google Places
  Future<void> _handleGooglePlaceSelected(PlaceDetails placeDetails) async {
    try {
      // Parse địa chỉ từ Google Places
      final parsedAddress = placeDetails.parseAddress();
      
      // Cập nhật tên đường
      _streetController.text = parsedAddress['streetName'] ?? placeDetails.formattedAddress;

      // Tìm City/District/Ward tương ứng trong database
      await _matchAddressToDatabase(parsedAddress);

      // Hiển thị thông báo thành công
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã chọn địa điểm: ${placeDetails.name}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi xử lý địa điểm: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Tìm City/District/Ward trong database dựa trên địa chỉ từ Google Places
  Future<void> _matchAddressToDatabase(Map<String, String?> parsedAddress) async {
    final cityName = parsedAddress['cityName'];
    final districtName = parsedAddress['districtName'];
    final wardName = parsedAddress['wardName'];

    if (cityName != null) {
      // Tìm City
      final matchingCity = _cities.firstWhere(
        (city) => city.name.toLowerCase().contains(cityName.toLowerCase()) ||
                  cityName.toLowerCase().contains(city.name.toLowerCase()),
        orElse: () => _cities.first,
      );

      if (matchingCity != null) {
        setState(() => _selectedCity = matchingCity);
        await _loadDistricts(matchingCity.id);

        if (districtName != null && _filteredDistricts.isNotEmpty) {
          // Tìm District
          final matchingDistrict = _filteredDistricts.firstWhere(
            (district) => district.name.toLowerCase().contains(districtName.toLowerCase()) ||
                          districtName.toLowerCase().contains(district.name.toLowerCase()),
            orElse: () => _filteredDistricts.first,
          );

          if (matchingDistrict != null) {
            setState(() => _selectedDistrict = matchingDistrict);
            await _loadWards(matchingDistrict.id);

            if (wardName != null && _filteredWards.isNotEmpty) {
              // Tìm Ward
              final matchingWard = _filteredWards.firstWhere(
                (ward) => ward.name.toLowerCase().contains(wardName.toLowerCase()) ||
                          wardName.toLowerCase().contains(ward.name.toLowerCase()),
                orElse: () => _filteredWards.first,
              );

              if (matchingWard != null) {
                setState(() => _selectedWard = matchingWard);
              }
            }
          }
        }
      }
    }
  }

  Future<void> _submitPost() async {
    if (!_validateCurrentStep()) return;

    setState(() => _isSubmitting = true);

    try {
      // Tạo FormData
      final formData = FormData();

      // Basic info
      formData.fields.addAll([
        MapEntry('Title', _titleController.text.trim()),
        MapEntry('Description', _descriptionController.text.trim()),
        MapEntry('Price', _priceController.text),
        MapEntry('PriceUnit', _priceUnit.index.toString()),
        MapEntry('TransactionType', _transactionType.name),
        MapEntry('Status', _status),
        MapEntry('Street_Name', _streetController.text.trim()),
        MapEntry('Area_Size', _areaController.text),
        MapEntry('CategoryId', _selectedCategory!.id.toString()),
        MapEntry('AreaId', _selectedWard!.id.toString()), // Using ward ID as AreaId
      ]);

      // Optional fields
      if (_soPhongNguController.text.isNotEmpty) {
        formData.fields.add(MapEntry('SoPhongNgu', _soPhongNguController.text));
      }
      if (_soPhongTamController.text.isNotEmpty) {
        formData.fields.add(MapEntry('SoPhongTam', _soPhongTamController.text));
      }
      if (_soTangController.text.isNotEmpty) {
        formData.fields.add(MapEntry('SoTang', _soTangController.text));
      }
      if (_matTienController.text.isNotEmpty) {
        formData.fields.add(MapEntry('MatTien', _matTienController.text));
      }
      if (_duongVaoController.text.isNotEmpty) {
        formData.fields.add(MapEntry('DuongVao', _duongVaoController.text));
      }
      if (_phapLyController.text.isNotEmpty) {
        formData.fields.add(MapEntry('PhapLy', _phapLyController.text));
      }
      if (_huongNha != null) {
        formData.fields.add(MapEntry('HuongNha', _huongNha!));
      }
      if (_huongBanCong != null) {
        formData.fields.add(MapEntry('HuongBanCong', _huongBanCong!));
      }

      // Add images
      for (var image in _selectedImages) {
        formData.files.add(MapEntry(
          'Images',
          await MultipartFile.fromFile(image.path, filename: image.path.split('/').last),
        ));
      }

      // Submit
      await _postRepository.createPost(formData);

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đăng tin thành công! Tin của bạn đang chờ duyệt.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showError('Lỗi đăng tin: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Đăng tin', style: AppTextStyles.h6),
        actions: [
          if (_currentStep == _totalSteps - 1)
            TextButton(
              onPressed: _isSubmitting ? null : _submitPost,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text('Đăng', style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : Column(
              children: [
                _buildProgressIndicator(),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildStep1BasicInfo(),
                      _buildStep2Location(),
                      _buildStep3PriceArea(),
                      _buildStep4Details(),
                      _buildStep5Images(),
                    ],
                  ),
                ),
                _buildNavigationButtons(),
              ],
            ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: AppColors.surface,
      child: Column(
        children: [
          Row(
            children: List.generate(_totalSteps, (index) {
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: index < _totalSteps - 1 ? 8 : 0),
                  decoration: BoxDecoration(
                    color: index <= _currentStep
                        ? AppColors.primary
                        : AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const Gap(12),
          Text(
            'Bước ${_currentStep + 1}/$_totalSteps',
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: AppShadows.top,
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: AppButton(
                text: 'Quay lại',
                onPressed: _previousStep,
                isOutlined: true,
              ),
            ),
          if (_currentStep > 0) const Gap(12),
          Expanded(
            flex: _currentStep == 0 ? 1 : 2,
            child: AppButton(
              text: _currentStep == _totalSteps - 1 ? 'Hoàn tất' : 'Tiếp theo',
              onPressed: _currentStep == _totalSteps - 1 ? _submitPost : _nextStep,
              isLoading: _currentStep == _totalSteps - 1 && _isSubmitting,
            ),
          ),
        ],
      ),
    );
  }

  // Step 1: Thông tin cơ bản
  Widget _buildStep1BasicInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Thông tin cơ bản', style: AppTextStyles.h5),
            const Gap(8),
            Text('Nhập tiêu đề và mô tả cho tin đăng của bạn', style: AppTextStyles.bodySmall),
            const Gap(24),
            
            // Tiêu đề
            _buildTextField(
              controller: _titleController,
              label: 'Tiêu đề *',
              hint: 'VD: Căn hộ 2PN đẹp, view đẹp tại Quận 1',
              maxLines: 2,
            ),
            const Gap(20),
            
            // Mô tả
            _buildTextField(
              controller: _descriptionController,
              label: 'Mô tả chi tiết *',
              hint: 'Mô tả đầy đủ về bất động sản...',
              maxLines: 6,
            ),
            const Gap(20),
            
            // Loại giao dịch
            Text('Loại giao dịch *', style: AppTextStyles.labelLarge),
            const Gap(12),
            Row(
              children: [
                Expanded(
                  child: _buildChoiceChip(
                    label: 'Bán',
                    icon: Iconsax.shop,
                    isSelected: _transactionType == TransactionType.sale,
                    onSelected: () => setState(() => _transactionType = TransactionType.sale),
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: _buildChoiceChip(
                    label: 'Cho thuê',
                    icon: Iconsax.calendar,
                    isSelected: _transactionType == TransactionType.rent,
                    onSelected: () => setState(() => _transactionType = TransactionType.rent),
                  ),
                ),
              ],
            ),
            const Gap(24),
            
            // Loại hình
            Text('Loại hình bất động sản *', style: AppTextStyles.labelLarge),
            const Gap(12),
            if (_categories.isEmpty)
              const Center(child: CircularProgressIndicator())
            else
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _categories.map((category) {
                  final isSelected = _selectedCategory?.id == category.id;
                  return _buildCategoryChip(
                    category: category,
                    isSelected: isSelected,
                    onSelected: () => setState(() => _selectedCategory = category),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  // Step 2: Địa điểm
  Widget _buildStep2Location() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Địa điểm', style: AppTextStyles.h5),
          const Gap(8),
          Text('Chọn địa điểm của bất động sản', style: AppTextStyles.bodySmall),
          const Gap(24),
          
          // Thành phố
          _buildDropdown<CityModel>(
            label: 'Thành phố *',
            value: _selectedCity,
            items: _cities,
            displayText: (city) => city.name,
            onChanged: (city) {
              setState(() => _selectedCity = city);
              if (city != null) {
                _loadDistricts(city.id);
              }
            },
          ),
          const Gap(20),
          
          // Quận/Huyện
          _buildDropdown<DistrictModel>(
            label: 'Quận/Huyện *',
            value: _selectedDistrict,
            items: _filteredDistricts,
            displayText: (district) => district.name,
            onChanged: (district) {
              setState(() => _selectedDistrict = district);
              if (district != null) {
                _loadWards(district.id);
              }
            },
            enabled: _selectedCity != null,
          ),
          const Gap(20),
          
          // Phường/Xã
          _buildDropdown<WardModel>(
            label: 'Phường/Xã *',
            value: _selectedWard,
            items: _filteredWards,
            displayText: (ward) => ward.name,
            onChanged: (ward) => setState(() => _selectedWard = ward),
            enabled: _selectedDistrict != null,
          ),
          const Gap(20),
          
          // Tìm kiếm bằng Google Maps
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            child: AppButton(
              text: 'Tìm kiếm trên bản đồ',
              onPressed: _openGooglePlacesSearch,
              isOutlined: true,
              icon: Iconsax.map_1,
            ),
          ),
          
          // Tên đường
          _buildTextField(
            controller: _streetController,
            label: 'Tên đường/Số nhà *',
            hint: 'VD: 123 Nguyễn Huệ',
            suffixIcon: IconButton(
              icon: const Icon(Iconsax.search_normal_1),
              onPressed: _openGooglePlacesSearch,
              tooltip: 'Tìm kiếm địa điểm',
            ),
          ),
        ],
      ),
    );
  }

  // Step 3: Giá và diện tích
  Widget _buildStep3PriceArea() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Giá và diện tích', style: AppTextStyles.h5),
          const Gap(8),
          Text('Nhập thông tin giá và diện tích', style: AppTextStyles.bodySmall),
          const Gap(24),
          
          // Giá
          _buildTextField(
            controller: _priceController,
            label: 'Giá *',
            hint: 'VD: 5000000000',
            keyboardType: TextInputType.number,
            suffixText: _priceUnit == PriceUnit.total 
                ? 'VNĐ' 
                : _priceUnit == PriceUnit.perM2 
                    ? 'VNĐ/m²' 
                    : 'VNĐ/tháng',
          ),
          const Gap(12),
          
          // Đơn vị giá
          Text('Đơn vị giá', style: AppTextStyles.labelLarge),
          const Gap(12),
          Row(
            children: [
              Expanded(
                child: _buildChoiceChip(
                  label: 'Tổng giá',
                  isSelected: _priceUnit == PriceUnit.total,
                  onSelected: () => setState(() => _priceUnit = PriceUnit.total),
                ),
              ),
              const Gap(12),
              Expanded(
                child: _buildChoiceChip(
                  label: 'Giá/m²',
                  isSelected: _priceUnit == PriceUnit.perM2,
                  onSelected: () => setState(() => _priceUnit = PriceUnit.perM2),
                ),
              ),
              const Gap(12),
              Expanded(
                child: _buildChoiceChip(
                  label: 'Giá/tháng',
                  isSelected: _priceUnit == PriceUnit.perMonth,
                  onSelected: () => setState(() => _priceUnit = PriceUnit.perMonth),
                ),
              ),
            ],
          ),
          const Gap(24),
          
          // Diện tích
          _buildTextField(
            controller: _areaController,
            label: 'Diện tích (m²) *',
            hint: 'VD: 100',
            keyboardType: TextInputType.number,
            suffixText: 'm²',
          ),
        ],
      ),
    );
  }

  // Step 4: Thông tin chi tiết
  Widget _buildStep4Details() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Thông tin chi tiết', style: AppTextStyles.h5),
          const Gap(8),
          Text('Các thông tin bổ sung (tùy chọn)', style: AppTextStyles.bodySmall),
          const Gap(24),
          
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _soPhongNguController,
                  label: 'Số phòng ngủ',
                  hint: 'VD: 3',
                  keyboardType: TextInputType.number,
                ),
              ),
              const Gap(12),
              Expanded(
                child: _buildTextField(
                  controller: _soPhongTamController,
                  label: 'Số phòng tắm',
                  hint: 'VD: 2',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const Gap(20),
          
          _buildTextField(
            controller: _soTangController,
            label: 'Số tầng',
            hint: 'VD: 5',
            keyboardType: TextInputType.number,
          ),
          const Gap(20),
          
          // Hướng nhà
          _buildDropdown<String>(
            label: 'Hướng nhà',
            value: _huongNha,
            items: _huongNhaOptions,
            displayText: (value) => value,
            onChanged: (value) => setState(() => _huongNha = value),
            allowNull: true,
          ),
          const Gap(20),
          
          // Hướng ban công
          _buildDropdown<String>(
            label: 'Hướng ban công',
            value: _huongBanCong,
            items: _huongNhaOptions,
            displayText: (value) => value,
            onChanged: (value) => setState(() => _huongBanCong = value),
            allowNull: true,
          ),
          const Gap(20),
          
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _matTienController,
                  label: 'Mặt tiền (m)',
                  hint: 'VD: 5',
                  keyboardType: TextInputType.number,
                ),
              ),
              const Gap(12),
              Expanded(
                child: _buildTextField(
                  controller: _duongVaoController,
                  label: 'Đường vào (m)',
                  hint: 'VD: 4',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const Gap(20),
          
          _buildTextField(
            controller: _phapLyController,
            label: 'Pháp lý',
            hint: 'VD: Sổ đỏ/Sổ hồng',
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  // Step 5: Hình ảnh
  Widget _buildStep5Images() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hình ảnh', style: AppTextStyles.h5),
          const Gap(8),
          Text('Thêm hình ảnh cho tin đăng (tối thiểu 1 ảnh, tối đa 10 ảnh)', 
            style: AppTextStyles.bodySmall),
          const Gap(24),
          
          // Image Grid
          if (_selectedImages.isEmpty)
            _buildEmptyImagePlaceholder()
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: _selectedImages.length + (_selectedImages.length < 10 ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < _selectedImages.length) {
                  return _buildImageItem(_selectedImages[index], index);
                } else {
                  return _buildAddImageButton();
                }
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyImagePlaceholder() {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.image, size: 48, color: AppColors.textHint),
            const Gap(12),
            Text('Thêm hình ảnh', style: AppTextStyles.labelLarge),
            const Gap(4),
            Text('Chạm để chọn ảnh', style: AppTextStyles.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildImageItem(File image, int index) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            image,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removeImage(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddImageButton() {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.add, size: 32, color: AppColors.textSecondary),
            const Gap(8),
            Text('Thêm', style: AppTextStyles.labelSmall),
          ],
        ),
      ),
    );
  }

  // Helper Widgets
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? suffixText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelLarge),
        const Gap(8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: AppTextStyles.bodyMedium,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
            suffixText: suffixText,
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildChoiceChip({
    required String label,
    IconData? icon,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return GestureDetector(
      onTap: onSelected,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: isSelected ? Colors.white : AppColors.textSecondary),
              const Gap(8),
            ],
            Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip({
    required CategoryModel category,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return GestureDetector(
      onTap: onSelected,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          category.name,
          style: AppTextStyles.labelMedium.copyWith(
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T) displayText,
    required void Function(T?) onChanged,
    bool enabled = true,
    bool allowNull = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelLarge),
        const Gap(8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: enabled ? AppColors.surface : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonFormField<T>(
            value: value,
            items: [
              if (allowNull)
                DropdownMenuItem<T>(
                  value: null,
                  child: Text('Không chọn', style: AppTextStyles.bodyMedium),
                ),
              ...items.map((item) => DropdownMenuItem<T>(
                value: item,
                child: Text(displayText(item), style: AppTextStyles.bodyMedium),
              )),
            ],
            onChanged: enabled ? onChanged : null,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 16),
            ),
            style: AppTextStyles.bodyMedium,
            isExpanded: true,
          ),
        ),
      ],
    );
  }
}
