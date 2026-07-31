import 'package:shared_preferences/shared_preferences.dart';

/// App Currency Definition
class CurrencyOption {
  final String code;
  final String symbol;
  final String name;

  const CurrencyOption({
    required this.code,
    required this.symbol,
    required this.name,
  });
}

/// App Language Definition
class LanguageOption {
  final String code;
  final String name;
  final String nativeName;

  const LanguageOption({
    required this.code,
    required this.name,
    required this.nativeName,
  });
}

/// Service managing app-wide settings (Currency, Default Income, Language).
class SettingsService {
  SettingsService._();
  static final SettingsService instance = SettingsService._();

  static const String _keyCurrencyCode = 'setting_currency_code';
  static const String _keyCurrencySymbol = 'setting_currency_symbol';
  static const String _keyDefaultIncome = 'setting_default_income';
  static const String _keyAppLanguage = 'setting_app_language';

  // ── Available Currencies ───────────────────────────────────────────
  static const List<CurrencyOption> availableCurrencies = [
    CurrencyOption(code: 'INR', symbol: '₹', name: 'Indian Rupee (INR)'),
    CurrencyOption(code: 'USD', symbol: '\$', name: 'US Dollar (USD)'),
    CurrencyOption(code: 'EUR', symbol: '€', name: 'Euro (EUR)'),
    CurrencyOption(code: 'GBP', symbol: '£', name: 'British Pound (GBP)'),
    CurrencyOption(code: 'AED', symbol: 'AED', name: 'UAE Dirham (AED)'),
  ];

  // ── Available Languages ────────────────────────────────────────────
  static const List<LanguageOption> availableLanguages = [
    LanguageOption(code: 'en', name: 'English', nativeName: 'English'),
    LanguageOption(code: 'hi', name: 'Hindi', nativeName: 'हिन्दी'),
    LanguageOption(code: 'mr', name: 'Marathi', nativeName: 'मराठी'),
    LanguageOption(code: 'gu', name: 'Gujarati', nativeName: 'ગુજરાતી'),
    LanguageOption(code: 'ta', name: 'Tamil', nativeName: 'தமிழ்'),
  ];

  // ── Currency ───────────────────────────────────────────────────────
  Future<CurrencyOption> getCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_keyCurrencyCode) ?? 'INR';
    final symbol = prefs.getString(_keyCurrencySymbol) ?? '₹';
    return availableCurrencies.firstWhere(
      (c) => c.code == code,
      orElse: () => CurrencyOption(code: code, symbol: symbol, name: code),
    );
  }

  Future<void> setCurrency(CurrencyOption option) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCurrencyCode, option.code);
    await prefs.setString(_keyCurrencySymbol, option.symbol);
  }

  // ── Default Income ─────────────────────────────────────────────────
  Future<double> getDefaultIncome() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyDefaultIncome) ?? 85000.0;
  }

  Future<void> setDefaultIncome(double amount) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyDefaultIncome, amount);
  }

  // ── App Language ───────────────────────────────────────────────────
  Future<LanguageOption> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_keyAppLanguage) ?? 'en';
    return availableLanguages.firstWhere(
      (l) => l.code == code,
      orElse: () => availableLanguages.first,
    );
  }

  Future<void> setLanguage(LanguageOption lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAppLanguage, lang.code);
  }
}
