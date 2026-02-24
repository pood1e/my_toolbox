import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonBox extends StatelessWidget {
  final double? _width;
  final double? _height;
  final BorderRadius? _borderRadius;

  const SkeletonBox({
    super.key,
    double? width,
    double? height,
    BorderRadius? borderRadius,
  }) : _width = width,
       _height = height,
       _borderRadius = borderRadius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;

    final highlightColor = isDark ? Colors.grey.shade700 : Colors.grey.shade200;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      period: const Duration(milliseconds: 1200),
      child: Container(
        width: _width,
        height: _height ?? 16,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: _borderRadius ?? BorderRadius.circular(8),
        ),
      ),
    );
  }
}
