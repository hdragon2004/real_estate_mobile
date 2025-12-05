import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service để tích hợp Google Places API
/// Cần thêm package: http
/// Cần Google Places API Key trong app_config.dart
class GooglePlacesService {
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api';
  
  /// Tìm kiếm địa điểm với autocomplete
  static Future<List<PlacePrediction>> searchPlaces(
    String query, {
    String? apiKey,
    String? language = 'vi',
    String? components = 'country:vn', // Giới hạn tìm kiếm trong Việt Nam
  }) async {
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Google Places API Key is required');
    }

    try {
      final url = Uri.parse(
        '$_baseUrl/place/autocomplete/json?'
        'input=${Uri.encodeComponent(query)}'
        '&key=$apiKey'
        '&language=$language'
        '&components=$components',
      );

      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' || data['status'] == 'ZERO_RESULTS') {
          final predictions = data['predictions'] as List?;
          if (predictions != null) {
            return predictions
                .map((p) => PlacePrediction.fromJson(p))
                .toList();
          }
        } else {
          throw Exception('Google Places API error: ${data['status']}');
        }
      } else {
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching places: $e');
    }
    
    return [];
  }

  /// Lấy chi tiết địa điểm từ place_id
  static Future<PlaceDetails> getPlaceDetails(
    String placeId, {
    String? apiKey,
    String? language = 'vi',
  }) async {
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Google Places API Key is required');
    }

    try {
      final url = Uri.parse(
        '$_baseUrl/place/details/json?'
        'place_id=$placeId'
        '&key=$apiKey'
        '&language=$language'
        '&fields=place_id,name,formatted_address,geometry,address_components',
      );

      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          return PlaceDetails.fromJson(data['result']);
        } else {
          throw Exception('Google Places API error: ${data['status']}');
        }
      } else {
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting place details: $e');
    }
  }

  /// Geocoding: Chuyển đổi tọa độ thành địa chỉ
  static Future<PlaceDetails> reverseGeocode(
    double latitude,
    double longitude, {
    String? apiKey,
    String? language = 'vi',
  }) async {
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Google Places API Key is required');
    }

    try {
      final url = Uri.parse(
        '$_baseUrl/geocode/json?'
        'latlng=$latitude,$longitude'
        '&key=$apiKey'
        '&language=$language',
      );

      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          return PlaceDetails.fromJson(data['results'][0]);
        } else {
          throw Exception('Google Places API error: ${data['status']}');
        }
      } else {
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error reverse geocoding: $e');
    }
  }
}

/// Model cho Place Prediction (kết quả autocomplete)
class PlacePrediction {
  final String placeId;
  final String description;
  final String? mainText;
  final String? secondaryText;

  PlacePrediction({
    required this.placeId,
    required this.description,
    this.mainText,
    this.secondaryText,
  });

  factory PlacePrediction.fromJson(Map<String, dynamic> json) {
    final structuredFormatting = json['structured_formatting'];
    return PlacePrediction(
      placeId: json['place_id'] ?? '',
      description: json['description'] ?? '',
      mainText: structuredFormatting?['main_text'],
      secondaryText: structuredFormatting?['secondary_text'],
    );
  }
}

/// Model cho Place Details (chi tiết địa điểm)
class PlaceDetails {
  final String placeId;
  final String name;
  final String formattedAddress;
  final double? latitude;
  final double? longitude;
  final AddressComponents addressComponents;

  PlaceDetails({
    required this.placeId,
    required this.name,
    required this.formattedAddress,
    this.latitude,
    this.longitude,
    required this.addressComponents,
  });

  factory PlaceDetails.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry'];
    final location = geometry?['location'];
    
    return PlaceDetails(
      placeId: json['place_id'] ?? '',
      name: json['name'] ?? '',
      formattedAddress: json['formatted_address'] ?? '',
      latitude: location != null ? (location['lat'] as num?)?.toDouble() : null,
      longitude: location != null ? (location['lng'] as num?)?.toDouble() : null,
      addressComponents: AddressComponents.fromJson(json['address_components'] ?? []),
    );
  }

  /// Parse địa chỉ để tìm City, District, Ward
  /// Trả về map với keys: cityName, districtName, wardName, streetName
  Map<String, String?> parseAddress() {
    final components = addressComponents;
    
    // Tìm các thành phần địa chỉ
    String? cityName = components.locality ?? components.administrativeAreaLevel1;
    String? districtName = components.administrativeAreaLevel2 ?? components.sublocality;
    String? wardName = components.sublocalityLevel1 ?? components.sublocalityLevel2;
    String? streetName = components.route;
    String? streetNumber = components.streetNumber;
    
    // Kết hợp street number và route
    if (streetNumber != null && streetName != null) {
      streetName = '$streetNumber $streetName';
    } else if (streetNumber != null) {
      streetName = streetNumber;
    }
    
    return {
      'cityName': cityName,
      'districtName': districtName,
      'wardName': wardName,
      'streetName': streetName ?? formattedAddress.split(',').first.trim(),
    };
  }
}

/// Model cho Address Components
class AddressComponents {
  final String? streetNumber;
  final String? route;
  final String? locality; // Thành phố
  final String? administrativeAreaLevel1; // Tỉnh/Thành phố
  final String? administrativeAreaLevel2; // Quận/Huyện
  final String? sublocality; // Phường/Xã
  final String? sublocalityLevel1;
  final String? sublocalityLevel2;
  final String? country;

  AddressComponents({
    this.streetNumber,
    this.route,
    this.locality,
    this.administrativeAreaLevel1,
    this.administrativeAreaLevel2,
    this.sublocality,
    this.sublocalityLevel1,
    this.sublocalityLevel2,
    this.country,
  });

  factory AddressComponents.fromJson(List<dynamic> components) {
    String? streetNumber;
    String? route;
    String? locality;
    String? administrativeAreaLevel1;
    String? administrativeAreaLevel2;
    String? sublocality;
    String? sublocalityLevel1;
    String? sublocalityLevel2;
    String? country;

    for (var component in components) {
      final types = List<String>.from(component['types'] ?? []);
      final longName = component['long_name'] ?? '';
      final shortName = component['short_name'] ?? '';

      if (types.contains('street_number')) {
        streetNumber = longName;
      } else if (types.contains('route')) {
        route = longName;
      } else if (types.contains('locality')) {
        locality = longName;
      } else if (types.contains('administrative_area_level_1')) {
        administrativeAreaLevel1 = longName;
      } else if (types.contains('administrative_area_level_2')) {
        administrativeAreaLevel2 = longName;
      } else if (types.contains('sublocality')) {
        sublocality = longName;
      } else if (types.contains('sublocality_level_1')) {
        sublocalityLevel1 = longName;
      } else if (types.contains('sublocality_level_2')) {
        sublocalityLevel2 = longName;
      } else if (types.contains('country')) {
        country = longName;
      }
    }

    return AddressComponents(
      streetNumber: streetNumber,
      route: route,
      locality: locality,
      administrativeAreaLevel1: administrativeAreaLevel1,
      administrativeAreaLevel2: administrativeAreaLevel2,
      sublocality: sublocality,
      sublocalityLevel1: sublocalityLevel1,
      sublocalityLevel2: sublocalityLevel2,
      country: country,
    );
  }
}

