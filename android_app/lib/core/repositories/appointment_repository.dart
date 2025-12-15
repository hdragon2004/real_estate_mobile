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
    final body = <String, dynamic>{
      'title': title,
      'appointmentTime': startTime.toUtc().toIso8601String(),
      'reminderMinutes': reminderMinutes,
    };

    if (description != null && description.trim().isNotEmpty) {
      body['description'] = description.trim();
    }

    if (location != null && location.isNotEmpty) {
      body['location'] = location;
    }

    if (attendeeEmails != null && attendeeEmails.isNotEmpty) {
      body['attendeeEmails'] = attendeeEmails.join(', ');
    }

    if (propertyId != null) {
      body['propertyId'] = propertyId;
    }

    final response = await _apiClient.post(
      ApiConstants.appointments,
      data: body,
    );

    if (response is Map<String, dynamic>) {
      return response;
    }

    throw Exception('Unexpected response when creating appointment');
  }
}
