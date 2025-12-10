import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../config/app_config.dart';
import '../services/auth_storage_service.dart';

class ApiClient {
  late final Dio _dio;
  String? _authToken;

  // Singleton instance
  static final ApiClient _instance = ApiClient._internal();
  
  factory ApiClient() {
    return _instance;
  }

  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: Duration(seconds: AppConfig.connectTimeout),
        receiveTimeout: Duration(seconds: AppConfig.receiveTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true', // Bỏ qua warning page của ngrok free tier
        },
      ),
    );

    // Thêm Interceptor để log request/response và thêm token
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // Thêm Authorization header nếu có token
        if (_authToken != null && _authToken!.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $_authToken';
        }
        debugPrint('[API Request] ${options.method} ${options.path}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        debugPrint('[API Response] ${response.statusCode} ${response.requestOptions.path}');
        return handler.next(response);
      },
      onError: (error, handler) {
        debugPrint('[API Error] ${error.response?.statusCode} ${error.requestOptions.path}');
        return handler.next(error);
      },
    ));

    // Log chi tiết trong debug mode
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (object) => debugPrint('[API] $object'),
    ));
  }

  Dio get dio => _dio;

  // Tải token từ secure storage (gọi từ main hoặc khi cần)
  Future<void> _loadTokenFromStorage() async {
    try {
      final token = await AuthStorageService.getToken();
      if (token != null && token.isNotEmpty) {
        _authToken = token;
        debugPrint('[ApiClient] Đã khôi phục token từ storage');
      }
    } catch (e) {
      debugPrint('[ApiClient] Lỗi khi load token từ storage: $e');
    }
  }

  // Khởi tạo và load token từ storage (gọi từ main)
  static Future<void> initialize() async {
    final instance = ApiClient();
    await instance._loadTokenFromStorage();
  }

  // Thiết lập token xác thực và lưu vào storage
  Future<void> setAuthToken(String? token) async {
    _authToken = token;
    if (token != null && token.isNotEmpty) {
      try {
        await AuthStorageService.saveToken(token);
        debugPrint('[ApiClient] Đã lưu token vào storage');
      } catch (e) {
        debugPrint('[ApiClient] Lỗi khi lưu token: $e');
      }
    } else {
      // Nếu token null, xóa khỏi storage
      await clearAuthToken();
    }
  }

  // Xóa token khi đăng xuất
  Future<void> clearAuthToken() async {
    _authToken = null;
    try {
      await AuthStorageService.deleteToken();
      debugPrint('[ApiClient] Đã xóa token khỏi storage');
    } catch (e) {
      debugPrint('[ApiClient] Lỗi khi xóa token: $e');
    }
  }

  // GET request wrapper
  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // POST request wrapper
  Future<dynamic> post(String path, {dynamic data}) async {
    try {
      final response = await _dio.post(path, data: data);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // PUT request wrapper
  Future<dynamic> put(String path, {dynamic data}) async {
    try {
      final response = await _dio.put(path, data: data);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // DELETE request wrapper
  Future<dynamic> delete(String path) async {
    try {
      final response = await _dio.delete(path);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException error) {
    String message = 'Đã xảy ra lỗi kết nối';
    if (error.response != null) {
      // Lấy message từ response nếu có
      final data = error.response?.data;
      if (data is String) {
        message = data;
      } else if (data is Map && data.containsKey('message')) {
        message = data['message'];
      } else {
        message = 'Lỗi server: ${error.response?.statusCode}';
      }
    } else if (error.type == DioExceptionType.connectionTimeout) {
      message = 'Kết nối quá hạn';
    } else if (error.type == DioExceptionType.connectionError) {
      message = 'Không thể kết nối tới server. Vui lòng kiểm tra kết nối mạng hoặc server.';
    }
    return Exception(message);
  }
}
