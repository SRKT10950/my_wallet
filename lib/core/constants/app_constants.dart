/// App-wide constants for My Wallet.
class AppConstants {
  AppConstants._();

  // ── App ──────────────────────────────────────────────────────────────
  static const String appName = 'My Wallet';
  static const String appVersion = '1.0.0';

  // ── Database API ─────────────────────────────────────────────────────
  static const String dbBaseUrl =
      'https://db.mhservice.co.in/api/db/my_wallet/query';
  static const String apiKey = 'hs_live_U74MhX82o5lOUmzAmXxKsbX3fxNKImkl';

  // ── Storage Keys ─────────────────────────────────────────────────────
  static const String keyDeviceId = 'device_id';
  static const String keyAuthToken = 'auth_token';
  static const String keyUserId = 'user_id';       // stored as String UUID
  static const String keyUserName = 'user_name';
  static const String keyUserEmail = 'user_email';

  // ── Routes ───────────────────────────────────────────────────────────
  static const String routeSplash = '/';
  static const String routeLogin = '/login';
  static const String routeRegister = '/register';
  static const String routeHome = '/home';
}
