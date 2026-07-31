import 'package:flutter/material.dart';
import 'core/constants/app_constants.dart';
import 'core/services/device_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/otp_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/home/screens/main_layout_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize device service (device name + unique ID)
  await DeviceService.instance.initialize();

  runApp(const MyWalletApp());
}

class MyWalletApp extends StatelessWidget {
  const MyWalletApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: AppConstants.routeSplash,
      onGenerateRoute: (settings) {
        if (settings.name == AppConstants.routeOtp) {
          final args = settings.arguments as OtpScreenArgs?;
          return MaterialPageRoute(
            builder: (_) => OtpScreen(
              mobile: args?.mobile ?? '',
              initialDemoOtp: args?.demoOtp,
            ),
          );
        }
        return null;
      },
      routes: {
        AppConstants.routeSplash: (_) => const SplashScreen(),
        AppConstants.routeLogin: (_) => const LoginScreen(),
        AppConstants.routeRegister: (_) => const RegisterScreen(),
        AppConstants.routeHome: (_) => const MainLayoutScreen(initialTabIndex: 0),
        AppConstants.routeDashboard: (_) => const MainLayoutScreen(initialTabIndex: 0),
        AppConstants.routeDailyTracker: (_) => const MainLayoutScreen(initialTabIndex: 1),
        AppConstants.routeLendBorrow: (_) => const MainLayoutScreen(initialTabIndex: 2),
        AppConstants.routeExpenses: (_) => const MainLayoutScreen(initialTabIndex: 3),
        AppConstants.routeLoans: (_) => const MainLayoutScreen(initialTabIndex: 4),
        AppConstants.routeInvestment: (_) => const MainLayoutScreen(initialTabIndex: 5),
        AppConstants.routeOdAccount: (_) => const MainLayoutScreen(initialTabIndex: 6),
        AppConstants.routeContacts: (_) => const MainLayoutScreen(initialTabIndex: 7),
        AppConstants.routeCatalog: (_) => const MainLayoutScreen(initialTabIndex: 8),
        AppConstants.routeReceiptScan: (_) => const MainLayoutScreen(initialTabIndex: 9),
        AppConstants.routeSettings: (_) => const MainLayoutScreen(initialTabIndex: 10),
      },
    );
  }
}
