import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../config/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/system_repository.dart';
import 'dart:io';
import 'package:root_check/root_check.dart';

/// Splash screen with:
/// 1. Animated Voltra logo
/// 2. Version check (Force Update mechanism)
/// 3. Maintenance mode check
/// 4. Auth session restoration
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  final SystemRepository _systemRepo = SystemRepository();

  @override
  void initState() {
    super.initState();

    // Status bar: transparent for immersive splash
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _scaleAnim = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
    );

    _animController.forward();

    // Start initialization after animation starts
    Future.delayed(const Duration(milliseconds: 800), () {
      _initialize();
    });
  }

  Future<void> _initialize() async {
    try {
      // 2. Root Detection (Security Check)
      bool isDeviceRooted = false;
      if (Platform.isAndroid || Platform.isIOS) {
        try {
          isDeviceRooted = (await RootCheck.isRooted) ?? false;
        } catch (e) {
          isDeviceRooted = false; // Bypass jika package gagal jalan di simulator tertentu
        }
      }

      if (isDeviceRooted && mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Keamanan Terdeteksi', style: TextStyle(fontWeight: FontWeight.bold)),
            content: const Text('Aplikasi Voltra tidak dapat berjalan pada perangkat yang di-root atau dimodifikasi demi keamanan transaksi Anda.'),
            actions: [
              TextButton(
                onPressed: () => exit(0),
                child: const Text('Keluar', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
        return; // Hentikan proses aplikasi jika di-root
      }

      // 1. Check system settings (maintenance mode)
      final settings = await _systemRepo.getSettings();
      if (settings.isSuccess && settings.data != null) {
        final isMaintenance =
            settings.data!['is_maintenance_mode'] as bool? ?? false;
        if (isMaintenance && mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.maintenance);
          return;
        }
      }

      // 2. Version check
      final versionResult = await _systemRepo.checkVersion('1.0.0');
      if (versionResult.isSuccess && versionResult.data != null) {
        final forceUpdate =
            versionResult.data!['force_update'] as bool? ?? false;
        if (forceUpdate && mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.forceUpdate);
          return;
        }
      }

      // 3. Check auth status
      if (!mounted) return;
      final authProvider = context.read<AuthProvider>();
      await authProvider.checkAuthStatus();

      if (!mounted) return;

      // Ensure minimum splash display time
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      if (authProvider.isAuthenticated) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    } catch (e) {
      // On error, try to restore cached session
      if (!mounted) return;
      final authProvider = context.read<AuthProvider>();
      await authProvider.checkAuthStatus();

      if (!mounted) return;

      if (authProvider.isAuthenticated) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.electricBlueDark,
              AppColors.electricBlue,
              AppColors.electricBlueLight,
            ],
          ),
        ),
        child: AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnim,
              child: ScaleTransition(
                scale: _scaleAnim,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo icon
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppColors.white.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.bolt_rounded,
                        size: 56,
                        color: AppColors.energyYellow,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Brand name
                    const Text(
                      'VOLTRA',
                      style: TextStyle(
                        fontFamily: AppFonts.heading,
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                        letterSpacing: 6,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Tagline
                    Text(
                      AppStrings.appTagline,
                      style: TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppColors.white.withValues(alpha: 0.8),
                        letterSpacing: 1,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xxl),

                    // Loading indicator
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(
                          AppColors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}