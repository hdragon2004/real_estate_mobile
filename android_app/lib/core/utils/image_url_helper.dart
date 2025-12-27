import '../../config/app_config.dart';

class ImageUrlHelper {

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

