import '../network/api_client.dart';
import '../constants/api_constants.dart';

class AppointmentRepository {
  final ApiClient _apiClient = ApiClient();

  /// Tạo appointment mới
  Future<Map<String, dynamic>> createAppointment({
    required int postId,
    required String title,
    String? description,
    required DateTime appointmentTime,
    required int reminderMinutes,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.appointments,
        data: {
          'postId': postId,
          'title': title,
          'description': description,
          'appointmentTime': appointmentTime.toUtc().toIso8601String(),
          'reminderMinutes': reminderMinutes,
        },
      );
      return response as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// Lấy danh sách appointments của user hiện tại
  Future<List<Map<String, dynamic>>> getUserAppointments() async {
    try {
      final response = await _apiClient.get('${ApiConstants.appointments}/me');
      
      if (response is List) {
        return response.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Hủy appointment
  Future<void> cancelAppointment(int appointmentId) async {
    try {
      await _apiClient.put('${ApiConstants.appointments}/$appointmentId/cancel');
    } catch (e) {
      rethrow;
    }
  }

  /// Lấy danh sách appointments đang chờ chấp nhận (cho chủ bài post)
  Future<List<Map<String, dynamic>>> getPendingAppointments() async {
    try {
      final response = await _apiClient.get('${ApiConstants.appointments}/pending');
      
      if (response is List) {
        return response.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Chấp nhận appointment
  Future<void> confirmAppointment(int appointmentId) async {
    try {
      await _apiClient.put('${ApiConstants.appointments}/$appointmentId/confirm');
    } catch (e) {
      rethrow;
    }
  }

  /// Từ chối appointment
  Future<void> rejectAppointment(int appointmentId) async {
    try {
      await _apiClient.put('${ApiConstants.appointments}/$appointmentId/reject');
    } catch (e) {
      rethrow;
    }
  }
}

