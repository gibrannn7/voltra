import 'package:flutter/material.dart';
import '../../config/app_constants.dart';

/// Smart reminder card that shows contextual reminders.
/// Logic: Shows bill reminders after the 20th of each month.
class SmartReminderCard extends StatelessWidget {
  const SmartReminderCard({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isBillReminder = now.day >= 20;

    if (!isBillReminder) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFEF3C7),
            Color(0xFFFDE68A),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
        border: Border.all(
          color: AppColors.energyYellowDark.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.energyYellowDark.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: AppColors.energyYellowDark,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pengingat Tagihan 💡',
                  style: TextStyle(
                    fontFamily: AppFonts.heading,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF92400E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Jangan lupa bayar tagihan PLN, air, & internet bulan ini sebelum jatuh tempo!',
                  style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 12,
                    color: const Color(0xFF92400E).withValues(alpha: 0.8),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),

          // Action
          IconButton(
            onPressed: () {
              // Navigate to PLN category
              Navigator.pushNamed(context, AppRoutes.categoryProducts);
            },
            icon: const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Color(0xFF92400E),
            ),
          ),
        ],
      ),
    );
  }
}
