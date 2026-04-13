import 'package:flutter/material.dart';
import '../../config/app_constants.dart';
import '../../models/category_model.dart';

/// Quick action grid displaying product categories.
/// Each category shows icon + name and navigates to category products.
class QuickActionGrid extends StatelessWidget {
  final List<CategoryModel> categories;

  const QuickActionGrid({super.key, required this.categories});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final config = _getCategoryConfig(category.icon);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoutes.categoryProducts,
                arguments: category,
              );
            },
            borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon container
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: config.bgColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: config.iconColor.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    config.icon,
                    size: 28,
                    color: config.iconColor,
                  ),
                ),
                const SizedBox(height: 8),
                // Label
                Text(
                  category.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  _CategoryIconConfig _getCategoryConfig(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'bolt':
      case 'pln':
        return const _CategoryIconConfig(
          icon: Icons.bolt_rounded,
          iconColor: AppColors.electricBlue,
          bgColor: Color(0xFFDBEAFE),
        );
      case 'phone_android':
      case 'pulsa':
        return const _CategoryIconConfig(
          icon: Icons.phone_android_rounded,
          iconColor: Color(0xFF059669),
          bgColor: Color(0xFFD1FAE5),
        );
      case 'wifi':
      case 'data':
        return const _CategoryIconConfig(
          icon: Icons.wifi_rounded,
          iconColor: Color(0xFF7C3AED),
          bgColor: Color(0xFFEDE9FE),
        );
      case 'account_balance_wallet':
      case 'ewallet':
        return const _CategoryIconConfig(
          icon: Icons.account_balance_wallet_rounded,
          iconColor: Color(0xFFEA580C),
          bgColor: Color(0xFFFFF7ED),
        );
      case 'sports_esports':
      case 'game':
        return const _CategoryIconConfig(
          icon: Icons.sports_esports_rounded,
          iconColor: Color(0xFFDC2626),
          bgColor: Color(0xFFFEE2E2),
        );
      case 'water_drop':
      case 'pdam':
        return const _CategoryIconConfig(
          icon: Icons.water_drop_rounded,
          iconColor: Color(0xFF0284C7),
          bgColor: Color(0xFFE0F2FE),
        );
      case 'tv':
      case 'tv_cable':
        return const _CategoryIconConfig(
          icon: Icons.tv_rounded,
          iconColor: Color(0xFF7C3AED),
          bgColor: Color(0xFFF3E8FF),
        );
      default:
        return const _CategoryIconConfig(
          icon: Icons.category_rounded,
          iconColor: AppColors.electricBlue,
          bgColor: Color(0xFFDBEAFE),
        );
    }
  }
}

class _CategoryIconConfig {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;

  const _CategoryIconConfig({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });
}
