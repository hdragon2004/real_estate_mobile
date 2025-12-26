import 'package:dio/dio.dart';

class NominatimService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org';
  
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'User-Agent': 'RealEstateHub/1.0 (contact@realestatehub.com)',
      },
    ),
  );

  /// Chuyển đổi địa chỉ thành tọa độ (lat, lon)
  static Future<Map<String, double>?> geocodeAddress(String address) async {
    try {
      // Thêm "Vietnam" vào cuối để tăng độ chính xác
      final searchQuery = address.contains('Vietnam') 
          ? address 
          : '$address, Vietnam';
      
      final response = await _dio.get(
        '/search',
        queryParameters: {
          'q': searchQuery,
          'format': 'json',
          'limit': '1',
          'countrycodes': 'vn', 
        },
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        
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
      return null;
    }
  }
  
  /// Reverse geocode - lấy địa chỉ từ tọa độ (optional, không bắt buộc)
  static Future<String?> reverseGeocode(double lat, double lon) async {
    try {
      final response = await _dio.get(
        '/reverse',
        queryParameters: {
          'lat': lat.toString(),
          'lon': lon.toString(),
          'format': 'json',
          'zoom': '18',
        },
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        return data['display_name']?.toString();
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }
}

