import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

/// Service xử lý quyền truy cập thiết bị
class PermissionService {
  /// Kiểm tra và yêu cầu quyền camera
  /// Trả về true nếu được cấp quyền, false nếu bị từ chối
  static Future<bool> requestCameraPermission(BuildContext context) async {
    final status = await Permission.camera.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      final result = await Permission.camera.request();
      if (result.isGranted) {
        return true;
      } else if (result.isPermanentlyDenied) {
        if (context.mounted) {
          await _showPermissionDeniedDialog(
            context,
            'Quyền truy cập camera',
            'Ứng dụng cần quyền truy cập camera để chụp ảnh. Vui lòng cấp quyền trong Cài đặt.',
          );
        }
        return false;
      }
      return false;
    }

    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        await _showPermissionDeniedDialog(
          context,
          'Quyền truy cập camera',
          'Ứng dụng cần quyền truy cập camera để chụp ảnh. Vui lòng cấp quyền trong Cài đặt.',
        );
      }
      return false;
    }

    return false;
  }

  /// Kiểm tra và yêu cầu quyền truy cập thư viện ảnh
  static Future<bool> requestPhotoLibraryPermission(BuildContext context) async {
    // Android 13+ (API 33+) sử dụng Permission.photos
    // Android < 13 sử dụng Permission.storage
    try {
      // Thử dùng photos permission trước (Android 13+)
      final photosStatus = await Permission.photos.status;
      if (photosStatus.isGranted) {
        return true;
      }
      
      if (photosStatus.isDenied) {
        final result = await Permission.photos.request();
        if (result.isGranted) {
          return true;
        } else if (result.isPermanentlyDenied) {
          if (context.mounted) {
            await _showPermissionDeniedDialog(
              context,
              'Quyền truy cập thư viện ảnh',
              'Ứng dụng cần quyền truy cập thư viện ảnh để chọn ảnh. Vui lòng cấp quyền trong Cài đặt.',
            );
          }
          return false;
        }
      }
      
      // Fallback cho Android < 13
      final storageStatus = await Permission.storage.status;
      if (storageStatus.isGranted) {
        return true;
      }
      
      if (storageStatus.isDenied) {
        final result = await Permission.storage.request();
        if (result.isGranted) {
          return true;
        } else if (result.isPermanentlyDenied) {
          if (context.mounted) {
            await _showPermissionDeniedDialog(
              context,
              'Quyền truy cập thư viện ảnh',
              'Ứng dụng cần quyền truy cập thư viện ảnh để chọn ảnh. Vui lòng cấp quyền trong Cài đặt.',
            );
          }
          return false;
        }
      }
      
      return false;
    } catch (e) {
      // Nếu có lỗi, thử dùng storage permission
      try {
        final storageStatus = await Permission.storage.status;
        if (storageStatus.isGranted) {
          return true;
        }
        final result = await Permission.storage.request();
        return result.isGranted;
      } catch (_) {
        return false;
      }
    }
  }

  /// Kiểm tra và yêu cầu quyền truy cập vị trí
  static Future<bool> requestLocationPermission(BuildContext context) async {
    final status = await Permission.location.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      final result = await Permission.location.request();
      if (result.isGranted) {
        return true;
      } else if (result.isPermanentlyDenied) {
        if (context.mounted) {
          await _showPermissionDeniedDialog(
            context,
            'Quyền truy cập vị trí',
            'Ứng dụng cần quyền truy cập vị trí để hiển thị bản đồ. Vui lòng cấp quyền trong Cài đặt.',
          );
        }
        return false;
      }
      return false;
    }

    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        await _showPermissionDeniedDialog(
          context,
          'Quyền truy cập vị trí',
          'Ứng dụng cần quyền truy cập vị trí để hiển thị bản đồ. Vui lòng cấp quyền trong Cài đặt.',
        );
      }
      return false;
    }

    return false;
  }

  /// Kiểm tra và yêu cầu quyền lưu trữ (Storage)
  static Future<bool> requestStoragePermission(BuildContext context) async {
    // Android 13+ sử dụng photos permission
    if (await Permission.photos.isGranted) {
      return true;
    }

    // Android < 13 sử dụng storage permission
    final status = await Permission.storage.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      final result = await Permission.storage.request();
      if (result.isGranted) {
        return true;
      } else if (result.isPermanentlyDenied) {
        if (context.mounted) {
          await _showPermissionDeniedDialog(
            context,
            'Quyền truy cập lưu trữ',
            'Ứng dụng cần quyền truy cập lưu trữ để lưu ảnh. Vui lòng cấp quyền trong Cài đặt.',
          );
        }
        return false;
      }
      return false;
    }

    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        await _showPermissionDeniedDialog(
          context,
          'Quyền truy cập lưu trữ',
          'Ứng dụng cần quyền truy cập lưu trữ để lưu ảnh. Vui lòng cấp quyền trong Cài đặt.',
        );
      }
      return false;
    }

    return false;
  }

  /// Hiển thị dialog khi quyền bị từ chối vĩnh viễn
  static Future<void> _showPermissionDeniedDialog(
    BuildContext context,
    String title,
    String message,
  ) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Mở Cài đặt'),
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
            ),
          ],
        );
      },
    );
  }

  /// Kiểm tra quyền camera đã được cấp chưa (không yêu cầu)
  static Future<bool> isCameraPermissionGranted() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  /// Kiểm tra quyền thư viện ảnh đã được cấp chưa (không yêu cầu)
  static Future<bool> isPhotoLibraryPermissionGranted() async {
    final status = await Permission.photos.status;
    return status.isGranted;
  }

  /// Kiểm tra quyền vị trí đã được cấp chưa (không yêu cầu)
  static Future<bool> isLocationPermissionGranted() async {
    final status = await Permission.location.status;
    return status.isGranted;
  }
}

