import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/finance_provider.dart';
import 'screens/auth_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
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
    return MaterialApp(
      title: 'My Wallet',
      theme: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          primary: Colors.tealAccent,
          secondary: Colors.deepPurpleAccent,
          surface: Color(0xFF1E1E2C),
          background: Color(0xFF121212),
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
        useMaterial3: true,
      ),
      builder: (context, child) {
        return Container(
          color: const Color(0xFF0F0F0F),
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 400,
                  maxHeight: 800,
                ),
                child: child,
              ),
            ),
          ),
        );
      },
      home: const AuthScreen(),
    );
  }
}
