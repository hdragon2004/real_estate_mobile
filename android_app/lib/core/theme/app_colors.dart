import 'package:flutter/material.dart';

/// Bảng màu chính của ứng dụng Real Estate Hub
class AppColors {
  AppColors._();

  // Primary Colors - Cyan/Turquoise (đã làm tối đi 3 phần)
  static const Color primary = Color(0xFF47B0A9); // Tối hơn #66FCF1
  static const Color primaryLight = Color(0xFF6FD4CD); // Lighter variant
  static const Color primaryDark = Color(0xFF2F8A84); // Darker variant

  // Secondary Colors - Vàng gold (sang trọng)
  static const Color secondary = Color(0xFFD4AF37);
  static const Color secondaryLight = Color(0xFFE8C555);
  static const Color secondaryDark = Color(0xFFB8941F);

  // Accent Colors - Xanh lá (tươi mới, tự nhiên)
  static const Color accent = Color(0xFF2ECC71);
  static const Color accentLight = Color(0xFF58D68D);
  static const Color accentDark = Color(0xFF27AE60);

  // Background Colors
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F3F5);

  // Text Colors
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6C757D);
  static const Color textHint = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnSecondary = Color(0xFF1A1A2E);

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Border Colors
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderLight = Color(0xFFF3F4F6);
  static const Color divider = Color(0xFFE5E7EB);

  // Shadow Colors
  static const Color shadow = Color(0x1A000000);
  static const Color shadowLight = Color(0x0D000000);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondary, secondaryLight],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, accentLight],
  );

  // Property Type Colors
  static const Color apartment = Color(0xFF6366F1);  // Tím xanh - Căn hộ
  static const Color house = Color(0xFF8B5CF6);      // Tím - Nhà riêng
  static const Color villa = Color(0xFFEC4899);      // Hồng - Biệt thự
  static const Color land = Color(0xFF14B8A6);       // Xanh ngọc - Đất nền
  static const Color office = Color(0xFF3B82F6);     // Xanh dương - Văn phòng
  static const Color commercial = Color(0xFFF97316); // Cam - Mặt bằng kinh doanh
}
