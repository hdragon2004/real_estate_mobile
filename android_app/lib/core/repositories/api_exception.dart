import 'package:dio/dio.dart';
import 'api_response.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final dynamic originalError;

  ApiException({
    required this.statusCode,
    required this.message,
    this.originalError,
  });

  factory ApiException.fromDioException(dynamic error) {
    if (error is DioException) {
      int statusCode = error.response?.statusCode ?? 0;
      String message = 'Đã xảy ra lỗi kết nối';

      if (error.response?.data != null) {
        final data = error.response!.data;
        if (data is Map<String, dynamic>) {
          if (data.containsKey('message')) {
            message = data['message'] as String? ?? message;
            statusCode = data['status'] as int? ?? statusCode;
          }
        } else if (data is String) {
          message = data;
        }
      }

      if (error.type == DioExceptionType.connectionTimeout) {
        message = 'Kết nối quá hạn. Vui lòng thử lại.';
      } else if (error.type == DioExceptionType.connectionError) {
        message = 'Không thể kết nối tới server. Vui lòng kiểm tra kết nối mạng.';
      } else if (error.type == DioExceptionType.receiveTimeout) {
        message = 'Nhận dữ liệu quá hạn. Vui lòng thử lại.';
      } else if (error.type == DioExceptionType.sendTimeout) {
        message = 'Gửi dữ liệu quá hạn. Vui lòng thử lại.';
      }

      return ApiException(
        statusCode: statusCode,
        message: message,
        originalError: error,
      );
    }

    return ApiException(
      statusCode: 0,
      message: error.toString(),
      originalError: error,
    );
  }

  factory ApiException.fromApiResponse(ApiResponse response) {
    return ApiException(
      statusCode: response.status,
      message: response.message.isNotEmpty
          ? response.message
          : 'Đã xảy ra lỗi không xác định',
    );
  }

  @override
  String toString() {
    return 'ApiException{statusCode: $statusCode, message: $message}';
  }
}

