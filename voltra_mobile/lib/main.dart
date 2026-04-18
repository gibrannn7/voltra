import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:voltra_mobile/config/app_constants.dart';
import 'package:voltra_mobile/config/app_theme.dart';
import 'package:voltra_mobile/providers/auth_provider.dart';
import 'package:voltra_mobile/providers/connectivity_provider.dart';
import 'package:voltra_mobile/providers/notification_provider.dart';
import 'package:voltra_mobile/providers/product_provider.dart';
import 'package:voltra_mobile/providers/transaction_provider.dart';
import 'package:voltra_mobile/providers/wallet_provider.dart';
import 'package:voltra_mobile/screens/auth/login_screen.dart';
import 'package:voltra_mobile/screens/auth/pin_screen.dart';
import 'package:voltra_mobile/screens/auth/register_screen.dart';
import 'package:voltra_mobile/screens/history/history_detail_screen.dart';
import 'package:voltra_mobile/screens/history/history_screen.dart';
import 'package:voltra_mobile/screens/main/main_wrapper.dart';
import 'package:voltra_mobile/screens/maintenance/maintenance_screen.dart';
import 'package:voltra_mobile/screens/notifications/notification_screen.dart';
import 'package:voltra_mobile/screens/products/category_products_screen.dart';
import 'package:voltra_mobile/screens/profile/profile_screen.dart';
import 'package:voltra_mobile/screens/splash/splash_screen.dart';
import 'package:voltra_mobile/screens/transactions/payment_screen.dart';
import 'package:voltra_mobile/screens/transactions/success_screen.dart';
import 'package:voltra_mobile/screens/wallet/wallet_screen.dart';
import 'package:voltra_mobile/services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock portrait orientation for better mobile experience
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize secure storage service
  await StorageService.initialize();

  // Initialize API client singleton
  ApiClient();

  runApp(const VoltraApp());
}

class VoltraApp extends StatelessWidget {
  const VoltraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        scaffoldMessengerKey: scaffoldMessengerKey,
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.light,
        initialRoute: AppRoutes.splash,
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case AppRoutes.splash:
              return MaterialPageRoute(builder: (_) => const SplashScreen());
            case AppRoutes.login:
              return MaterialPageRoute(builder: (_) => const LoginScreen());
            case AppRoutes.register:
              return MaterialPageRoute(builder: (_) => const RegisterScreen());
            case AppRoutes.pin:
              return MaterialPageRoute(builder: (_) => const PinScreen());
            case AppRoutes.home:
              return MaterialPageRoute(builder: (_) => const MainWrapper());
            case AppRoutes.maintenance:
              return MaterialPageRoute(builder: (_) => const MaintenanceScreen());
            case AppRoutes.categoryProducts:
              return MaterialPageRoute(
                builder: (_) => const CategoryProductsScreen(),
                settings: settings,
              );
            case AppRoutes.payment:
              return MaterialPageRoute(
                builder: (_) => const PaymentScreen(),
                settings: settings,
              );
            case AppRoutes.success:
              return MaterialPageRoute(builder: (_) => const SuccessScreen());
            case AppRoutes.history:
              return MaterialPageRoute(builder: (_) => const HistoryScreen());
            case AppRoutes.historyDetail:
              return MaterialPageRoute(
                builder: (_) => const HistoryDetailScreen(),
                settings: settings,
              );
            case AppRoutes.wallet:
              return MaterialPageRoute(builder: (_) => const WalletScreen());
            case AppRoutes.notifications:
              return MaterialPageRoute(builder: (_) => const NotificationScreen());
            case AppRoutes.profile:
              return MaterialPageRoute(builder: (_) => const ProfileScreen());
            default:
              return MaterialPageRoute(
                builder: (_) => const Scaffold(
                  body: Center(child: Text('Halaman tidak ditemukan')),
                ),
              );
          }
        },
      ),
    );
  }
}
