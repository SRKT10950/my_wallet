import 'package:flutter/material.dart';
import 'core/constants/app_constants.dart';
import 'core/services/device_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/home/screens/home_screen.dart';

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
      routes: {
        AppConstants.routeSplash: (_) => const SplashScreen(),
        AppConstants.routeLogin: (_) => const LoginScreen(),
        AppConstants.routeRegister: (_) => const RegisterScreen(),
        AppConstants.routeHome: (_) => const HomeScreen(),
      },
    );
  }
}
