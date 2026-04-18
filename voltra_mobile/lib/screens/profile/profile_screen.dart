import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:voltra_mobile/config/app_constants.dart';
import 'package:voltra_mobile/providers/auth_provider.dart';

/// Profile screen with user info, KYC status badge, menu items, and logout.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profil'),
        automaticallyImplyLeading: false,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final user = auth.user;

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              // Avatar + Info card
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.borderRadiusLg),
                  border: Border.all(color: AppColors.divider, width: 0.5),
                ),
                child: Column(
                  children: [
                    // Avatar
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.electricBlueDark,
                            AppColors.electricBlueLight,
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color:
                                AppColors.electricBlue.withValues(alpha: 0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          (user?.name ?? 'U')
                              .substring(0, 1)
                              .toUpperCase(),
                          style: const TextStyle(
                            fontFamily: AppFonts.heading,
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Name
                    Text(
                      user?.name ?? 'User',
                      style: const TextStyle(
                        fontFamily: AppFonts.heading,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Phone
                    Text(
                      user?.phoneNumber ?? '-',
                      style: const TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    // Email
                    if (user?.email != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        user!.email!,
                        style: const TextStyle(
                          fontFamily: AppFonts.body,
                          fontSize: 13,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],

                    const SizedBox(height: AppSpacing.md),

                    // KYC Status badge
                    _buildKycBadge(user?.kycStatus ?? 'unverified'),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Menu items
              _buildMenuItem(
                context,
                icon: Icons.person_outline,
                label: 'Data Pribadi',
                onTap: () {},
              ),
              _buildMenuItem(
                context,
                icon: Icons.lock_outline,
                label: 'Ubah PIN',
                onTap: () {},
              ),
              _buildMenuItem(
                context,
                icon: Icons.notifications_outlined,
                label: 'Notifikasi',
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.notifications);
                },
              ),
              _buildMenuItem(
                context,
                icon: Icons.headset_mic_outlined,
                label: 'Hubungi CS',
                subtitle: 'WhatsApp Customer Service',
                onTap: () {},
              ),
              _buildMenuItem(
                context,
                icon: Icons.info_outline,
                label: 'Tentang Aplikasi',
                subtitle: 'Voltra v1.0.0',
                onTap: () {},
              ),

              const SizedBox(height: AppSpacing.lg),

              // Delete account
              _buildMenuItem(
                context,
                icon: Icons.delete_forever_outlined,
                label: 'Hapus Akun',
                subtitle: 'Penghapusan akun permanen',
                iconColor: AppColors.danger,
                labelColor: AppColors.danger,
                onTap: () => _showDeleteAccountDialog(context),
              ),

              const SizedBox(height: AppSpacing.sm),

              // Logout button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showLogoutDialog(context),
                  icon: const Icon(
                    Icons.logout,
                    color: AppColors.danger,
                    size: 20,
                  ),
                  label: const Text(
                    'Keluar',
                    style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontWeight: FontWeight.w600,
                      color: AppColors.danger,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.danger),
                    minimumSize: const Size(double.infinity, 52),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),
            ],
          );
        },
      ),
    );
  }

  Widget _buildKycBadge(String status) {
    Color bgColor;
    Color textColor;
    IconData icon;
    String label;

    switch (status.toLowerCase()) {
      case 'verified':
        bgColor = AppColors.successBg;
        textColor = AppColors.success;
        icon = Icons.verified_rounded;
        label = 'Terverifikasi';
        break;
      case 'pending':
        bgColor = AppColors.warningBg;
        textColor = AppColors.warning;
        icon = Icons.hourglass_top_rounded;
        label = 'Menunggu Verifikasi';
        break;
      default:
        bgColor = AppColors.surface;
        textColor = AppColors.textTertiary;
        icon = Icons.shield_outlined;
        label = 'Belum Verifikasi';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    String? subtitle,
    Color? iconColor,
    Color? labelColor,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color:
                (iconColor ?? AppColors.electricBlue).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: iconColor ?? AppColors.electricBlue,
            size: 20,
          ),
        ),
        title: Text(
          label,
          style: TextStyle(
            fontFamily: AppFonts.body,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: labelColor ?? AppColors.textPrimary,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: const TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 12,
                  color: AppColors.textTertiary,
                ),
              )
            : null,
        trailing: Icon(
          Icons.chevron_right,
          color: AppColors.textTertiary,
          size: 20,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Keluar',
          style: TextStyle(fontFamily: AppFonts.heading),
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari akun?',
          style: TextStyle(fontFamily: AppFonts.body),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.login,
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Hapus Akun',
          style: TextStyle(
            fontFamily: AppFonts.heading,
            color: AppColors.danger,
          ),
        ),
        content: const Text(
          'Aksi ini TIDAK DAPAT dibatalkan. Semua data Anda akan dihapus secara permanen. Apakah Anda yakin?',
          style: TextStyle(fontFamily: AppFonts.body),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<AuthProvider>().deleteAccount();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.login,
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
            ),
            child: const Text('Hapus Akun'),
          ),
        ],
      ),
    );
  }
}
