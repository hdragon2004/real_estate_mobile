import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Cấu hình kết nối Backend API
/// Đọc từ file .env
class AppConfig {
  // ============================================
  // CẤU HÌNH THIẾT BỊ - CHUYỂN ĐỔI DỄ DÀNG
  // ============================================
  /// Chọn thiết bị đang chạy app:
  /// - true: Chạy trên Android Emulator (máy ảo)
  /// - false: Chạy trên điện thoại thật
  /// 
  /// Lưu ý: Chỉ ảnh hưởng khi connectionMode = 'local'
  /// Khi dùng ngrok, cấu hình này không cần thiết
  static bool get useEmulator => dotenv.get('USE_EMULATOR', fallback: 'false') == 'true';
  
  // ============================================
  // CẤU HÌNH KẾT NỐI BACKEND
  // ============================================
  /// Chế độ kết nối: 'ngrok' hoặc 'local'
  /// - 'ngrok': Sử dụng ngrok tunnel (không cần đổi IP mỗi lần build)
  /// - 'local': Sử dụng IP local (cần đổi IP khi chuyển mạng)
  static String get connectionMode => dotenv.get('CONNECTION_MODE', fallback: 'ngrok');
  
  // ============================================
  // CẤU HÌNH NGROK (khi connectionMode = 'ngrok')
  // ============================================
  /// Ngrok domain từ file ngrok.yml
  /// Domain này tương ứng với tunnel có addr: 5134 (android-api)
  static String get ngrokDomain => dotenv.get('NGROK_DOMAIN');
  
  /// Protocol cho ngrok (http hoặc https)
  static String get ngrokProtocol => dotenv.get('NGROK_PROTOCOL');
  
  // ============================================
  // CẤU HÌNH LOCAL (khi connectionMode = 'local')
  // ============================================
  /// IP của máy tính chạy backend (chỉ dùng khi connectionMode = 'local' và useEmulator = false)
  /// Để tìm IP: Windows: ipconfig | Mac/Linux: ifconfig
  /// Lưu ý: IP này chỉ cần khi chạy trên điện thoại thật
  static String get serverIp => dotenv.get('SERVER_IP', fallback: '192.168.1.100');
  
  /// Port của backend API local
  static int get serverPort => int.tryParse(dotenv.get('SERVER_PORT', fallback: '5134')) ?? 5134;
  
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
  static int get connectTimeout => int.tryParse(dotenv.get('CONNECT_TIMEOUT', fallback: '30')) ?? 30;
  static int get receiveTimeout => int.tryParse(dotenv.get('RECEIVE_TIMEOUT', fallback: '30')) ?? 30;
}

