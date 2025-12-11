import 'package:intl/intl.dart';

import '../models/post_model.dart';

/// Các helper format cho giá, diện tích, thời gian
class Formatters {
  Formatters._();

  static final NumberFormat _decimalVi = NumberFormat.decimalPattern('vi_VN');

  static String formatArea(double area) {
    if (area == 0) return '—';
    return '${_decimalVi.format(area)} m²';
  }

  static String formatDate(DateTime date, {String pattern = 'dd/MM/yyyy'}) {
    return DateFormat(pattern, 'vi_VN').format(date);
  }

  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return 'Vừa đăng';
    if (difference.inHours < 1) return '${difference.inMinutes} phút trước';
    if (difference.inHours < 24) return '${difference.inHours} giờ trước';
    if (difference.inDays < 7) return '${difference.inDays} ngày trước';
    return formatDate(date);
  }

  static String formatPriceWithUnit(double price, PriceUnit unit) {
    switch (unit) {
      case PriceUnit.perM2:
        return '${_formatMillions(price)} /m²';
      case PriceUnit.perMonth:
        return '${_formatMillions(price)} /tháng';
      case PriceUnit.total:
        return _formatMillions(price);
    }
  }

  static String _formatMillions(double price) {
    if (price >= 1000) {
      final value = price / 1000;
      return '${_trimZero(value)} tỷ';
    }
    return '${_trimZero(price)} triệu';
  }

  static String _trimZero(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }
}
