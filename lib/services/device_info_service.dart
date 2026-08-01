import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';

class DeviceInfoService {
  static const String _keyDeviceId = 'mwallet_device_id';
  static String? _cachedDeviceId;

  /// Returns a persistent unique device ID for multi-device sync tracking.
  static Future<String> getDeviceId() async {
    if (_cachedDeviceId != null) return _cachedDeviceId!;

    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString(_keyDeviceId);

    if (deviceId == null || deviceId.isEmpty) {
      final random = Random.secure();
      final values = List<int>.generate(16, (i) => random.nextInt(256));
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final platformTag = kIsWeb ? 'web' : 'app';
      deviceId = '$platformTag-${timestamp.toRadixString(36)}-${values.take(6).map((e) => e.toRadixString(16).padLeft(2, '0')).join()}';
      await prefs.setString(_keyDeviceId, deviceId);
    }

    _cachedDeviceId = deviceId;
    return deviceId;
  }
}
