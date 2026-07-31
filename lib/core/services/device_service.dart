import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../constants/app_constants.dart';

/// Provides device name and a persistent unique device ID.
class DeviceService {
  DeviceService._();
  static final DeviceService instance = DeviceService._();

  String _deviceName = AppConstants.appName;
  String _deviceId = '';

  String get deviceName => _deviceName;
  String get deviceId => _deviceId;

  /// Must be called once at app startup (before any API calls).
  Future<void> initialize() async {
    _deviceId = await _getOrCreateDeviceId();
    _deviceName = await _resolveDeviceName();
  }

  // ── Device ID ──────────────────────────────────────────────────────
  Future<String> _getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString(AppConstants.keyDeviceId);
    if (id == null || id.isEmpty) {
      id = const Uuid().v4();
      await prefs.setString(AppConstants.keyDeviceId, id);
    }
    return id;
  }

  // ── Device Name ────────────────────────────────────────────────────
  Future<String> _resolveDeviceName() async {
    try {
      final info = DeviceInfoPlugin();
      if (kIsWeb) {
        final web = await info.webBrowserInfo;
        return web.browserName.name;
      }
      if (Platform.isAndroid) {
        final android = await info.androidInfo;
        return '${android.manufacturer} ${android.model}';
      }
      if (Platform.isIOS) {
        final ios = await info.iosInfo;
        return ios.name;
      }
      if (Platform.isWindows) {
        final win = await info.windowsInfo;
        return win.computerName;
      }
      if (Platform.isMacOS) {
        final mac = await info.macOsInfo;
        return mac.computerName;
      }
      if (Platform.isLinux) {
        final linux = await info.linuxInfo;
        return linux.name;
      }
    } catch (_) {
      // Fallback silently
    }
    return AppConstants.appName;
  }
}
