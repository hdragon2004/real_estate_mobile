import 'package:flutter/material.dart';

/// Widget hiển thị rating với sao
class RatingWidget extends StatelessWidget {
  final double rating;
  final int totalReviews;
  final bool showReviewsCount;
  final double starSize;
  final Color? starColor;

  const RatingWidget({
    super.key,
    required this.rating,
    this.totalReviews = 0,
    this.showReviewsCount = true,
    this.starSize = 20,
    this.starColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (index) {
          final filled = index < rating.floor();
          final halfFilled = index == rating.floor() && rating % 1 >= 0.5;
          
          return Icon(
            halfFilled
                ? Icons.star_half
                : filled
                    ? Icons.star
                    : Icons.star_border,
            size: starSize,
            color: starColor ?? Colors.amber,
          );
        }),
        const SizedBox(width: 8),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        if (showReviewsCount && totalReviews > 0) ...[
          const SizedBox(width: 4),
          Text(
            '($totalReviews)',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ],
      ],
    );
  }
}

