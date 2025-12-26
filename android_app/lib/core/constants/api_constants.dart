/// Các API Endpoints - Chỉ chứa đường dẫn, không chứa base URL
/// Base URL được cấu hình trong app_config.dart
class ApiConstants {
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
  static const String postSearchByRadius = '/posts/map-radius-search';
  static const String postsByUser = '/posts/user'; // + /{userId}

  // Category Endpoints
  static const String categories = '/categories';
  static const String categoriesAll = '/categories/all';

  // Location Endpoints (City/District/Ward)
  static const String cities = '/locations/cities';
  static const String districts = '/locations/districts';
  static const String wards = '/locations/wards';
  
  // Favorite Endpoints
  static const String favorites = '/favorites';

  // Message Endpoints
  static const String messages = '/messages';

  // Notification Endpoints
  static const String notifications = '/notifications';

  // Appointment Endpoints
  static const String appointments = '/appointments';
  static const String appointmentsMe = '/appointments/me';
  static const String appointmentsForMyPosts = '/appointments/for-my-posts';

  // Payment Endpoints
  static const String payment = '/payment';

  // Saved Search Endpoints
  static const String savedSearches = '/saved-searches';
}
