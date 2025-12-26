import '../repositories/api_response.dart';
import '../repositories/api_exception.dart';

abstract class BaseService {
  /// Unwrap ApiResponse và throw exception nếu có lỗi
  /// Trả về data nếu thành công
  /// [allowNullData]: Cho phép data null (ví dụ: delete API trả success nhưng data=null)
  T unwrapResponse<T>(ApiResponse<T> response, {bool allowNullData = false}) {
    if (!response.isSuccess) {
      final error = ApiException(
        statusCode: response.status,
        message: response.message,
      );
      handleError(error);
      throw error;
    }
    
    if (!allowNullData && response.data == null) {
      final error = ApiException(
        statusCode: response.status,
        message: response.message.isNotEmpty 
            ? response.message 
            : 'Không nhận được dữ liệu từ server',
      );
      handleError(error);
      throw error;
    }
    
    return response.data as T;
  }

  /// Unwrap ApiResponse[List] và throw exception nếu có lỗi
  /// Trả về List nếu thành công (có thể là empty list)
  List<T> unwrapListResponse<T>(ApiResponse<List<T>> response) {
    if (!response.isSuccess) {
      final error = ApiException(
        statusCode: response.status,
        message: response.message,
      );
      handleError(error);
      throw error;
    }
    
    return response.data ?? [];
  }

  void handleError(ApiException error) {
    // Override trong service con để xử lý lỗi cụ thể
  }

  /// Wrapper để xử lý API call với error handling tập trung
  /// Tự động catch ApiException và gọi handleError
  Future<T> safeApiCall<T>(Future<T> Function() apiCall) async {
    try {
      return await apiCall();
    } on ApiException catch (e) {
      handleError(e);
      rethrow;
    } catch (e) {
      final error = ApiException(
        statusCode: 0,
        message: 'Lỗi không xác định: ${e.toString()}',
        originalError: e,
      );
      handleError(error);
      throw error;
    }
  }

  /// Wrapper để xử lý local operations (không phải API) với error handling tập trung
  /// Tự động convert lỗi thành ApiException và gọi handleError
  /// [rethrowOriginal]: Nếu true, throw lại original error thay vì ApiException (để phân biệt business error và system error)
  Future<T> safeLocalCall<T>(
    Future<T> Function() localCall, {
    bool rethrowOriginal = false,
  }) async {
    try {
      return await localCall();
    } catch (e) {
      if (rethrowOriginal && e is! ApiException) {
        // Rethrow original error để phân biệt business error và system error
        handleError(ApiException(
          statusCode: 0,
          message: e.toString(),
          originalError: e,
        ));
        rethrow;
      }
      
      final error = ApiException(
        statusCode: 0,
        message: e.toString(),
        originalError: e,
      );
      handleError(error);
      throw error;
    }
  }
}
