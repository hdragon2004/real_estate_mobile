import '../constants/api_constants.dart';
import '../network/api_client.dart';

class AppointmentRepository {
  final ApiClient _apiClient = ApiClient();

<<<<<<< HEAD
<<<<<<< HEAD
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

  /// Lấy TẤT CẢ appointments cho các bài post của user hiện tại (cho chủ bài post)
  Future<List<Map<String, dynamic>>> getAllAppointmentsForMyPosts() async {
    try {
      final response = await _apiClient.get('${ApiConstants.appointments}/for-my-posts');
      
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

  /// Lấy chi tiết appointment theo ID
  Future<Map<String, dynamic>> getAppointmentById(int appointmentId) async {
    try {
      final response = await _apiClient.get('${ApiConstants.appointments}/$appointmentId');
      return response as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }
}

=======
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
>>>>>>> 0da2ee6bd5ecda35da33cee30388a45e96185811
