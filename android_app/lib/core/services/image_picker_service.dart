import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'permission_service.dart';

/// Service xử lý chọn và chụp ảnh
class ImagePickerService {
  static final ImagePicker _picker = ImagePicker();

  /// Chụp ảnh từ camera
  /// Trả về File ảnh hoặc null nếu bị hủy/lỗi
  static Future<File?> takePicture(BuildContext context) async {
    // Kiểm tra và yêu cầu quyền camera
    final hasPermission =
        await PermissionService.requestCameraPermission(context);
    if (!hasPermission) {
      return null;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85, // Chất lượng ảnh (0-100)
        maxWidth: 1920,   // Giới hạn kích thước
        maxHeight: 1920,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error taking picture: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi chụp ảnh: $e')),
        );
      }
      return null;
    }
  }

  /// Chọn 1 ảnh từ thư viện
  /// Trả về File ảnh hoặc null nếu bị hủy/lỗi
  static Future<File?> pickImageFromGallery(BuildContext context) async {
    // Kiểm tra và yêu cầu quyền thư viện ảnh
    final hasPermission =
        await PermissionService.requestPhotoLibraryPermission(context);
    if (!hasPermission) {
      return null;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi chọn ảnh: $e')),
        );
      }
      return null;
    }
  }

  /// Hiển thị bottom sheet cho phép chọn nguồn ảnh: camera hoặc thư viện
  /// Trả về File ảnh hoặc null nếu hủy
  static Future<File?> showImageSourceDialog(BuildContext context) async {
    // Hỏi người dùng muốn lấy từ nguồn nào
    final ImageSource? source =
        await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Chụp ảnh'),
                onTap: () {
                  Navigator.of(sheetContext).pop(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Chọn từ thư viện'),
                onTap: () {
                  Navigator.of(sheetContext).pop(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('Hủy'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                },
              ),
            ],
          ),
        );
      },
    );

    // Người dùng hủy
    if (source == null) return null;

    // Sau khi bottom sheet đóng, mới thực hiện hành động tương ứng
    if (!context.mounted) {
      return null;
    }
    if (source == ImageSource.camera) {
      return await takePicture(context);
    } else {
      return await pickImageFromGallery(context);
    }
  }

  /// Chọn nhiều ảnh từ thư viện
  /// [maxImages]: số ảnh tối đa cho phép (mặc định 10)
  /// Trả về danh sách File ảnh (có thể rỗng)
  static Future<List<File>> pickMultipleImagesFromGallery(
    BuildContext context, {
    int maxImages = 10,
  }) async {
    final hasPermission =
        await PermissionService.requestPhotoLibraryPermission(context);
    if (!hasPermission) {
      return [];
    }

    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (images.isEmpty) return [];

      // Giới hạn số lượng ảnh theo maxImages
      final limitedImages = images.take(maxImages).toList();

      return limitedImages.map((xFile) => File(xFile.path)).toList();
    } catch (e) {
      debugPrint('Error picking multiple images: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi chọn ảnh: $e')),
        );
      }
      return [];
    }
  }
}
