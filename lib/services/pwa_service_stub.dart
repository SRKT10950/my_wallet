import 'dart:async';

class PwaService {
  static final PwaService _instance = PwaService._internal();
  factory PwaService() => _instance;
  PwaService._internal();

  bool isUpdateAvailable = false;

  Future<Map<String, dynamic>> checkForUpdates() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return {
      'status': 'LATEST',
      'hasUpdate': false,
      'message': 'Running latest native build (v1.0.2+3)',
    };
  }

  void applyUpdate() {}

  void forcePurgeAndReload() {}

  Future<String> requestNotificationPermission() async {
    return 'UNSUPPORTED';
  }

  Future<bool> sendTestNotification() async {
    return false;
  }

  bool isStandalone() {
    return true;
  }
}
