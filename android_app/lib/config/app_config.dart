import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

/// Cấu hình kết nối Backend API
class AppConfig {
  // ============================================
  // CẤU HÌNH KẾT NỐI BACKEND
  // ============================================
  
  /// Chế độ kết nối: 'ngrok' hoặc 'local'
  /// - 'ngrok': Sử dụng ngrok tunnel (không cần đổi IP mỗi lần build)
  /// - 'local': Sử dụng IP local (cần đổi IP khi chuyển mạng)
  static const String connectionMode = 'ngrok'; // 'ngrok' hoặc 'local'
  
  // ============================================
  // CẤU HÌNH NGROK (khi connectionMode = 'ngrok')
  // ============================================
  /// Ngrok domain từ file ngrok.yml
  /// Domain này tương ứng với tunnel có addr: 5134 (android-api)
  static const String ngrokDomain = 'expressless-dorla-destructively.ngrok-free.dev';
  
  /// Protocol cho ngrok (http hoặc https)
  static const String ngrokProtocol = 'https'; // ngrok mặc định dùng https
  
  // ============================================
  // CẤU HÌNH LOCAL (khi connectionMode = 'local')
  // ============================================
  /// Sử dụng Emulator hay thiết bị thật (chỉ dùng khi connectionMode = 'local')
  static const bool useEmulator = false; // true = Emulator, false = Thiết bị thật
  
  /// IP của máy tính chạy backend (chỉ dùng khi connectionMode = 'local' và useEmulator = false)
  /// Để tìm IP: Windows: ipconfig | Mac/Linux: ifconfig
  static const String serverIp = '192.168.1.100';
  
  /// Port của backend API local
  static const int serverPort = 5134;
  
  // ============================================
  // BASE URL - Tự động chọn dựa trên cấu hình
  // ============================================
  /// Base URL của API - tự động chọn dựa trên connectionMode và platform
  static String get baseUrl {
    // Nếu dùng ngrok, luôn dùng ngrok domain
    if (connectionMode == 'ngrok') {
      return '$ngrokProtocol://$ngrokDomain/api';
    }
    
    // Nếu dùng local, chọn dựa trên platform
    if (kIsWeb) {
      // Chạy trên Web (Chrome, Edge)
      return 'http://localhost:$serverPort/api';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      // Android: Chọn IP dựa trên cấu hình
      if (useEmulator) {
        // Android Emulator: 10.0.2.2 trỏ tới localhost của máy tính
        return 'http://10.0.2.2:$serverPort/api';
      } else {
        // Android thiết bị thật: dùng IP thật của máy tính
        return 'http://$serverIp:$serverPort/api';
      }
    } else {
      // Windows, macOS, Linux, iOS
      return 'http://localhost:$serverPort/api';
    }
  }
  
         // ============================================
         // TIMEOUT
         // ============================================
         /// Timeout cho các request (giây)
         static const int connectTimeout = 30; // Tăng timeout cho ngrok
         static const int receiveTimeout = 30;

         // ============================================
         // GOOGLE MAPS / PLACES API
         // ============================================
         /// Google Places API Key
         /// Lấy từ: https://console.cloud.google.com/apis/credentials
         /// Cần bật: Places API, Geocoding API
         static const String googlePlacesApiKey = 'YOUR_GOOGLE_PLACES_API_KEY_HERE';
       }

