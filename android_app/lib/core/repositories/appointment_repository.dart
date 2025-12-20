import '../constants/api_constants.dart';
import '../network/api_client.dart';

class AppointmentRepository {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> createAppointment({
    required String title,
    required DateTime startTime,
    required int reminderMinutes,
    String? description,
    String? location,
    List<String>? attendeeEmails,
    int? propertyId,
  }) async {
    // Backend mong đợi PostId (PascalCase) và nó là required
    if (propertyId == null || propertyId == 0) {
      throw Exception('PostId is required');
    }

    final body = <String, dynamic>{
      'PostId': propertyId, // Backend mong đợi PostId (PascalCase)
      'Title': title,
      // Gửi local time (không convert sang UTC) để lưu đúng giờ user chọn
      'AppointmentTime': startTime.toIso8601String(),
      'ReminderMinutes': reminderMinutes,
    };

    if (description != null && description.trim().isNotEmpty) {
      body['Description'] = description.trim();
    }

    // Backend không có Location và AttendeeEmails trong CreateAppointmentDto
    // Nên không gửi các field này

    final response = await _apiClient.post(
      ApiConstants.appointments,
      data: body,
    );

    if (response is Map<String, dynamic>) {
      return response;
    }

    throw Exception('Unexpected response when creating appointment');
  }

  Future<List<Map<String, dynamic>>> getUserAppointments() async {
    final response = await _apiClient.get(ApiConstants.appointmentsMe);

    if (response is List) {
      return response.cast<Map<String, dynamic>>();
    }

    throw Exception('Unexpected response when fetching appointments');
  }

  Future<List<Map<String, dynamic>>> getAllAppointmentsForMyPosts() async {
    final response = await _apiClient.get(ApiConstants.appointmentsForMyPosts);

    if (response is List) {
      return response.cast<Map<String, dynamic>>();
    }

    throw Exception('Unexpected response when fetching appointments for my posts');
  }

  Future<Map<String, dynamic>> confirmAppointment(int appointmentId) async {
    // Backend sử dụng HttpPut và trả về 204 NoContent khi thành công
    final response = await _apiClient.put(
      '${ApiConstants.appointments}/$appointmentId/confirm',
    );

    // Backend trả về NoContent (204) nên response có thể null hoặc empty
    // Trả về map rỗng để indicate success
    return response is Map<String, dynamic> ? response : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> rejectAppointment(int appointmentId) async {
    // Backend sử dụng HttpPut và trả về 204 NoContent khi thành công
    final response = await _apiClient.put(
      '${ApiConstants.appointments}/$appointmentId/reject',
    );

    // Backend trả về NoContent (204) nên response có thể null hoặc empty
    // Trả về map rỗng để indicate success
    return response is Map<String, dynamic> ? response : <String, dynamic>{};
  }
}
