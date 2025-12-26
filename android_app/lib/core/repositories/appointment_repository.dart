import '../constants/api_constants.dart';
import '../utils/datetime_helper.dart';
import 'base_repository.dart';
import 'api_response.dart';

class AppointmentRepository extends BaseRepository {
  /// Tạo appointment mới
  Future<ApiResponse<Map<String, dynamic>>> createAppointment({
    required String title,
    required DateTime startTime,
    required int reminderMinutes,
    String? description,
    String? location,
    List<String>? attendeeEmails,
    int? propertyId,
  }) async {
    if (propertyId == null || propertyId == 0) {
      throw Exception('PostId is required');
    }

    final body = <String, dynamic>{
      'PostId': propertyId,
      'Title': title,
      // Sử dụng DateTimeHelper để đảm bảo timezone đúng (Vietnam GMT+7)
      'AppointmentTime': DateTimeHelper.toIso8601String(startTime),
      'ReminderMinutes': reminderMinutes,
    };

    if (description != null && description.trim().isNotEmpty) {
      body['Description'] = description.trim();
    }

    return await handleRequestWithResponse<Map<String, dynamic>>(
      request: () => apiClient.post(
        ApiConstants.appointments,
        data: body,
      ),
      fromJson: (json) => Map<String, dynamic>.from(json),
    );
  }

  /// Lấy danh sách appointments của user
  Future<ApiResponse<List<Map<String, dynamic>>>> getUserAppointments() async {
    return await handleRequestListWithResponse<Map<String, dynamic>>(
      request: () => apiClient.get(ApiConstants.appointmentsMe),
      fromJson: (json) => Map<String, dynamic>.from(json),
    );
  }

  /// Lấy danh sách appointments cho posts của user
  Future<ApiResponse<List<Map<String, dynamic>>>> getAllAppointmentsForMyPosts() async {
    return await handleRequestListWithResponse<Map<String, dynamic>>(
      request: () => apiClient.get(ApiConstants.appointmentsForMyPosts),
      fromJson: (json) => Map<String, dynamic>.from(json),
    );
  }

  /// Xác nhận appointment
  Future<ApiResponse<Map<String, dynamic>>> confirmAppointment(int appointmentId) async {
    return await handleRequestWithResponse<Map<String, dynamic>>(
      request: () => apiClient.put('${ApiConstants.appointments}/$appointmentId/confirm'),
      fromJson: (json) => Map<String, dynamic>.from(json),
    );
  }

  /// Từ chối appointment
  Future<ApiResponse<Map<String, dynamic>>> rejectAppointment(int appointmentId) async {
    return await handleRequestWithResponse<Map<String, dynamic>>(
      request: () => apiClient.put('${ApiConstants.appointments}/$appointmentId/reject'),
      fromJson: (json) => Map<String, dynamic>.from(json),
    );
  }
}
