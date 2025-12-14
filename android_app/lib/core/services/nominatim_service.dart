import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Service để sử dụng OpenStreetMap Nominatim API (FREE)
/// 
/// LƯU Ý: Chúng ta CHỈ dùng Nominatim để CENTER map, KHÔNG dùng để lấy tọa độ tự động
/// Tọa độ (lat/lng) sẽ được lấy từ việc user TAP trên map
/// 
/// Tại sao không dùng Google Geocoding API?
/// - Google API có phí và cần API key
/// - Nominatim là FREE và không cần API key
/// - Nominatim đủ tốt để center map dựa trên địa chỉ hành chính
class NominatimService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org';
  
  /// Geocode địa chỉ để lấy tọa độ (chỉ để center map)
  /// 
  /// [address] là địa chỉ đầy đủ: "Phường X, Quận Y, Thành phố Z, Vietnam"
  /// 
  /// Returns: LatLng? - null nếu không tìm thấy
  /// 
  /// LƯU Ý: Chúng ta CHỈ dùng kết quả này để CENTER map ban đầu
  /// User sẽ TAP trên map để chọn vị trí chính xác
  static Future<Map<String, double>?> geocodeAddress(String address) async {
    try {
      // Thêm "Vietnam" vào cuối để tăng độ chính xác
      final searchQuery = address.contains('Vietnam') 
          ? address 
          : '$address, Vietnam';
      
      final uri = Uri.parse('$_baseUrl/search')
          .replace(queryParameters: {
        'q': searchQuery,
        'format': 'json',
        'limit': '1',
        'countrycodes': 'vn', // Chỉ tìm trong Việt Nam
      });
      
      // Nominatim yêu cầu User-Agent header
      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'RealEstateHub/1.0 (contact@realestatehub.com)',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data is List && data.isNotEmpty) {
          final result = data[0];
          final lat = double.tryParse(result['lat']?.toString() ?? '');
          final lon = double.tryParse(result['lon']?.toString() ?? '');
          
          if (lat != null && lon != null) {
            return {'lat': lat, 'lon': lon};
          }
        }
      }
      
      return null;
    } catch (e) {
      // Log error nhưng không throw - map sẽ dùng default center
      debugPrint('Nominatim geocoding error: $e');
      return null;
    }
  }
  
  /// Reverse geocode - lấy địa chỉ từ tọa độ (optional, không bắt buộc)
  static Future<String?> reverseGeocode(double lat, double lon) async {
    try {
      final uri = Uri.parse('$_baseUrl/reverse')
          .replace(queryParameters: {
        'lat': lat.toString(),
        'lon': lon.toString(),
        'format': 'json',
        'zoom': '18',
      });
      
      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'RealEstateHub/1.0 (contact@realestatehub.com)',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['display_name']?.toString();
      }
      
      return null;
    } catch (e) {
      debugPrint('Nominatim reverse geocoding error: $e');
      return null;
    }
  }
}

