import 'package:flutter/material.dart';

/// Model cho Appointment
class AppointmentModel {
  final String id;
  final String propertyId;
  final String propertyTitle;
  final String? propertyImage;
  final DateTime scheduledDate;
  final String scheduledTime;
  final String? notes;
  final AppointmentStatus status;
  final String ownerName;
  final String? ownerPhone;
  final String? ownerEmail;

  AppointmentModel({
    required this.id,
    required this.propertyId,
    required this.propertyTitle,
    this.propertyImage,
    required this.scheduledDate,
    required this.scheduledTime,
    this.notes,
    required this.status,
    required this.ownerName,
    this.ownerPhone,
    this.ownerEmail,
  });
}

/// Enum trạng thái lịch hẹn - phù hợp với backend
enum AppointmentStatus {
  pending,   // PENDING = 0 - Chờ xác nhận
  accepted,  // ACCEPTED = 1 - Đã chấp nhận
  rejected,  // REJECTED = 2 - Bị từ chối
}

extension AppointmentStatusExtension on AppointmentStatus {
  String get displayName {
    switch (this) {
      case AppointmentStatus.pending:
        return 'Chờ xác nhận';
      case AppointmentStatus.accepted:
        return 'Đã chấp nhận';
      case AppointmentStatus.rejected:
        return 'Bị từ chối';
    }
  }

  Color get color {
    switch (this) {
      case AppointmentStatus.pending:
        return Colors.orange;
      case AppointmentStatus.accepted:
        return Colors.green;
      case AppointmentStatus.rejected:
        return Colors.red;
    }
  }

  /// Convert từ string (từ API) sang enum
  static AppointmentStatus fromString(String? status) {
    if (status == null) return AppointmentStatus.pending;
    
    switch (status.toUpperCase()) {
      case 'PENDING':
        return AppointmentStatus.pending;
      case 'ACCEPTED':
        return AppointmentStatus.accepted;
      case 'REJECTED':
        return AppointmentStatus.rejected;
      default:
        return AppointmentStatus.pending;
    }
  }

  /// Convert từ int (enum value từ API) sang enum
  static AppointmentStatus fromInt(int? status) {
    if (status == null) return AppointmentStatus.pending;
    
    switch (status) {
      case 0:
        return AppointmentStatus.pending;
      case 1:
        return AppointmentStatus.accepted;
      case 2:
        return AppointmentStatus.rejected;
      default:
        return AppointmentStatus.pending;
    }
  }

  /// Convert sang string để gửi lên API
  String toApiString() {
    switch (this) {
      case AppointmentStatus.pending:
        return 'PENDING';
      case AppointmentStatus.accepted:
        return 'ACCEPTED';
      case AppointmentStatus.rejected:
        return 'REJECTED';
    }
  }

  /// Convert sang int để gửi lên API
  int toApiInt() {
    switch (this) {
      case AppointmentStatus.pending:
        return 0;
      case AppointmentStatus.accepted:
        return 1;
      case AppointmentStatus.rejected:
        return 2;
    }
  }
}

