import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/finance_provider.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleRegister() async {
    if (_pinController.text != _confirmPinController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PINs do not match')));
      return;
    }
    if (_nameController.text.isEmpty || _mobileController.text.isEmpty || _pinController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await Provider.of<FinanceProvider>(context, listen: false).register(
        _nameController.text,
        _mobileController.text,
        _pinController.text,
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A12),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               // Small logo for registration
              Container(
                width: 80,
                height: 80,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.cyanAccent.withOpacity(0.3), width: 1.5),
                ),
                child: ClipOval(
                  child: Image.asset('assets/logo.png', fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'SYSTEM REGISTRATION',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const Text(
                'CREATE COMMAND CENTER CREDENTIALS',
                style: TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              
              _buildGlassField(_nameController, 'USER_FULL_NAME', Icons.person),
              const SizedBox(height: 16),
              _buildGlassField(_mobileController, 'AUTH_MOBILE_ID', Icons.phone, keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              _buildGlassField(_pinController, 'SECURE_PIN_KEY', Icons.lock, isPin: true),
              const SizedBox(height: 16),
              _buildGlassField(_confirmPinController, 'CONFIRM_PIN_KEY', Icons.lock_outline, isPin: true),
              
              const SizedBox(height: 32),
              if (_isLoading)
                const CircularProgressIndicator(color: Colors.cyanAccent)
              else
                ElevatedButton(
                  onPressed: _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 10,
                    shadowColor: Colors.cyanAccent.withOpacity(0.4),
                  ),
                  child: const Text('CREATE SYSTEM ACCOUNT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                child: RichText(
                  text: const TextSpan(
                    text: "ALREADY REGISTERED? ",
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                    children: [
                      TextSpan(
                        text: "ACCESS COMMAND CENTER",
                        style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassField(TextEditingController controller, String label, IconData icon, {TextInputType? keyboardType, bool isPin = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: isPin,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold),
          prefixIcon: Icon(icon, color: Colors.cyanAccent, size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}
