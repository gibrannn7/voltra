import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'config/app_constants.dart';
import 'config/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/wallet_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/history/history_screen.dart';
import 'screens/main/main_wrapper.dart';
import 'screens/maintenance/maintenance_screen.dart';
import 'screens/products/category_products_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'services/api_client.dart';
import 'services/storage_service.dart';
import 'providers/connectivity_provider.dart';
import 'providers/notification_provider.dart';
import 'screens/notifications/notification_screen.dart';
import 'screens/transactions/success_screen.dart';
import 'screens/history/history_detail_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize storage service
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
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.light,
        initialRoute: AppRoutes.splash,
        routes: {
          AppRoutes.splash: (_) => const SplashScreen(),
          AppRoutes.login: (_) => const LoginScreen(),
          AppRoutes.register: (_) => const RegisterScreen(),
          AppRoutes.home: (_) => const MainWrapper(),
          AppRoutes.maintenance: (_) => const MaintenanceScreen(),
          AppRoutes.categoryProducts: (_) => const CategoryProductsScreen(),
          AppRoutes.history: (_) => const HistoryScreen(),
          AppRoutes.notifications: (_) => const NotificationScreen(),
          AppRoutes.success: (_) => const SuccessScreen(),
          AppRoutes.historyDetail: (_) => const HistoryDetailScreen(),
        },
      ),
    );
  }
}
