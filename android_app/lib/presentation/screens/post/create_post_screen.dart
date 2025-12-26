import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/models/post_model.dart';
import '../../../core/models/category_model.dart';
import '../../../core/models/vietnam_address_model.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/services/post_service.dart';
import '../../../core/services/user_service.dart';
import '../../../core/services/vietnam_address_service.dart';
import '../../../core/services/nominatim_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_shadows.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/choose_photo.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Màn hình đăng tin bất động sản - Modern UI với Multi-step Form
class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final PageController _pageController = PageController();
  final PostService _postService = PostService();
  final UserService _userService = UserService();

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
  // PriceUnit đã được bỏ - format tự động dựa trên giá trị Price
  // Status không được gửi lên - backend sẽ tự động set "Pending" khi tạo mới
  CategoryModel? _selectedCategory;
  VietnamProvince? _selectedProvince;
  VietnamDistrict? _selectedDistrict;
  VietnamWard? _selectedWard;
  String? _huongNha;
  String? _huongBanCong;
  File? _mainImage; // Ảnh chính (chỉ 1 ảnh)
  List<File> _selectedImages = []; // Ảnh phụ (nhiều ảnh)
  // Tọa độ từ map selection
  double? _selectedLatitude;
  double? _selectedLongitude;

  // Data Lists
  List<CategoryModel> _categories = [];
  List<VietnamProvince> _provinces = [];
  List<VietnamDistrict> _districts = [];
  List<VietnamWard> _wards = [];

  // Hướng nhà options
  final List<String> _huongNhaOptions = [
    'Đông',
    'Tây',
    'Nam',
    'Bắc',
    'Đông Nam',
    'Đông Bắc',
    'Tây Nam',
    'Tây Bắc',
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
        _postService.getActiveCategories(),
        VietnamAddressService.fetchProvinces(),
      ]);

      if (mounted) {
        setState(() {
          _categories = results[0] as List<CategoryModel>;
          _provinces = results[1] as List<VietnamProvince>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi tải dữ liệu: $e')));
      }
    }
  }

  Future<void> _loadDistricts(String provinceCode) async {
    try {
      final districts = await VietnamAddressService.fetchDistricts(
        provinceCode,
      );
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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi tải quận/huyện: $e')));
      }
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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi tải phường/xã: $e')));
      }
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
        if (_selectedProvince == null) {
          _showError('Vui lòng chọn tỉnh/thành phố');
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
          _showError('Vui lòng nhập tên đường/số nhà');
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
        if (_mainImage == null) {
          _showError('Vui lòng chọn ảnh chính');
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  /// Chọn/chụp ảnh chính (chỉ 1 ảnh)
  Future<void> _pickMainImage() async {
    final source = await showImageSourceDialog(context);
    if (source == null || !mounted) return;

    File? newImage;

    if (source == 'camera') {
      newImage = await _postService.takePicture(context);
    } else if (source == 'gallery') {
      final images = await _postService.pickMultipleImagesFromGallery(
        context,
        maxImages: 1,
      );
      if (images.isNotEmpty) {
        newImage = images.first;
      }
    }

    if (newImage != null && mounted) {
      setState(() {
        _mainImage = newImage;
      });
    }
  }

  /// Chọn/chụp ảnh phụ (nhiều ảnh)
  Future<void> _pickImages() async {
    final source = await showImageSourceDialog(context);
    if (source == null || !mounted) return;

    List<File> newImages = [];

    if (source == 'camera') {
      final image = await _postService.takePicture(context);
      if (image != null) {
        newImages.add(image);
      }
    } else if (source == 'gallery') {
      final remainingSlots = 10 - _selectedImages.length;
      if (remainingSlots <= 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Chỉ được tối đa 10 ảnh phụ')),
          );
        }
        return;
      }
      newImages = await _postService.pickMultipleImagesFromGallery(
        context,
        maxImages: remainingSlots,
      );
    }

    if (newImages.isNotEmpty && mounted) {
      setState(() {
        _selectedImages.addAll(newImages);
        if (_selectedImages.length > 10) {
          _selectedImages = _selectedImages.take(10).toList();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Chỉ được tối đa 10 ảnh phụ')),
          );
        }
      });
    }
  }


  void _removeMainImage() {
    setState(() {
      _mainImage = null;
    });
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submitPost() async {
    if (!_validateCurrentStep()) return;

    setState(() => _isSubmitting = true);

    try {
      // Lấy thông tin user hiện tại để lấy userId
      int userId;
      try {
        final currentUser = await _userService.getProfile();
        userId = currentUser.id;
      } catch (e) {
        // Nếu chưa đăng nhập, yêu cầu đăng nhập
        if (mounted) {
          final shouldLogin = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Yêu cầu đăng nhập', style: AppTextStyles.h6),
              content: Text(
                'Bạn cần đăng nhập để đăng tin. Vui lòng đăng nhập để tiếp tục.',
                style: AppTextStyles.bodyMedium,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('Hủy', style: AppTextStyles.labelLarge),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(
                    'Đăng nhập',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          );

          if (shouldLogin == true && mounted && context.mounted) {
            Navigator.pop(context); // Đóng màn hình đăng tin
            Navigator.pushNamed(
              context,
              '/login',
            ); // Chuyển đến màn hình đăng nhập
          }
        }
        return;
      }

      // Tạo FormData
      final formData = FormData();

      // Tạo địa chỉ đầy đủ từ dropdown
      final fullAddress =
          '${_streetController.text.trim()}, ${_selectedWard!.name}, ${_selectedDistrict!.name}, ${_selectedProvince!.name}';

      final transactionTypeString = _transactionType == TransactionType.sale ? 'Sale' : 'Rent';

      formData.fields.addAll([
        MapEntry('Title', _titleController.text.trim()),
        MapEntry('Description', _descriptionController.text.trim()),
        MapEntry('Price', _priceController.text),
        MapEntry('TransactionType', transactionTypeString),
        MapEntry('Street_Name', _streetController.text.trim()),
        MapEntry('Area_Size', _areaController.text),
        MapEntry('CategoryId', _selectedCategory!.id.toString()),
        MapEntry('UserId', userId.toString()),
        MapEntry('CityName', _selectedProvince!.name),
        MapEntry('DistrictName', _selectedDistrict!.name),
        MapEntry('WardName', _selectedWard!.name),
        MapEntry('FullAddress', fullAddress),
      ]);

      if (_selectedLatitude != null && _selectedLongitude != null) {
        formData.fields.add(MapEntry('Latitude', _selectedLatitude!.toString()));
        formData.fields.add(MapEntry('Longitude', _selectedLongitude!.toString()));
        // PlaceId có thể được thêm sau nếu cần tích hợp Google Places API
        // formData.fields.add(MapEntry('PlaceId', placeId));
      }

      // Optional property details (theo Post.cs)
      if (_soPhongNguController.text.isNotEmpty) {
        final value = int.tryParse(_soPhongNguController.text);
        if (value != null) {
          formData.fields.add(MapEntry('SoPhongNgu', value.toString()));
        }
      }
      if (_soPhongTamController.text.isNotEmpty) {
        final value = int.tryParse(_soPhongTamController.text);
        if (value != null) {
          formData.fields.add(MapEntry('SoPhongTam', value.toString()));
        }
      }
      if (_soTangController.text.isNotEmpty) {
        final value = int.tryParse(_soTangController.text);
        if (value != null) {
          formData.fields.add(MapEntry('SoTang', value.toString()));
        }
      }
      if (_matTienController.text.isNotEmpty) {
        final value = double.tryParse(_matTienController.text);
        if (value != null) {
          formData.fields.add(MapEntry('MatTien', value.toString()));
        }
      }
      if (_duongVaoController.text.isNotEmpty) {
        final value = double.tryParse(_duongVaoController.text);
        if (value != null) {
          formData.fields.add(MapEntry('DuongVao', value.toString()));
        }
      }
      if (_phapLyController.text.trim().isNotEmpty) {
        formData.fields.add(MapEntry('PhapLy', _phapLyController.text.trim()));
      }
      if (_huongNha != null && _huongNha!.isNotEmpty) {
        formData.fields.add(MapEntry('HuongNha', _huongNha!));
      }
      if (_huongBanCong != null && _huongBanCong!.isNotEmpty) {
        formData.fields.add(MapEntry('HuongBanCong', _huongBanCong!));
      }

      // Add images: ảnh chính trước, sau đó là ảnh phụ
      // Backend sẽ lấy ảnh đầu tiên làm ảnh chính (ImageURL)
      if (_mainImage != null) {
        formData.files.add(
          MapEntry(
            'Images',
            await MultipartFile.fromFile(
              _mainImage!.path,
              filename: _mainImage!.path.split('/').last,
            ),
          ),
        );
      }

      // Thêm các ảnh phụ
      for (var image in _selectedImages) {
        formData.files.add(
          MapEntry(
            'Images',
            await MultipartFile.fromFile(
              image.path,
              filename: image.path.split('/').last,
            ),
          ),
        );
      }

      // Submit - role mặc định là 0 (User)
      await _postService.createPost(formData, role: 0);

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
        String errorMessage = 'Lỗi đăng tin';
        if (e is DioException && e.response != null) {
          // Lấy message từ server response
          final responseData = e.response?.data;
          if (responseData is Map && responseData.containsKey('message')) {
            errorMessage = responseData['message'] ?? errorMessage;
          } else if (responseData is String) {
            errorMessage = responseData;
          } else {
            errorMessage = 'Lỗi ${e.response?.statusCode}: ${e.message}';
          }
        } else {
          errorMessage = 'Lỗi đăng tin: $e';
        }
        _showError(errorMessage);
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
                  : Text(
                      'Đăng',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
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
                  margin: EdgeInsets.only(
                    right: index < _totalSteps - 1 ? 8 : 0,
                  ),
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
              onPressed: _currentStep == _totalSteps - 1
                  ? _submitPost
                  : _nextStep,
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
            Text(
              'Nhập tiêu đề và mô tả cho tin đăng của bạn',
              style: AppTextStyles.bodySmall,
            ),
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
                    icon: FontAwesomeIcons.store,
                    isSelected: _transactionType == TransactionType.sale,
                    onSelected: () =>
                        setState(() => _transactionType = TransactionType.sale),
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: _buildChoiceChip(
                    label: 'Cho thuê',
                    icon: FontAwesomeIcons.calendar,
                    isSelected: _transactionType == TransactionType.rent,
                    onSelected: () =>
                        setState(() => _transactionType = TransactionType.rent),
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
                    onSelected: () =>
                        setState(() => _selectedCategory = category),
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
          Text(
            'Chọn địa điểm của bất động sản',
            style: AppTextStyles.bodySmall,
          ),
          const Gap(24),

          // Tỉnh/Thành phố
          _buildDropdown<VietnamProvince>(
            label: 'Tỉnh/Thành phố *',
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
          const Gap(20),

          // Quận/Huyện
          _buildDropdown<VietnamDistrict>(
            label: 'Quận/Huyện *',
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
            enabled: _selectedProvince != null,
          ),
          const Gap(20),

          // Phường/Xã
          _buildDropdown<VietnamWard>(
            label: 'Phường/Xã *',
            value: _selectedWard,
            items: _wards,
            displayText: (ward) => ward.name,
            onChanged: (ward) => setState(() => _selectedWard = ward),
            enabled: _selectedDistrict != null,
          ),
          const Gap(20),

          // Tên đường/Số nhà
          _buildTextField(
            controller: _streetController,
            label: 'Tên đường/Số nhà *',
            hint: 'VD: 123 Nguyễn Huệ',
            onChanged: (value) =>
                setState(() {}), // Trigger rebuild để hiển thị map selector
          ),
          const Gap(24),

          // Chọn vị trí trên bản đồ (chỉ hiển thị khi đã chọn đủ địa chỉ)
          if (_selectedProvince != null &&
              _selectedDistrict != null &&
              _selectedWard != null &&
              _streetController.text.trim().isNotEmpty)
            _buildMapSelectorSection(),
        ],
      ),
    );
  }

  /// Widget hiển thị section chọn vị trí trên bản đồ
  Widget _buildMapSelectorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vị trí trên bản đồ',
          style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w600),
        ),
        const Gap(8),
        Text(
          'Chọn vị trí chính xác trên bản đồ để lưu tọa độ (tùy chọn)',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const Gap(12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _selectedLatitude != null && _selectedLongitude != null
                ? AppColors.success.withValues(alpha: 0.1)
                : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _selectedLatitude != null && _selectedLongitude != null
                  ? AppColors.success
                  : AppColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_selectedLatitude != null && _selectedLongitude != null) ...[
                Row(
                  children: [
                    const FaIcon(
                      FontAwesomeIcons.circleCheck,
                      color: AppColors.success,
                      size: 20,
                    ),
                    const Gap(8),
                    Expanded(
                      child: Text(
                        'Đã chọn vị trí',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const Gap(8),
                Text(
                  'Lat: ${_selectedLatitude!.toStringAsFixed(6)}',
                  style: AppTextStyles.bodySmall,
                ),
                Text(
                  'Lng: ${_selectedLongitude!.toStringAsFixed(6)}',
                  style: AppTextStyles.bodySmall,
                ),
              ] else ...[
                Row(
                  children: [
                    const FaIcon(
                      FontAwesomeIcons.mapLocationDot,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    const Gap(8),
                    Expanded(
                      child: Text(
                        'Chưa chọn vị trí',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const Gap(12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _openMapSelector,
                  icon: const FaIcon(FontAwesomeIcons.map, size: 16),
                  label: Text(
                    _selectedLatitude != null && _selectedLongitude != null
                        ? 'Thay đổi vị trí'
                        : 'Chọn vị trí trên bản đồ',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Lấy tọa độ mặc định dựa trên tên thành phố
  /// Fallback khi geocoding thất bại
  LatLng _getDefaultLocationByCity(String cityName) {
    // Normalize city name để so sánh
    final normalizedName = cityName.toLowerCase().trim();

    // Tọa độ các thành phố lớn ở Việt Nam
    if (normalizedName.contains('hồ chí minh') ||
        normalizedName.contains('ho chi minh') ||
        normalizedName.contains('tp. hồ chí minh') ||
        normalizedName.contains('tp hồ chí minh') ||
        normalizedName == 'hcm' ||
        normalizedName == 'sài gòn' ||
        normalizedName.contains('sai gon')) {
      return const LatLng(10.7769, 106.7009); // TP. Hồ Chí Minh
    }

    if (normalizedName.contains('hà nội') ||
        normalizedName.contains('ha noi') ||
        normalizedName.contains('hanoi')) {
      return const LatLng(21.0285, 105.8542); // Hà Nội
    }

    if (normalizedName.contains('đà nẵng') ||
        normalizedName.contains('da nang') ||
        normalizedName.contains('danang')) {
      return const LatLng(16.0544, 108.2022); // Đà Nẵng
    }

    if (normalizedName.contains('hải phòng') ||
        normalizedName.contains('hai phong')) {
      return const LatLng(20.8449, 106.6881); // Hải Phòng
    }

    if (normalizedName.contains('cần thơ') ||
        normalizedName.contains('can tho')) {
      return const LatLng(10.0452, 105.7469); // Cần Thơ
    }

    // Mặc định: Trung tâm Việt Nam (nếu không nhận diện được)
    return const LatLng(16.0544, 108.2022); // Đà Nẵng (trung tâm địa lý)
  }

  /// Mở bottom sheet để chọn vị trí trên map
  Future<void> _openMapSelector() async {
    if (_selectedProvince == null ||
        _selectedDistrict == null ||
        _selectedWard == null ||
        _streetController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn đầy đủ địa chỉ trước'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Tìm tọa độ ban đầu từ địa chỉ đã nhập (ưu tiên sử dụng thông tin đã nhập)
    LatLng? initialCenter;

    // Thử geocode với các mức độ khác nhau (từ chi tiết đến tổng quát)
    final geocodeAttempts = [
      // 1. Địa chỉ đầy đủ (nếu có street)
      if (_streetController.text.trim().isNotEmpty)
        '${_streetController.text.trim()}, ${_selectedWard!.name}, ${_selectedDistrict!.name}, ${_selectedProvince!.name}',
      // 2. Quận + Thành phố
      '${_selectedDistrict!.name}, ${_selectedProvince!.name}',
      // 3. Chỉ Thành phố
      _selectedProvince!.name,
    ];

    // Thử từng mức độ cho đến khi tìm được
    for (final addressString in geocodeAttempts) {
      try {
        final result = await NominatimService.geocodeAddress(addressString);
        if (result != null &&
            result.containsKey('lat') &&
            result.containsKey('lon')) {
          initialCenter = LatLng(result['lat']!, result['lon']!);
          break; // Tìm được rồi, dừng lại
        }
      } catch (e) {
        // Tiếp tục thử mức độ tiếp theo
        continue;
      }
    }

    // Nếu vẫn không tìm được, dùng fallback dựa trên tên thành phố
    initialCenter ??= _getDefaultLocationByCity(_selectedProvince!.name);

    if (!mounted) return;

    final mapController = MapController();
    LatLng? selectedLocation =
        _selectedLatitude != null && _selectedLongitude != null
        ? LatLng(_selectedLatitude!, _selectedLongitude!)
        : null;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MapSelectorBottomSheet(
        mapController: mapController,
        initialCenter: initialCenter ?? const LatLng(21.0285, 105.8542),
        selectedLocation: selectedLocation,
        onLocationSelected: (location) {
          setState(() {
            _selectedLatitude = location.latitude;
            _selectedLongitude = location.longitude;
          });
        },
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
          Text(
            'Nhập thông tin giá và diện tích',
            style: AppTextStyles.bodySmall,
          ),
          const Gap(24),

          // Giá
          _buildTextField(
            controller: _priceController,
            label: 'Giá (VNĐ) *',
            hint: 'VD: 5000000 (sẽ tự động format: 5 triệu)',
            keyboardType: TextInputType.number,
            suffixText: 'VNĐ',
            onChanged: (value) => setState(() {}), // Trigger rebuild để hiển thị preview
          ),
          // Hiển thị preview format nếu đã nhập giá
          if (_priceController.text.isNotEmpty)
            Builder(
              builder: (context) {
                final priceValue = double.tryParse(_priceController.text) ?? 0;
                if (priceValue > 0) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                        const Gap(4),
                        Text(
                          'Sẽ hiển thị: ${Formatters.formatCurrency(priceValue)} VNĐ',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
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
          Text(
            'Các thông tin bổ sung (tùy chọn)',
            style: AppTextStyles.bodySmall,
          ),
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
          const Gap(24),

          // Phần 1: Ảnh chính
          Text('Ảnh chính *', style: AppTextStyles.labelLarge),
          const Gap(8),
          Text(
            'Chọn hoặc chụp 1 ảnh chính cho tin đăng',
            style: AppTextStyles.bodySmall,
          ),
          const Gap(12),
          _buildMainImageSection(),

          const Gap(32),

          // Phần 2: Ảnh phụ
          Text('Ảnh phụ', style: AppTextStyles.labelLarge),
          const Gap(8),
          Text(
            'Thêm các ảnh phụ (tối đa 10 ảnh)',
            style: AppTextStyles.bodySmall,
          ),
          const Gap(12),
          _buildAdditionalImagesSection(),
        ],
      ),
    );
  }

  Widget _buildMainImageSection() {
    if (_mainImage == null) {
      return GestureDetector(
        onTap: _pickMainImage,
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.border,
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(
                FontAwesomeIcons.image,
                size: 48,
                color: AppColors.textHint,
              ),
              const Gap(12),
              Text('Thêm ảnh chính', style: AppTextStyles.labelLarge),
              const Gap(4),
              Text(
                'Chạm để chọn hoặc chụp ảnh',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.file(
            _mainImage!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: 200,
          ),
        ),
        Positioned(
          top: 8,
          left: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Ảnh chính',
              style: AppTextStyles.labelSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: _removeMainImage,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 20, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalImagesSection() {
    if (_selectedImages.isEmpty) {
      return GestureDetector(
        onTap: _pickImages,
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.border,
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(
                FontAwesomeIcons.images,
                size: 32,
                color: AppColors.textHint,
              ),
              const Gap(8),
              Text('Thêm ảnh phụ', style: AppTextStyles.bodyMedium),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
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
            FaIcon(
              FontAwesomeIcons.plus,
              size: 32,
              color: AppColors.textSecondary,
            ),
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
    Widget? suffixIcon,
    bool enabled = true,
    void Function(String)? onChanged,
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
          enabled: enabled,
          onChanged: onChanged,
          style: AppTextStyles.bodyMedium,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textHint,
            ),
            suffixText: suffixText,
            suffixIcon: suffixIcon,
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
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
              Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
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
            initialValue: value,
            items: [
              if (allowNull)
                DropdownMenuItem<T>(
                  value: null,
                  child: Text('Không chọn', style: AppTextStyles.bodyMedium),
                ),
              ...items.map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(
                    displayText(item),
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
              ),
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
  State<_MapSelectorBottomSheet> createState() =>
      _MapSelectorBottomSheetState();
}

class _MapSelectorBottomSheetState extends State<_MapSelectorBottomSheet> {
  LatLng? _currentSelection;

  @override
  void initState() {
    super.initState();
    _currentSelection = widget.selectedLocation;
    // Center map khi mở
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.mapController.move(widget.initialCenter, 15.0);
    });
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
                      icon: const FaIcon(FontAwesomeIcons.xmark, size: 20),
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
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
