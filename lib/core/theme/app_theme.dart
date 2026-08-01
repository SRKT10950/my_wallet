import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary Brand Tokens
  static const Color primary = Color(0xFF6366F1); // Indigo Primary
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF4F46E5);

  // Secondary & Accents
  static const Color secondary = Color(0xFF06B6D4); // Vibrant Cyan
  static const Color accentViolet = Color(0xFFA855F7); // Electric Violet
  static const Color emerald = Color(0xFF10B981); // Positive / Income
  static const Color rose = Color(0xFFF43F5E); // Negative / Expense
  static const Color amber = Color(0xFFF59E0B); // Warning / Pending

  // Dark Theme Surfaces
  static const Color darkBackground = Color(0xFF070913);
  static const Color darkSurface = Color(0xFF0F1222);
  static const Color darkSurfaceElevated = Color(0xFF171B33);
  static const Color darkBorder = Color(0xFF262B4A);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextMuted = Color(0xFF64748B);

  // Light Theme Surfaces
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFF1F5F9);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextMuted = Color(0xFF64748B);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient emeraldGradient = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient roseGradient = LinearGradient(
    colors: [Color(0xFFE11D48), Color(0xFFF43F5E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppStatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const AppStatusBadge({
    super.key,
    required this.label,
    required this.color,
  });

  factory AppStatusBadge.paid({String label = 'Paid'}) =>
      AppStatusBadge(label: label, color: AppColors.emerald);

  factory AppStatusBadge.pending({String label = 'Pending'}) =>
      AppStatusBadge(label: label, color: AppColors.amber);

  factory AppStatusBadge.overdue({String label = 'Overdue'}) =>
      AppStatusBadge(label: label, color: AppColors.rose);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class AppGlassDecoration {
  static BoxDecoration card(
    BuildContext context, {
    Color? color,
    BorderRadius? borderRadius,
    Color? borderColor,
    bool isFocused = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final defaultBorder = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return BoxDecoration(
      color: color ?? defaultBg,
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      border: Border.all(
        color: isFocused
            ? AppColors.primary
            : (borderColor ?? defaultBorder),
        width: isFocused ? 2.0 : 1.0,
      ),
      boxShadow: [
        BoxShadow(
          color: isFocused
              ? AppColors.primary.withValues(alpha: 0.25)
              : (isDark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.04)),
          blurRadius: isFocused ? 20 : 14,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.darkSurface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.darkTextPrimary,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: AppColors.darkTextPrimary,
        displayColor: AppColors.darkTextPrimary,
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        elevation: 0,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.darkTextPrimary),
        titleTextStyle: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: AppColors.darkTextPrimary,
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData.light().copyWith(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryDark,
        secondary: AppColors.secondary,
        surface: AppColors.lightSurface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.lightTextPrimary,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme).apply(
        bodyColor: AppColors.lightTextPrimary,
        displayColor: AppColors.lightTextPrimary,
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
        elevation: 0,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.lightTextPrimary),
        titleTextStyle: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: AppColors.lightTextPrimary,
        ),
      ),
    );
  }
}
