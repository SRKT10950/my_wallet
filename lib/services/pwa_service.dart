import 'package:flutter/foundation.dart';

// Conditional JS interop for Web
import 'dart:async';
import 'dart:js_interop' as js;

@js.JS('window.myWalletPwa.checkForUpdates')
external js.JSPromise<js.JSObject> _checkForUpdatesJS();

@js.JS('window.myWalletPwa.applyUpdate')
external void _applyUpdateJS();

@js.JS('window.myWalletPwa.forcePurgeAndReload')
external void _forcePurgeAndReloadJS();

@js.JS('window.myWalletPwa.requestNotificationPermission')
external js.JSPromise<js.JSString> _requestNotificationPermissionJS();

@js.JS('window.myWalletPwa.sendTestNotification')
external js.JSPromise<js.JSBoolean> _sendTestNotificationJS();

@js.JS('window.myWalletPwa.isStandalone')
external js.JSBoolean _isStandaloneJS();

class PwaService {
  static final PwaService _instance = PwaService._internal();
  factory PwaService() => _instance;
  PwaService._internal();

  bool _isUpdateAvailable = false;
  bool get isUpdateAvailable => _isUpdateAvailable;

  /// Check for Service Worker & PWA updates
  Future<Map<String, dynamic>> checkForUpdates() async {
    if (!kIsWeb) {
      return {'status': 'NOT_WEB', 'message': 'Native app mode'};
    }

    try {
      final promise = _checkForUpdatesJS();
      await promise.toDart;
      _isUpdateAvailable = true;
      return {'status': 'SUCCESS'};
    } catch (e) {
      return {'status': 'ERROR', 'error': e.toString()};
    }
  }

  /// Trigger SW update & skip waiting
  void applyUpdate() {
    if (kIsWeb) {
      try {
        _applyUpdateJS();
      } catch (e) {
        forcePurgeAndReload();
      }
    }
  }

  /// Force purge all caches and reload page
  void forcePurgeAndReload() {
    if (kIsWeb) {
      try {
        _forcePurgeAndReloadJS();
      } catch (_) {}
    }
  }

  /// Request Web Push Notification Permission
  Future<String> requestNotificationPermission() async {
    if (!kIsWeb) return 'UNSUPPORTED';
    try {
      final promise = _requestNotificationPermissionJS();
      final jsStr = await promise.toDart;
      return jsStr.toDart;
    } catch (e) {
      return 'ERROR: ${e.toString()}';
    }
  }

  /// Send Test Web Push Notification
  Future<bool> sendTestNotification() async {
    if (!kIsWeb) return false;
    try {
      final promise = _sendTestNotificationJS();
      final jsBool = await promise.toDart;
      return jsBool.toDart;
    } catch (e) {
      return false;
    }
  }

  /// Check if running in installed Standalone PWA mode
  bool isStandalone() {
    if (!kIsWeb) return true; // Mobile/Desktop native apps are standalone
    try {
      final jsBool = _isStandaloneJS();
      return jsBool.toDart;
    } catch (_) {
      return false;
    }
  }
}
