import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/finance_provider.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with TickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  final _nameFocus = FocusNode();
  final _mobileFocus = FocusNode();
  final _pinFocus = FocusNode();
  final _confirmPinFocus = FocusNode();

  bool _isLoading = false;
  bool _showPin = false;
  bool _showConfirmPin = false;

  bool _nameFocused = false;
  bool _mobileFocused = false;
  bool _pinFocused = false;
  bool _confirmPinFocused = false;

  late AnimationController _orbController;
  late AnimationController _shimmerController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  String get _initials {
    final parts = _nameController.text.trim().split(' ');
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  int get _pinStrength {
    final pin = _pinController.text;
    if (pin.isEmpty) return 0;
    if (pin.length < 4) return 1;
    if (pin.length < 6) return 2;
    return 3;
  }

  Color get _pinStrengthColor {
    switch (_pinStrength) {
      case 1: return const Color(0xFFF43F5E);
      case 2: return const Color(0xFFF59E0B);
      case 3: return const Color(0xFF10B981);
      default: return Colors.transparent;
    }
  }

  String get _pinStrengthLabel {
    switch (_pinStrength) {
      case 1: return 'Weak';
      case 2: return 'Fair';
      case 3: return 'Strong';
      default: return '';
    }
  }

  @override
  void initState() {
    super.initState();
    _orbController = AnimationController(vsync: this, duration: const Duration(seconds: 9))..repeat(reverse: true);
    _shimmerController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();

    _nameFocus.addListener(() => setState(() => _nameFocused = _nameFocus.hasFocus));
    _mobileFocus.addListener(() => setState(() => _mobileFocused = _mobileFocus.hasFocus));
    _pinFocus.addListener(() => setState(() => _pinFocused = _pinFocus.hasFocus));
    _confirmPinFocus.addListener(() => setState(() => _confirmPinFocused = _confirmPinFocus.hasFocus));

    _nameController.addListener(() => setState(() {}));
    _pinController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _orbController.dispose();
    _shimmerController.dispose();
    _fadeController.dispose();
    _nameFocus.dispose();
    _mobileFocus.dispose();
    _pinFocus.dispose();
    _confirmPinFocus.dispose();
    _nameController.dispose();
    _mobileController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_nameController.text.isEmpty || _mobileController.text.isEmpty || _pinController.text.isEmpty) {
      _showSnack('Please fill all fields', const Color(0xFFF59E0B), Icons.warning_amber_rounded);
      return;
    }
    if (_pinController.text != _confirmPinController.text) {
      _showSnack('PINs do not match', const Color(0xFFF43F5E), Icons.lock_outline);
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
      if (mounted) _showSnack(e.toString(), const Color(0xFFF43F5E), Icons.error_outline);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(msg)),
        ]),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
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
            builder: (context, child) {
              final t = _orbController.value;
              return Stack(
                children: [
                  Positioned(
                    top: -60 + (t * 50),
                    left: -80,
                    child: _OrbWidget(size: 300, color: const Color(0xFFA855F7), opacity: 0.10 + t * 0.05),
                  ),
                  Positioned(
                    bottom: -80,
                    right: -60 + (t * 30),
                    child: _OrbWidget(size: 340, color: const Color(0xFF10B981), opacity: 0.07 + t * 0.04),
                  ),
                  Positioned(
                    top: size.height * 0.45,
                    right: size.width * 0.1,
                    child: _OrbWidget(size: 180, color: const Color(0xFF6366F1), opacity: 0.06 + t * 0.04),
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
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Top header: avatar + title ─────────────────
                      Row(
                        children: [
                          // Animated avatar with initials
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                                  blurRadius: 18,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                _initials,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 18),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ShaderMask(
                                shaderCallback: (bounds) => const LinearGradient(
                                  colors: [Color(0xFF818CF8), Colors.white],
                                ).createShader(bounds),
                                child: const Text(
                                  'CREATE ACCOUNT',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                                ),
                                child: const Text(
                                  'NEW MEMBER SETUP',
                                  style: TextStyle(
                                    color: Color(0xFF10B981),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 36),

                      // ── Step progress indicator ────────────────────
                      _StepProgressBar(
                        filledCount: _nameController.text.isNotEmpty
                            ? (_mobileController.text.isNotEmpty ? (_pinController.text.isNotEmpty ? 3 : 2) : 1)
                            : 0,
                      ),

                      const SizedBox(height: 32),

                      // ── Fields ─────────────────────────────────────
                      _RegGlowField(
                        controller: _nameController,
                        focusNode: _nameFocus,
                        label: 'Full Name',
                        hint: 'Your full name',
                        icon: Icons.person_rounded,
                        isFocused: _nameFocused,
                      ),
                      const SizedBox(height: 14),
                      _RegGlowField(
                        controller: _mobileController,
                        focusNode: _mobileFocus,
                        label: 'Mobile Number',
                        hint: 'Your mobile number',
                        icon: Icons.phone_android_rounded,
                        isFocused: _mobileFocused,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 14),
                      _RegGlowField(
                        controller: _pinController,
                        focusNode: _pinFocus,
                        label: 'PIN',
                        hint: 'Create a secure PIN',
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

                      // PIN strength bar
                      if (_pinController.text.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            ...List.generate(3, (i) => Expanded(
                              child: Container(
                                margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                                height: 4,
                                decoration: BoxDecoration(
                                  color: i < _pinStrength ? _pinStrengthColor : Colors.white10,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            )),
                            const SizedBox(width: 10),
                            Text(
                              _pinStrengthLabel,
                              style: TextStyle(
                                color: _pinStrengthColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 14),
                      _RegGlowField(
                        controller: _confirmPinController,
                        focusNode: _confirmPinFocus,
                        label: 'Confirm PIN',
                        hint: 'Repeat your PIN',
                        icon: Icons.lock_outline_rounded,
                        isFocused: _confirmPinFocused,
                        obscureText: !_showConfirmPin,
                        suffix: IconButton(
                          icon: Icon(
                            _showConfirmPin ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                            color: const Color(0xFF6366F1).withValues(alpha: 0.7),
                            size: 20,
                          ),
                          onPressed: () => setState(() => _showConfirmPin = !_showConfirmPin),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ── Register Button ────────────────────────────
                      if (_isLoading)
                        Container(
                          height: 58,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4F46E5), Color(0xFFA855F7)],
                            ),
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
                        _RegShimmerButton(
                          shimmerController: _shimmerController,
                          onPressed: _handleRegister,
                        ),

                      const SizedBox(height: 28),

                      // ── Already registered? ────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Already have an account? ',
                            style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pushReplacement(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (_, a, b) => const LoginScreen(),
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
                                'Sign In',
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

// ── Step Progress Bar ──────────────────────────────────────────────────────────
class _StepProgressBar extends StatelessWidget {
  final int filledCount;
  const _StepProgressBar({required this.filledCount});

  static const _steps = ['Profile', 'Contact', 'Security'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(_steps.length, (i) {
        final filled = i < filledCount;
        final active = i == filledCount;
        return Expanded(
          child: Row(
            children: [
              if (i > 0)
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    height: 2,
                    color: filled ? const Color(0xFF6366F1) : Colors.white10,
                  ),
                ),
              Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: filled || active
                          ? const LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: (!filled && !active) ? Colors.white.withValues(alpha: 0.05) : null,
                      border: active
                          ? Border.all(color: const Color(0xFF6366F1), width: 2)
                          : null,
                      boxShadow: filled || active
                          ? [BoxShadow(color: const Color(0xFF6366F1).withValues(alpha: 0.4), blurRadius: 10)]
                          : [],
                    ),
                    child: Center(
                      child: filled
                          ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                          : Text(
                              '${i + 1}',
                              style: TextStyle(
                                color: active ? const Color(0xFF6366F1) : Colors.white30,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _steps[i],
                    style: TextStyle(
                      color: filled || active ? const Color(0xFF818CF8) : Colors.white24,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              if (i < _steps.length - 1)
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    height: 2,
                    color: filled ? const Color(0xFF6366F1) : Colors.white10,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

// ── Orb ───────────────────────────────────────────────────────────────────────
class _OrbWidget extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;
  const _OrbWidget({required this.size, required this.color, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: opacity), Colors.transparent],
        ),
      ),
    );
  }
}

// ── Glow Input Field ──────────────────────────────────────────────────────────
class _RegGlowField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String hint;
  final IconData icon;
  final bool isFocused;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffix;

  const _RegGlowField({
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
          prefixIcon: Icon(icon, color: isFocused ? const Color(0xFF6366F1) : Colors.white24, size: 20),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }
}

// ── Shimmer Register Button ────────────────────────────────────────────────────
class _RegShimmerButton extends StatelessWidget {
  final AnimationController shimmerController;
  final VoidCallback onPressed;

  const _RegShimmerButton({required this.shimmerController, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: AnimatedBuilder(
        animation: shimmerController,
        builder: (context, child) {
          return Stack(
            children: [
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
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Align(
                  alignment: Alignment(-1.5 + shimmerController.value * 3.0, 0),
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
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  onTap: onPressed,
                  borderRadius: BorderRadius.circular(18),
                  splashColor: Colors.white.withValues(alpha: 0.1),
                  child: const Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'CREATE ACCOUNT',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            letterSpacing: 2,
                          ),
                        ),
                        SizedBox(width: 10),
                        Icon(Icons.person_add_rounded, color: Colors.white, size: 18),
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
