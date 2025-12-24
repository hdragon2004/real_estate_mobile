import 'package:flutter/material.dart';

class AvatarPicker extends StatelessWidget {
  final ImageProvider? imageProvider;
  final String initials;
  final VoidCallback onTap;
  final double radius;

  const AvatarPicker({
    super.key,
    required this.imageProvider,
    required this.initials,
    required this.onTap,
    this.radius = 60,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          CircleAvatar(
            radius: radius,
            backgroundImage: imageProvider,
            child: imageProvider == null
                ? Text(initials, style: const TextStyle(fontSize: 48))
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.camera_alt, size: 20, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}
