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


  static String formatCurrency(double amount) {
    if (amount >= 1000000000) {
      // >= 1 tỷ
      return '${(amount / 1000000000).toStringAsFixed(1).replaceAll(RegExp(r'\.?0+$'), '')} tỷ';
    } else if (amount >= 1000000) {
      // >= 1 triệu
      return '${(amount / 1000000).toStringAsFixed(1).replaceAll(RegExp(r'\.?0+$'), '')} triệu';
    } else if (amount >= 1000) {
      // >= 1 nghìn
      return '${(amount / 1000).toStringAsFixed(1).replaceAll(RegExp(r'\.?0+$'), '')} nghìn';
    } else {
      return amount.toStringAsFixed(0);
    }
  }

  /// Format số tiền với đơn vị VNĐ
  static String formatCurrencyWithUnit(double amount) {
    return '${formatCurrency(amount)} VNĐ';
  }

  // Deprecated: Giữ lại để tương thích ngược, nhưng nên dùng formatCurrency
  @Deprecated('Use formatCurrency instead')
  static String formatPriceWithUnit(double price, PriceUnit unit) {
    // Fallback: format tự động dựa trên giá trị
    return formatCurrency(price);
  }
}
