import 'package:flutter/material.dart';

/// Box Shadows cho ứng dụng
class AppShadows {
  AppShadows._();

  // Small shadow - cho buttons, chips
  static const List<BoxShadow> small = [
        BoxShadow(
          color: Color(0x14000000), // 8% opacity
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ];

  // Medium shadow - cho cards
  static const List<BoxShadow> medium = [
        BoxShadow(
          color: Color(0x14000000), // 8% opacity
          blurRadius: 16,
          offset: Offset(0, 4),
        ),
      ];

  // Large shadow - cho modals, bottom sheets
  static const List<BoxShadow> large = [
        BoxShadow(
          color: Color(0x1F000000), // 12% opacity
          blurRadius: 24,
          offset: Offset(0, 8),
        ),
      ];

  // Card shadow
  static const List<BoxShadow> card = [
        BoxShadow(
          color: Color(0x0F000000), // 6% opacity
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ];

  // Bottom nav shadow
  static const List<BoxShadow> bottomNav = [
        BoxShadow(
          color: Color(0x1A000000), // 10% opacity
          blurRadius: 20,
          offset: Offset(0, -4),
        ),
      ];

  // Top shadow - cho bottom sheets, navigation bars
  static const List<BoxShadow> top = [
        BoxShadow(
          color: Color(0x1A000000), // 10% opacity
          blurRadius: 20,
          offset: Offset(0, -4),
        ),
      ];

  // Floating button shadow - primary color
  static const List<BoxShadow> floatingButton = [
        BoxShadow(
          color: Color(0x4D1E3A5F), // primary with 30% opacity
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ];

  // Image overlay shadow
  static const List<BoxShadow> imageOverlay = [
        BoxShadow(
          color: Color(0x66000000), // 40% opacity
          blurRadius: 20,
          offset: Offset(0, 10),
          spreadRadius: -5,
        ),
      ];
}
