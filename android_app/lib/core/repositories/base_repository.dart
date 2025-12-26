import 'package:dio/dio.dart';
import '../network/api_client.dart';
import 'api_exception.dart';
import 'api_response.dart';

abstract class BaseRepository {
  final ApiClient _apiClient = ApiClient();

  ApiClient get apiClient => _apiClient;
  
  /// Xử lý response
  Future<T> handleRequest<T>({
    required Future<dynamic> Function() request,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    try {
      final response = await request();
      
      // Nếu response đã là ApiResponse format (có status, message, data)
      if (response is Map<String, dynamic> && 
          response.containsKey('status') && 
          response.containsKey('message')) {
        final status = response['status'] as int? ?? 0;
        final message = response['message'] as String? ?? '';
        final data = response['data'];
        
        // Nếu lỗi, throw exception
        if (status < 200 || status >= 300) {
          throw ApiException(
            statusCode: status,
            message: message.isNotEmpty ? message : 'Đã xảy ra lỗi',
          );
        }
        
        // Parse data
        if (data != null) {
          if (data is Map<String, dynamic>) {
            return fromJson(data);
          }
          // Nếu data không phải Map, có thể là primitive type
          // Giữ nguyên nếu T là dynamic hoặc primitive
          if (T == dynamic || data is T) {
            return data as T;
          }
        }
        
        // Nếu không có data nhưng status thành công
        throw ApiException(
          statusCode: status,
          message: message.isNotEmpty ? message : 'Không nhận được dữ liệu từ server',
        );
      }
      
      // Nếu response là data trực tiếp (không có wrapper)
      if (response is Map<String, dynamic>) {
        return fromJson(response);
      }
      
      // Nếu response là List, lấy phần tử đầu tiên
      if (response is List && response.isNotEmpty) {
        final firstItem = response[0] as Map<String, dynamic>;
        return fromJson(firstItem);
      }
      
      // Nếu không có data
      throw ApiException(
        statusCode: 0,
        message: 'Response không hợp lệ hoặc không có dữ liệu',
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      // Nếu đã là ApiException, rethrow
      if (e is ApiException) rethrow;
      
      throw ApiException(
        statusCode: 0,
        message: 'Lỗi không xác định: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Xử lý response list
  Future<List<T>> handleRequestList<T>({
    required Future<dynamic> Function() request,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    try {
      final response = await request();
      
      // Nếu response đã là ApiResponse format
      if (response is Map<String, dynamic> && 
          response.containsKey('status') && 
          response.containsKey('message')) {
        final status = response['status'] as int? ?? 0;
        final message = response['message'] as String? ?? '';
        final data = response['data'];
        
        // Nếu lỗi, throw exception
        if (status < 200 || status >= 300) {
          throw ApiException(
            statusCode: status,
            message: message.isNotEmpty ? message : 'Đã xảy ra lỗi',
          );
        }
        
        // Parse data thành List
        if (data is List) {
          return data
              .map((e) => fromJson(e as Map<String, dynamic>))
              .toList();
        } else if (data is Map<String, dynamic>) {
          // Nếu là object đơn, convert thành List có 1 phần tử
          return [fromJson(data)];
        }
        
        // Nếu không có data, trả về empty list
        return [];
      }
      
      // Nếu response là List trực tiếp
      if (response is List) {
        return response
            .map((e) => fromJson(e as Map<String, dynamic>))
            .toList();
      }
      
      // Nếu response là object đơn, convert thành List có 1 phần tử
      if (response is Map<String, dynamic>) {
        return [fromJson(response)];
      }
      
      // Nếu không có data, trả về empty list
      return [];
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      // Nếu đã là ApiException, rethrow
      if (e is ApiException) rethrow;
      
      throw ApiException(
        statusCode: 0,
        message: 'Lỗi không xác định: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Xử lý response void
  Future<void> handleVoidRequest({
    required Future<dynamic> Function() request,
  }) async {
    try {
      final response = await request();
      
      // Nếu response có format ApiResponse, check status
      if (response is Map<String, dynamic> && 
          response.containsKey('status') && 
          response.containsKey('message')) {
        final status = response['status'] as int? ?? 0;
        final message = response['message'] as String? ?? '';
        
        if (status < 200 || status >= 300) {
          throw ApiException(
            statusCode: status,
            message: message.isNotEmpty ? message : 'Đã xảy ra lỗi',
          );
        }
      }
      
      // Nếu không có lỗi, return void
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      // Nếu đã là ApiException, rethrow
      if (e is ApiException) rethrow;
      
      throw ApiException(
        statusCode: 0,
        message: 'Lỗi không xác định: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Repository trả về ApiResponse (chuẩn - Repository biết API format)
  Future<ApiResponse<T>> handleRequestWithResponse<T>({
    required Future<dynamic> Function() request,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    try {
      final response = await request();
      
      if (response is Map<String, dynamic> && 
          response.containsKey('status') && 
          response.containsKey('message')) {
        return ApiResponse.fromJson(
          response,
          fromJson,
        );
      }
      
      throw ApiException(
        statusCode: 0,
        message: 'Response không hợp lệ',
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        statusCode: 0,
        message: 'Lỗi không xác định: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Repository trả về ApiResponse cho List (chuẩn - Repository biết API format)
  Future<ApiResponse<List<T>>> handleRequestListWithResponse<T>({
    required Future<dynamic> Function() request,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    try {
      final response = await request();
      
      if (response is Map<String, dynamic> && 
          response.containsKey('status') && 
          response.containsKey('message')) {
        return ApiResponse.fromJsonList(
          response,
          fromJson,
        );
      }
      
      throw ApiException(
        statusCode: 0,
        message: 'Response không hợp lệ',
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        statusCode: 0,
        message: 'Lỗi không xác định: ${e.toString()}',
        originalError: e,
      );
    }
  }
}
