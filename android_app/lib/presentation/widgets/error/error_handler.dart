import 'package:flutter/material.dart';
import '../../../core/repositories/api_exception.dart';
import '../../../core/theme/app_colors.dart';

/// Helper để hiển thị lỗi tập trung cho người dùng
class ErrorHandler {
  ErrorHandler._();

  /// Hiển thị lỗi dưới dạng SnackBar
  /// [context]: BuildContext để hiển thị SnackBar
  /// [error]: ApiException hoặc Exception
  /// [duration]: Thời gian hiển thị (mặc định 4 giây)
  static void showError(
    BuildContext context,
    dynamic error, {
    Duration duration = const Duration(seconds: 4),
  }) {
    if (!context.mounted) return;

    String message = _getErrorMessage(error);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Hiển thị lỗi dưới dạng Dialog (cho lỗi nghiêm trọng)
  /// [context]: BuildContext để hiển thị Dialog
  /// [error]: ApiException hoặc Exception
  /// [title]: Tiêu đề dialog (mặc định "Lỗi")
  static Future<void> showErrorDialog(
    BuildContext context,
    dynamic error, {
    String title = 'Lỗi',
  }) async {
    if (!context.mounted) return;

    String message = _getErrorMessage(error);

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(message),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  /// Lấy message từ error
  static String _getErrorMessage(dynamic error) {
    if (error is ApiException) {
      return error.message.isNotEmpty
          ? error.message
          : 'Đã xảy ra lỗi không xác định';
    } else if (error is Exception) {
      return error.toString().replaceFirst('Exception: ', '');
    } else {
      return error.toString();
    }
  }

  /// Hiển thị lỗi từ error stream (dùng trong StreamBuilder)
  static Widget buildErrorWidget(dynamic error) {
    String message = _getErrorMessage(error);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

