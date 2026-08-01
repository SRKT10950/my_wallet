import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'providers/finance_provider.dart';
import 'screens/home_screen.dart';
import 'screens/auth/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => FinanceProvider()),
      ],
      child: const MyWalletApp(),
    ),
  );
}

class MyWalletApp extends StatelessWidget {
  const MyWalletApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'mWallet Enterprise',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      home: Consumer<FinanceProvider>(
        builder: (context, provider, _) {
          return provider.isAuthenticated ? const HomeScreen() : const LoginScreen();
        },
      ),
    );
  }
}
