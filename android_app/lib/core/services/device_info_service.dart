import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart';

/// Service lấy thông tin ứng dụng
class DeviceInfoService {
  /// Lấy thông tin ứng dụng
  static Future<PackageInfo?> getAppInfo() async {
    try {
      return await PackageInfo.fromPlatform();
    } catch (e) {
      debugPrint('Error getting app info: $e');
      return null;
    }
  }

  /// Lấy thông tin ứng dụng dạng string
  static Future<String> getAppInfoString() async {
    final appInfo = await getAppInfo();
    if (appInfo != null) {
      return '${appInfo.appName} v${appInfo.version} (${appInfo.buildNumber})';
    }
    return 'Unknown App';
  }

  /// Lấy thông tin ứng dụng đầy đủ dạng Map
  static Future<Map<String, dynamic>> getFullDeviceInfo() async {
    final Map<String, dynamic> info = {};

    // Thông tin ứng dụng
    final appInfo = await getAppInfo();
    if (appInfo != null) {
      info['app'] = {
        'appName': appInfo.appName,
        'packageName': appInfo.packageName,
        'version': appInfo.version,
        'buildNumber': appInfo.buildNumber,
        'buildSignature': appInfo.buildSignature,
      };
    }

    // Platform info
    info['platform'] = defaultTargetPlatform.toString();

    return info;
  }

  /// Lấy tên thiết bị (chỉ trả về platform vì không có device info)
  static Future<String> getDeviceName() async {
    return defaultTargetPlatform.toString().replaceAll('TargetPlatform.', '');
  }

  /// Lấy phiên bản hệ điều hành (chỉ trả về platform)
  static Future<String> getOSVersion() async {
    return defaultTargetPlatform.toString().replaceAll('TargetPlatform.', '');
  }

  /// Kiểm tra có phải thiết bị thật không (luôn trả về true vì không có thông tin)
  static Future<bool> isPhysicalDevice() async {
    return true;
  }

  /// Lấy thông tin mạng WiFi (trả về empty vì không có thông tin)
  static Future<Map<String, String?>> getWiFiInfo() async {
    return {};
  }
}
