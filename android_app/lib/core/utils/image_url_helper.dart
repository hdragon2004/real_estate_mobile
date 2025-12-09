import '../../config/app_config.dart';

/// Utility class để resolve image URL từ relative path thành full URL
class ImageUrlHelper {
  /// Resolve image URL từ relative path (bắt đầu bằng /) thành full URL
  /// Nếu URL đã là full URL (bắt đầu bằng http/https) thì trả về nguyên
  /// 
  /// Lưu ý: Static files (uploads) được serve từ root của server, không phải từ /api
  /// Ví dụ: /uploads/image.jpg -> https://domain.com/uploads/image.jpg (không có /api)
  static String resolveImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    
    // Nếu đã là full URL, trả về nguyên
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    
    // Nếu là relative path (bắt đầu bằng /), thêm base URL
    if (url.startsWith('/')) {
      // Lấy base URL từ AppConfig
      String baseUrl = AppConfig.baseUrl;
      
      // Loại bỏ /api vì static files được serve từ root, không phải từ /api
      if (baseUrl.endsWith('/api')) {
        baseUrl = baseUrl.substring(0, baseUrl.length - 4); // Loại bỏ '/api'
      } else if (baseUrl.endsWith('/api/')) {
        baseUrl = baseUrl.substring(0, baseUrl.length - 5); // Loại bỏ '/api/'
      } else if (baseUrl.endsWith('/')) {
        baseUrl = baseUrl.substring(0, baseUrl.length - 1); // Loại bỏ trailing slash
      }
      
      return '$baseUrl$url';
    }
    
    // Trường hợp khác, trả về nguyên
    return url;
  }
  
  /// Resolve nhiều image URLs cùng lúc
  static List<String> resolveImageUrls(List<String> urls) {
    return urls.map((url) => resolveImageUrl(url)).where((url) => url.isNotEmpty).toList();
  }
}

