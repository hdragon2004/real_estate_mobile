import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

class ApiConstants {
  // Tự động chọn baseUrl phù hợp với platform
  static String get baseUrl {
    if (kIsWeb) {
      // Chạy trên Web (Chrome, Edge)
      return 'http://localhost:5134/api';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      // Android Emulator: 10.0.2.2 trỏ tới localhost của máy tính
      return 'http://10.0.2.2:5134/api';
    } else {
      // Windows, macOS, Linux, iOS
      return 'http://localhost:5134/api';
    }
  }

  // Auth Endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';

  // User Endpoints
  static const String users = '/users';
  static const String userProfile = '/users/profile';
  static const String userAvatar = '/users/avatar';

  // Post Endpoints (Bất động sản)
  static const String posts = '/posts';
  static const String postSearch = '/posts/search';
  static const String postsByUser = '/posts/user'; // + /{userId}
  static const String postDraft = '/posts/draft';
  static const String postDraftSave = '/posts/draft/save';

  // Category Endpoints
  static const String categories = '/categories';
  static const String categoriesAll = '/categories/all';

  // Area Endpoints
  static const String cities = '/areas/cities';
  static const String districts = '/areas/districts';
  static const String wards = '/areas/wards';
  // /areas/cities/{cityId}/districts - lấy quận theo thành phố
  // /areas/districts/{districtId}/wards - lấy phường theo quận

  // Favorite Endpoints
  static const String favorites = '/favorites';

  // Message Endpoints
  static const String messages = '/messages';

  // Payment Endpoints
  static const String payment = '/payment';
}
