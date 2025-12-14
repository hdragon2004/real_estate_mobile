import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../core/models/vietnam_address_model.dart';
import '../../../core/services/vietnam_address_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../widgets/common/app_dropdown.dart';

/// Widget chọn địa chỉ hành chính (Province/District/Ward)
/// 
/// Widget này CHỈ có dropdowns, KHÔNG có map và street input
/// Dùng cho:
/// - Filter screen
/// - Các nơi chỉ cần chọn địa chỉ hành chính
/// 
/// Nếu cần map + street + coordinates, dùng `AddressSelectionWidget` thay thế
class AddressSelectorWidget extends StatefulWidget {
  /// Callback khi user chọn xong địa chỉ
  final Function(VietnamProvince?, VietnamDistrict?, VietnamWard?)? onAddressChanged;
  
  /// Địa chỉ ban đầu (nếu có)
  final VietnamProvince? initialProvince;
  final VietnamDistrict? initialDistrict;
  final VietnamWard? initialWard;
  
  /// Có cho phép null không (dùng cho filter)
  final bool allowNull;
  
  /// Labels tùy chỉnh
  final String? provinceLabel;
  final String? districtLabel;
  final String? wardLabel;

  const AddressSelectorWidget({
    super.key,
    this.onAddressChanged,
    this.initialProvince,
    this.initialDistrict,
    this.initialWard,
    this.allowNull = false,
    this.provinceLabel,
    this.districtLabel,
    this.wardLabel,
  });

  @override
  State<AddressSelectorWidget> createState() => _AddressSelectorWidgetState();
}

class _AddressSelectorWidgetState extends State<AddressSelectorWidget> {
  // Selected values
  VietnamProvince? _selectedProvince;
  VietnamDistrict? _selectedDistrict;
  VietnamWard? _selectedWard;
  
  // Data lists
  List<VietnamProvince> _provinces = [];
  List<VietnamDistrict> _districts = [];
  List<VietnamWard> _wards = [];
  
  // UI state
  bool _isLoading = false;
  bool _isLoadingDistricts = false;
  bool _isLoadingWards = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedProvince = widget.initialProvince;
    _selectedDistrict = widget.initialDistrict;
    _selectedWard = widget.initialWard;
    _loadProvinces();
    
    // Load districts/wards nếu có initial values
    if (_selectedProvince != null) {
      _loadDistricts(_selectedProvince!.code);
    }
    if (_selectedDistrict != null) {
      _loadWards(_selectedDistrict!.code);
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
    setState(() {
      _isLoadingDistricts = true;
    });

    try {
      final districts = await VietnamAddressService.fetchDistricts(provinceCode);
      if (!mounted) return;

      setState(() {
        _districts = districts;
        _selectedDistrict = null;
        _selectedWard = null;
        _wards = [];
        _isLoadingDistricts = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingDistricts = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tải quận/huyện: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _loadWards(String districtCode) async {
    setState(() {
      _isLoadingWards = true;
    });

    try {
      final wards = await VietnamAddressService.fetchWards(districtCode);
      if (!mounted) return;

      setState(() {
        _wards = wards;
        _selectedWard = null;
        _isLoadingWards = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingWards = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tải phường/xã: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _notifyChange() {
    widget.onAddressChanged?.call(
      _selectedProvince,
      _selectedDistrict,
      _selectedWard,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                const Icon(Icons.error_outline, color: AppColors.error, size: 16),
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

        // Province dropdown
        AppDropdown<VietnamProvince>(
          label: widget.provinceLabel ?? 'Tỉnh/Thành phố',
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
            });
            if (province != null) {
              _loadDistricts(province.code);
            }
            _notifyChange();
          },
          enabled: !_isLoading,
          isLoading: _isLoading,
          allowNull: widget.allowNull,
          nullLabel: 'Tất cả',
          icon: Icons.location_city,
        ),

        // District dropdown (chỉ hiện khi có province)
        if (_selectedProvince != null || widget.allowNull) ...[
          const Gap(16),
          AppDropdown<VietnamDistrict>(
            label: widget.districtLabel ?? 'Quận/Huyện',
            value: _selectedDistrict,
            items: _districts,
            displayText: (d) => d.name,
            onChanged: (district) {
              setState(() {
                _selectedDistrict = district;
                _selectedWard = null;
                _wards = [];
              });
              if (district != null) {
                _loadWards(district.code);
              }
              _notifyChange();
            },
            enabled: _selectedProvince != null && !_isLoadingDistricts,
            isLoading: _isLoadingDistricts,
            allowNull: widget.allowNull,
            nullLabel: 'Tất cả',
            icon: Icons.location_on,
          ),
        ],

        // Ward dropdown (chỉ hiện khi có district)
        if ((_selectedDistrict != null || widget.allowNull) && 
            (_selectedProvince != null || widget.allowNull)) ...[
          const Gap(16),
          AppDropdown<VietnamWard>(
            label: widget.wardLabel ?? 'Phường/Xã',
            value: _selectedWard,
            items: _wards,
            displayText: (w) => w.name,
            onChanged: (ward) {
              setState(() {
                _selectedWard = ward;
              });
              _notifyChange();
            },
            enabled: _selectedDistrict != null && !_isLoadingWards,
            isLoading: _isLoadingWards,
            allowNull: widget.allowNull,
            nullLabel: 'Tất cả',
            icon: Icons.place,
          ),
        ],
      ],
    );
  }
}

