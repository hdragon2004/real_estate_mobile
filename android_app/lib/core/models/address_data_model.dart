import 'vietnam_address_model.dart';

/// Model cho dữ liệu địa chỉ đầy đủ để gửi lên backend
/// 
/// Bao gồm:
/// - Thông tin hành chính (province, district, ward) từ provinces.open-api.vn
/// - Đường phố (street) do user nhập
/// - Tọa độ (latitude, longitude) từ việc user TAP trên map
/// 
/// LƯU Ý: Dùng objects (VietnamProvince/District/Ward) thay vì duplicate fields
/// để tránh trùng lặp code và tăng type safety
class AddressData {
  final VietnamProvince province;
  final VietnamDistrict district;
  final VietnamWard ward;
  final String street;
  final double latitude;
  final double longitude;

  AddressData({
    required this.province,
    required this.district,
    required this.ward,
    required this.street,
    required this.latitude,
    required this.longitude,
  });

  /// Factory constructor từ objects (cách khuyến nghị)
  factory AddressData.fromVietnamAddress({
    required VietnamProvince province,
    required VietnamDistrict district,
    required VietnamWard ward,
    required String street,
    required double latitude,
    required double longitude,
  }) {
    return AddressData(
      province: province,
      district: district,
      ward: ward,
      street: street,
      latitude: latitude,
      longitude: longitude,
    );
  }

  /// Factory constructor từ fields (backward compatibility)
  /// Dùng khi cần tạo từ code/name strings
  factory AddressData.fromFields({
    required String provinceCode,
    required String provinceName,
    required String districtCode,
    required String districtName,
    required String wardCode,
    required String wardName,
    required String street,
    required double latitude,
    required double longitude,
  }) {
    return AddressData(
      province: VietnamProvince(code: provinceCode, name: provinceName),
      district: VietnamDistrict(code: districtCode, name: districtName),
      ward: VietnamWard(code: wardCode, name: wardName),
      street: street,
      latitude: latitude,
      longitude: longitude,
    );
  }

  // Getters cho backward compatibility (nếu code cũ dùng .provinceCode)
  String get provinceCode => province.code;
  String get provinceName => province.name;
  String get districtCode => district.code;
  String get districtName => district.name;
  String get wardCode => ward.code;
  String get wardName => ward.name;

  /// Convert sang Map để gửi lên backend
  Map<String, dynamic> toJson() {
    return {
      'province': {
        'code': province.code,
        'name': province.name,
      },
      'district': {
        'code': district.code,
        'name': district.name,
      },
      'ward': {
        'code': ward.code,
        'name': ward.name,
      },
      'street': street,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  /// Tạo địa chỉ đầy đủ dạng text
  String get fullAddress {
    return '$street, ${ward.name}, ${district.name}, ${province.name}';
  }

  /// Validate dữ liệu
  bool get isValid {
    return province.code.isNotEmpty &&
        district.code.isNotEmpty &&
        ward.code.isNotEmpty &&
        street.trim().isNotEmpty &&
        latitude != 0 &&
        longitude != 0;
  }
}

