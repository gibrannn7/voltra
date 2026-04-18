/// Voltra App Constants
/// Single Source of Truth for all static values across the app.
library;

import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

// ─── API Configuration ─────────────────────────────────────
class ApiConfig {
  ApiConfig._();

  /// Base URL for Voltra API — change to production URL before release.
  static const String baseUrl = 'https://8aeb-180-242-129-10.ngrok-free.app/api/v1';
  static const String prodBaseUrl = 'https://api.voltra.app/api/v1';

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  /// Token key for secure storage
  static const String tokenKey = 'voltra_auth_token';
  static const String userKey = 'voltra_user_data';
}

// ─── Design System Colors ──────────────────────────────────
class AppColors {
  AppColors._();

  // Primary Palette ("Clean Energy")
  static const Color electricBlue = Color(0xFF2563EB);
  static const Color electricBlueDark = Color(0xFF1D4ED8);
  static const Color electricBlueLight = Color(0xFF3B82F6);
  static const Color energyYellow = Color(0xFFFACC15);
  static const Color energyYellowDark = Color(0xFFEAB308);

  // Semantic Colors
  static const Color success = Color(0xFF10B981);
  static const Color successBg = Color(0xFFD1FAE5);
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerBg = Color(0xFFFEE2E2);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningBg = Color(0xFFFEF3C7);
  static const Color info = Color(0xFF0EA5E9);
  static const Color infoBg = Color(0xFFE0F2FE);

  // Neutral Palette
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color divider = Color(0xFFE5E7EB);
  static const Color surface = Color(0xFFF9FAFB);
  static const Color background = Color(0xFFF3F4F6);
  static const Color white = Color(0xFFFFFFFF);

  // Dark Mode
  static const Color darkBg = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkCard = Color(0xFF334155);
  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
}

// ─── Typography ────────────────────────────────────────────
class AppFonts {
  AppFonts._();

  static const String heading = 'Lexend';
  static const String body = 'Inter';
}

// ─── Spacing & Sizing ──────────────────────────────────────
class AppSpacing {
  AppSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  static const double borderRadius = 12.0;
  static const double borderRadiusSm = 8.0;
  static const double borderRadiusLg = 16.0;
  static const double borderRadiusXl = 24.0;

  static const double iconSm = 20.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 48.0;
}

// ─── App Strings ───────────────────────────────────────────
class AppStrings {
  AppStrings._();

  static const String appName = 'Voltra';
  static const String appTagline = 'Smart PPOB & Bill Payment';

  // Auth
  static const String loginTitle = 'Selamat Datang!';
  static const String loginSubtitle = 'Masuk ke akun Voltra Anda';
  static const String registerTitle = 'Buat Akun Baru';
  static const String registerSubtitle = 'Daftar untuk mulai bayar tagihan';
  static const String enterPin = 'Masukkan PIN';
  static const String verifyPin = 'Verifikasi PIN Anda';
  static const String createPin = 'Buat PIN 6 Digit';

  // Transaction
  static const String transactionSuccess = 'Transaksi Berhasil!';
  static const String transactionFailed = 'Transaksi Gagal';
  static const String transactionPending = 'Menunggu Pembayaran';

  // General
  static const String retry = 'Coba Lagi';
  static const String cancel = 'Batal';
  static const String confirm = 'Konfirmasi';
  static const String close = 'Tutup';
  static const String save = 'Simpan';
  static const String loading = 'Memuat...';
  static const String noData = 'Belum ada data';
  static const String noInternet = 'Tidak ada koneksi internet';
  static const String maintenanceMessage = 'Server sedang dalam perbaikan. Silakan coba beberapa saat lagi.';
}

// ─── Route Names ───────────────────────────────────────────
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String pin = '/pin';
  static const String home = '/home';
  static const String categoryProducts = '/category-products';
  static const String payment = '/payment';
  static const String processing = '/processing';
  static const String transactionSuccess = '/transaction-success';
  static const String history = '/history';
  static const String historyDetail = '/history-detail';
  static const String wallet = '/wallet';
  static const String profile = '/profile';
  static const String notifications = '/notifications';
  static const String maintenance = '/maintenance';
  static const String forceUpdate = '/force-update';
  static const String success = '/success';
}

// ─── Asset Paths ───────────────────────────────────────────
class AppAssets {
  AppAssets._();

  static const String logoFull = 'assets/images/voltra_logo.png';
  static const String logoIcon = 'assets/images/voltra_icon.png';

  // Lottie animations
  static const String lottieSuccess = 'assets/lottie/success.json';
  static const String lottieFailed = 'assets/lottie/failed.json';
  static const String lottieLoading = 'assets/lottie/loading.json';
  static const String lottieMaintenance = 'assets/lottie/maintenance.json';
  static const String lottieEmpty = 'assets/lottie/empty.json';
}
