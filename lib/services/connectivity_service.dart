import 'package:flutter/foundation.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal() {
    _init();
  }

  final ValueNotifier<bool> isOnline = ValueNotifier<bool>(true);

  void _init() {
    if (kIsWeb) {
      try {
        isOnline.value = true;
      } catch (_) {}
    }
  }

  void setOnlineStatus(bool status) {
    if (isOnline.value != status) {
      isOnline.value = status;
    }
  }
}
