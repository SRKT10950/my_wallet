import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/finance_provider.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _mobileController = TextEditingController();
  final _pinController = TextEditingController();
  final _mobileFocus = FocusNode();
  final _pinFocus = FocusNode();
  bool _isLoading = false;
  bool _showPin = false;
  bool _mobileFocused = false;
  bool _pinFocused = false;

  late AnimationController _orbController;
  late AnimationController _shimmerController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _orbController = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat(reverse: true);
    _shimmerController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();

    _mobileFocus.addListener(() => setState(() => _mobileFocused = _mobileFocus.hasFocus));
    _pinFocus.addListener(() => setState(() => _pinFocused = _pinFocus.hasFocus));
  }

  @override
  void dispose() {
    _orbController.dispose();
    _shimmerController.dispose();
    _fadeController.dispose();
    _mobileFocus.dispose();
    _pinFocus.dispose();
    _mobileController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_mobileController.text.isEmpty || _pinController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Text('Please enter all fields'),
          ]),
          backgroundColor: const Color(0xFF1E1B3A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final provider = Provider.of<FinanceProvider>(context, listen: false);
      await provider.login(_mobileController.text, _pinController.text);
      if (mounted && provider.isOfflineLogin) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.wifi_off_rounded, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Expanded(child: Text('Offline mode — sync resumes when online.')),
            ]),
            backgroundColor: const Color(0xFFF59E0B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(e.toString())),
            ]),
            backgroundColor: const Color(0xFFF43F5E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF050810),
      body: Stack(
        children: [
          // ── Animated ambient orbs ──────────────────────────────────
          AnimatedBuilder(
            animation: _orbController,
            builder: (_, child) {
              final t = _orbController.value;
              return Stack(
                children: [
                  Positioned(
                    top: -80 + (t * 40),
                    right: -60 + (t * 30),
                    child: _Orb(size: 320, color: const Color(0xFF6366F1), opacity: 0.12 + t * 0.05),
                  ),
                  Positioned(
                    bottom: -100 + (t * 30),
                    left: -80,
                    child: _Orb(size: 360, color: const Color(0xFF10B981), opacity: 0.07 + t * 0.04),
                  ),
                  Positioned(
                    top: size.height * 0.4 - (t * 20),
                    left: size.width * 0.3,
                    child: _Orb(size: 200, color: const Color(0xFFA855F7), opacity: 0.06 + t * 0.03),
                  ),
                ],
              );
            },
          ),

          // ── Main content ───────────────────────────────────────────
          FadeTransition(
            opacity: _fadeAnim,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ── Logo ──────────────────────────────────────
                      AnimatedBuilder(
                        animation: _orbController,
                        builder: (_, child) {
                          return Container(
                            width: 110,
                            height: 110,
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6366F1), Color(0xFFA855F7), Color(0xFF06B6D4)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF6366F1).withValues(alpha: 0.25 + _orbController.value * 0.15),
                                  blurRadius: 28 + _orbController.value * 12,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF0A0D1A),
                              ),
                              padding: const EdgeInsets.all(10),
                              child: ClipOval(
                                child: Image.asset('assets/logo.png', fit: BoxFit.cover),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 28),

                      // ── Brand Text ────────────────────────────────
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFF818CF8), Colors.white, Color(0xFF818CF8)],
                        ).createShader(bounds),
                        child: const Text(
                          'MY WALLET',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
                        ),
                        child: const Text(
                          'SECURE FINANCE PORTAL',
                          style: TextStyle(
                            color: Color(0xFF818CF8),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2.5,
                          ),
                        ),
                      ),

                      const SizedBox(height: 52),

                      // ── Fields ────────────────────────────────────
                      _GlowField(
                        controller: _mobileController,
                        focusNode: _mobileFocus,
                        label: 'Mobile Number',
                        hint: 'Enter your mobile',
                        icon: Icons.phone_android_rounded,
                        isFocused: _mobileFocused,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      _GlowField(
                        controller: _pinController,
                        focusNode: _pinFocus,
                        label: 'PIN',
                        hint: 'Enter your PIN',
                        icon: Icons.lock_rounded,
                        isFocused: _pinFocused,
                        obscureText: !_showPin,
                        suffix: IconButton(
                          icon: Icon(
                            _showPin ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                            color: const Color(0xFF6366F1).withValues(alpha: 0.7),
                            size: 20,
                          ),
                          onPressed: () => setState(() => _showPin = !_showPin),
                        ),
                      ),

                      const SizedBox(height: 36),

                      // ── Login Button ──────────────────────────────
                      if (_isLoading)
                        Container(
                          height: 58,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFFA855F7)]),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            ),
                          ),
                        )
                      else
                        _ShimmerButton(
                          shimmerController: _shimmerController,
                          label: 'SIGN IN',
                          icon: Icons.arrow_forward_rounded,
                          onPressed: _handleLogin,
                        ),

                      const SizedBox(height: 32),

                      // ── Footer link ───────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Don't have an account? ",
                            style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pushReplacement(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (_, a, b) => const RegisterScreen(),
                                transitionsBuilder: (ctx, anim, secondAnim, child) =>
                                    FadeTransition(opacity: anim, child: child),
                                transitionDuration: const Duration(milliseconds: 400),
                              ),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
                              ),
                              child: const Text(
                                'Register Now',
                                style: TextStyle(
                                  color: Color(0xFF818CF8),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),

                      // ── Bottom decoration ─────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _DotIndicator(active: true),
                          const SizedBox(width: 6),
                          _DotIndicator(active: false),
                          const SizedBox(width: 6),
                          _DotIndicator(active: false),
                        ],
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

// ── Reusable: Ambient Orb ──────────────────────────────────────────────────────
class _Orb extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;
  const _Orb({required this.size, required this.color, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: opacity), Colors.transparent],
          stops: const [0.0, 1.0],
        ),
      ),
    );
  }
}

// ── Reusable: Focus-Glow Glass Input Field ─────────────────────────────────────
class _GlowField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String hint;
  final IconData icon;
  final bool isFocused;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffix;

  const _GlowField({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.hint,
    required this.icon,
    required this.isFocused,
    this.obscureText = false,
    this.keyboardType,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: isFocused
            ? const Color(0xFF6366F1).withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isFocused ? const Color(0xFF6366F1) : Colors.white.withValues(alpha: 0.08),
          width: isFocused ? 1.5 : 1.0,
        ),
        boxShadow: isFocused
            ? [BoxShadow(color: const Color(0xFF6366F1).withValues(alpha: 0.2), blurRadius: 16, spreadRadius: 1)]
            : [],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 13),
          labelStyle: TextStyle(
            color: isFocused ? const Color(0xFF818CF8) : Colors.white38,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
          prefixIcon: Icon(
            icon,
            color: isFocused ? const Color(0xFF6366F1) : Colors.white24,
            size: 20,
          ),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }
}

// ── Reusable: Shimmer Gradient Button ─────────────────────────────────────────
class _ShimmerButton extends StatelessWidget {
  final AnimationController shimmerController;
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _ShimmerButton({
    required this.shimmerController,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: AnimatedBuilder(
        animation: shimmerController,
        builder: (context, child) {
          return Stack(
            children: [
              // Base gradient
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF6366F1), Color(0xFFA855F7)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
              ),
              // Shimmer sweep
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Align(
                  alignment: Alignment(
                    -1.5 + (shimmerController.value * 3.0),
                    0,
                  ),
                  child: Container(
                    width: 80,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.0),
                          Colors.white.withValues(alpha: 0.12),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Button tap area
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  onTap: onPressed,
                  borderRadius: BorderRadius.circular(18),
                  splashColor: Colors.white.withValues(alpha: 0.1),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            letterSpacing: 2.5,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Reusable: Dot page indicator ───────────────────────────────────────────────
class _DotIndicator extends StatelessWidget {
  final bool active;
  const _DotIndicator({required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: active ? 20 : 6,
      height: 6,
      decoration: BoxDecoration(
        color: active ? const Color(0xFF6366F1) : Colors.white12,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
