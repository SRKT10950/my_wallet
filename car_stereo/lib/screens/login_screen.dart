import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/database_helper.dart';
import '../services/sync_service.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _mobileController = TextEditingController();
  final _pinController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    final mobile = _mobileController.text.trim();
    final pin = _pinController.text.trim();

    if (mobile.isEmpty || pin.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter mobile number and PIN'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await SyncService.loginUser(mobile, pin);
      if (user != null) {
        final dbHelper = DatabaseHelper.instance;
        await dbHelper.setConfig('user_id', user['mobile_number']!);
        await dbHelper.setConfig('user_name', user['name']!);
        await dbHelper.setConfig('is_authenticated', '1');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Welcome, ${user['name']}! Connected to system.'),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
          );
        }
      } else {
        // Check if there is cached offline user to match
        final dbHelper = DatabaseHelper.instance;
        final cachedMobile = await dbHelper.getConfig('user_id');
        final cachedName = await dbHelper.getConfig('user_name');
        final isAuth = await dbHelper.getConfig('is_authenticated');

        if (cachedMobile == mobile && isAuth == '1') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Offline mode active. Welcome back, $cachedName.'),
                backgroundColor: Colors.orangeAccent,
              ),
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const DashboardScreen()),
            );
          }
        } else {
          throw Exception('Invalid Mobile Number or PIN (Offline cache mismatch)');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Curated sleek dark mode colors
    const primaryBg = Color(0xFF080914);
    const surfaceColor = Color(0xFF121422);
    const accentIndigo = Color(0xFF6366F1);

    return Scaffold(
      backgroundColor: primaryBg,
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -150,
            left: -150,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentIndigo.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            right: -150,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF10B981).withOpacity(0.05),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Card(
                color: surfaceColor.withOpacity(0.85),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(color: Colors.white.withOpacity(0.08)),
                ),
                elevation: 12,
                child: Container(
                  width: 800,
                  height: 400,
                  padding: const EdgeInsets.all(32),
                  child: Row(
                    children: [
                      // Left branding side (landscape optimized)
                      Expanded(
                        flex: 1,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: accentIndigo.withOpacity(0.3), width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: accentIndigo.withOpacity(0.15),
                                    blurRadius: 20,
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/logo.png',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Icon(
                                    Icons.directions_car_rounded,
                                    size: 48,
                                    color: accentIndigo,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'MY VEHICLE',
                              style: GoogleFonts.outfit(
                                textStyle: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Stereo Interface System',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                textStyle: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Divider
                      VerticalDivider(
                        color: Colors.white.withOpacity(0.08),
                        thickness: 1,
                        indent: 20,
                        endIndent: 20,
                      ),
                      const SizedBox(width: 24),
                      // Right form side
                      Expanded(
                        flex: 1,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'CONNECT DEVICE',
                              style: GoogleFonts.outfit(
                                textStyle: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Mobile Input
                            TextFormField(
                              controller: _mobileController,
                              keyboardType: TextInputType.phone,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Mobile Number',
                                labelStyle: const TextStyle(color: Colors.white70),
                                prefixIcon: const Icon(Icons.phone_android_rounded, color: accentIndigo),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.03),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(color: accentIndigo, width: 2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // PIN Input
                            TextFormField(
                              controller: _pinController,
                              keyboardType: TextInputType.number,
                              obscureText: true,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'System PIN',
                                labelStyle: const TextStyle(color: Colors.white70),
                                prefixIcon: const Icon(Icons.lock_outline_rounded, color: accentIndigo),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.03),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(color: accentIndigo, width: 2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Connect Button
                            SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: accentIndigo,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 4,
                                  shadowColor: accentIndigo.withOpacity(0.4),
                                ),
                                onPressed: _isLoading ? null : _handleLogin,
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 3,
                                        ),
                                      )
                                    : Text(
                                        'CONNECT SYSTEM',
                                        style: GoogleFonts.outfit(
                                          textStyle: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
