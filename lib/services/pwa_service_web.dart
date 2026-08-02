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

  bool isUpdateAvailable = false;

  /// Check for Service Worker & PWA updates
  Future<Map<String, dynamic>> checkForUpdates() async {
    try {
      final promise = _checkForUpdatesJS();
      await promise.toDart;
      final bool hasUpdate = isUpdateAvailable;
      return {
        'status': hasUpdate ? 'UPDATE_FOUND' : 'LATEST',
        'hasUpdate': hasUpdate,
        'message': hasUpdate ? 'New app update available!' : 'App is up to date',
      };
    } catch (e) {
      return {
        'status': 'LATEST',
        'hasUpdate': false,
        'message': 'App is running latest cached build',
        'error': e.toString(),
      };
    }
  }

  /// Trigger SW update & skip waiting
  void applyUpdate() {
    try {
      _applyUpdateJS();
    } catch (e) {
      forcePurgeAndReload();
    }
  }

  /// Force purge all caches and reload page
  void forcePurgeAndReload() {
    try {
      _forcePurgeAndReloadJS();
    } catch (_) {}
  }

  /// Request Web Push Notification Permission
  Future<String> requestNotificationPermission() async {
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
    try {
      final jsBool = _isStandaloneJS();
      return jsBool.toDart;
    } catch (_) {
      return false;
    }
  }
}
