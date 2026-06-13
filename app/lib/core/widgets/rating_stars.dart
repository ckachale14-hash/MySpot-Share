import 'package:flutter/material.dart';

class RatingStars extends StatelessWidget {
  const RatingStars({super.key, required this.rating, this.count, this.size = 16});

  final num rating;
  final int? count;
  final double size;

  @override
  Widget build(BuildContext context) {
    const amber = Color(0xFFFFB300);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            rating >= i
                ? Icons.star
                : (rating >= i - 0.5 ? Icons.star_half : Icons.star_border),
            size: size,
            color: amber,
          ),
        if (count != null) ...[
          const SizedBox(width: 4),
          Text('($count)',
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    );
  }
}
