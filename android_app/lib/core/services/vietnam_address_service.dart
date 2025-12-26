import 'package:dio/dio.dart';
import '../models/vietnam_address_model.dart';

/// Service để fetch dữ liệu địa chỉ Việt Nam từ API provinces.open-api.vn
class VietnamAddressService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://provinces.open-api.vn/api',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  );

  /// Cache để tránh gọi API nhiều lần
  static List<VietnamProvince>? _cachedProvinces;
  static final Map<String, List<VietnamDistrict>> _cachedDistricts = {};
  static final Map<String, List<VietnamWard>> _cachedWards = {};

  /// Lấy danh sách tất cả tỉnh/thành phố
  static Future<List<VietnamProvince>> fetchProvinces() async {
    if (_cachedProvinces != null) {
      return _cachedProvinces!;
    }

    try {
      final response = await _dio.get('/?depth=1');
      if (response.data is List) {
        _cachedProvinces = (response.data as List)
            .map((province) => VietnamProvince.fromJson(province))
            .toList();
        return _cachedProvinces!;
      }
      throw Exception('Invalid response format');
    } catch (e) {
      throw Exception('Lỗi fetch tỉnh/thành phố: $e');
    }
  }

  /// Lấy danh sách quận/huyện theo mã tỉnh/thành phố
  static Future<List<VietnamDistrict>> fetchDistricts(String provinceCode) async {
    if (_cachedDistricts.containsKey(provinceCode)) {
      return _cachedDistricts[provinceCode]!;
    }

    try {
      final response = await _dio.get('/p/$provinceCode?depth=2');
      if (response.data is Map && response.data['districts'] != null) {
        final districts = (response.data['districts'] as List)
            .map((district) => VietnamDistrict.fromJson(district))
            .toList();
        _cachedDistricts[provinceCode] = districts;
        return districts;
      }
      return [];
    } catch (e) {
      throw Exception('Lỗi fetch quận/huyện: $e');
    }
  }

  /// Lấy danh sách phường/xã theo mã quận/huyện
  static Future<List<VietnamWard>> fetchWards(String districtCode) async {
    if (_cachedWards.containsKey(districtCode)) {
      return _cachedWards[districtCode]!;
    }

    try {
      final response = await _dio.get('/d/$districtCode?depth=2');
      if (response.data is Map && response.data['wards'] != null) {
        final wards = (response.data['wards'] as List)
            .map((ward) => VietnamWard.fromJson(ward))
            .toList();
        _cachedWards[districtCode] = wards;
        return wards;
      }
      return [];
    } catch (e) {
      throw Exception('Lỗi fetch phường/xã: $e');
    }
  }

  /// Clear cache (nếu cần reload)
  static void clearCache() {
    _cachedProvinces = null;
    _cachedDistricts.clear();
    _cachedWards.clear();
  }
}

