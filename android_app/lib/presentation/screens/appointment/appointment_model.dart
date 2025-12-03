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

enum AppointmentStatus {
  pending,
  confirmed,
  completed,
  cancelled,
}

extension AppointmentStatusExtension on AppointmentStatus {
  String get displayName {
    switch (this) {
      case AppointmentStatus.pending:
        return 'Chờ xác nhận';
      case AppointmentStatus.confirmed:
        return 'Đã xác nhận';
      case AppointmentStatus.completed:
        return 'Đã xem';
      case AppointmentStatus.cancelled:
        return 'Đã hủy';
    }
  }

  Color get color {
    switch (this) {
      case AppointmentStatus.pending:
        return Colors.orange;
      case AppointmentStatus.confirmed:
        return Colors.green;
      case AppointmentStatus.completed:
        return Colors.blue;
      case AppointmentStatus.cancelled:
        return Colors.red;
    }
  }
}

