import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _pinController = TextEditingController();
  bool _isFirstTime = true;
  String? _savedPin;

  @override
  void initState() {
    super.initState();
    _checkFirstTime();
  }

  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final pin = prefs.getString('user_pin');
    setState(() {
      _isFirstTime = pin == null;
      _savedPin = pin;
    });
  }

  Future<void> _submit() async {
    final prefs = await SharedPreferences.getInstance();
    if (_isFirstTime) {
      if (_pinController.text.length >= 4) {
        await prefs.setString('user_pin', _pinController.text);
        _navigateToHome();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN must be at least 4 digits')));
      }
    } else {
      if (_pinController.text == _savedPin) {
        _navigateToHome();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid PIN')));
      }
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Wallet')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_isFirstTime ? 'Register New PIN' : 'Enter PIN to Login', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 20),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'PIN'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submit,
              child: Text(_isFirstTime ? 'Register' : 'Login'),
            )
          ],
        ),
      ),
    );
  }
}
