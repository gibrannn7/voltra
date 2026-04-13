import 'package:flutter/material.dart';
import '../../config/app_constants.dart';

/// Status badge pill with semantic colors matching the transaction states.
class StatusPill extends StatelessWidget {
  final String status;
  final double fontSize;

  const StatusPill({
    super.key,
    required this.status,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: config.bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: 14, color: config.textColor),
          const SizedBox(width: 4),
          Text(
            config.label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: config.textColor,
              fontFamily: AppFonts.body,
            ),
          ),
        ],
      ),
    );
  }

  _StatusConfig _getStatusConfig(String status) {
    switch (status.toLowerCase()) {
      case 'success':
        return const _StatusConfig(
          label: 'Berhasil',
          bgColor: AppColors.successBg,
          textColor: AppColors.success,
          icon: Icons.check_circle_outline,
        );
      case 'failed':
        return const _StatusConfig(
          label: 'Gagal',
          bgColor: AppColors.dangerBg,
          textColor: AppColors.danger,
          icon: Icons.cancel_outlined,
        );
      case 'processing':
        return const _StatusConfig(
          label: 'Diproses',
          bgColor: AppColors.warningBg,
          textColor: AppColors.warning,
          icon: Icons.sync,
        );
      case 'pending':
      default:
        return _StatusConfig(
          label: 'Menunggu',
          bgColor: AppColors.divider.withValues(alpha: 0.5),
          textColor: AppColors.textSecondary,
          icon: Icons.access_time,
        );
    }
  }
}

class _StatusConfig {
  final String label;
  final Color bgColor;
  final Color textColor;
  final IconData icon;

  const _StatusConfig({
    required this.label,
    required this.bgColor,
    required this.textColor,
    required this.icon,
  });
}
