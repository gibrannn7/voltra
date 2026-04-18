import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../config/app_constants.dart';

/// Shimmer loading placeholder that matches the "Clean Energy" design system.
class ShimmerLoading extends StatelessWidget {
  final double height;
  final double? width;
  final double borderRadius;

  const ShimmerLoading({
    super.key,
    this.height = 16,
    this.width,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? AppColors.darkCard : AppColors.divider,
      highlightColor: isDark ? const Color(0xFF475569) : AppColors.surface,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// Shimmer card for loading list items.
class ShimmerCard extends StatelessWidget {
  const ShimmerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            const ShimmerLoading(height: 48, width: 48, borderRadius: 12),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerLoading(height: 14, width: MediaQuery.of(context).size.width * 0.4),
                  const SizedBox(height: AppSpacing.sm),
                  ShimmerLoading(height: 12, width: MediaQuery.of(context).size.width * 0.25),
                ],
              ),
            ),
            const ShimmerLoading(height: 16, width: 80),
          ],
        ),
      ),
    );
  }
}

/// Shimmer grid for category loading.
class ShimmerGrid extends StatelessWidget {
  final int itemCount;
  final int crossAxisCount;

  const ShimmerGrid({
    super.key,
    this.itemCount = 8,
    this.crossAxisCount = 4,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) => const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ShimmerLoading(height: 48, width: 48, borderRadius: 12),
          SizedBox(height: AppSpacing.xs),
          ShimmerLoading(height: 10, width: 50),
        ],
      ),
    );
  }
}
