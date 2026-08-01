import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'database/database_helper.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Check authentication status on startup
  final dbHelper = DatabaseHelper.instance;
  final isAuthStr = await dbHelper.getConfig('is_authenticated', defaultValue: '0');
  final bool isAuthenticated = isAuthStr == '1';

  runApp(CarStereoApp(isAuthenticated: isAuthenticated));
}

class CarStereoApp extends StatelessWidget {
  final bool isAuthenticated;
  const CarStereoApp({super.key, required this.isAuthenticated});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Car Stereo System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6366F1), // Indigo
          secondary: Color(0xFF10B981), // Green
          surface: Color(0xFF121422),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFF080914),
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
      ),
      home: isAuthenticated ? const DashboardScreen() : const LoginScreen(),
    );
  }
}
