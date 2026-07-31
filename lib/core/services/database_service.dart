import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../services/device_service.dart';

/// Result wrapper for all database operations.
class DbResult {
  final bool success;
  final List<Map<String, dynamic>> rows;
  final String? error;
  final int? affectedRows;

  const DbResult({
    required this.success,
    this.rows = const [],
    this.error,
    this.affectedRows,
  });

  bool get isEmpty => rows.isEmpty;
  bool get isNotEmpty => rows.isNotEmpty;
}

/// Low-level database service that wraps the My Wallet REST API.
///
/// Every request is automatically injected with:
///   - `x-api-key`
///   - `x-app-name`  (device name)
///   - `x-device-id` (unique installation ID)
class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  final _client = http.Client();

  /// Execute a raw SQL query against the My Wallet database.
  ///
  /// [sql]    — SQL query string with `?` placeholders.
  /// [params] — List of values to bind to placeholders (optional).
  Future<DbResult> query(String sql, [List<dynamic>? params]) async {
    try {
      final device = DeviceService.instance;

      final response = await _client.post(
        Uri.parse(AppConstants.dbBaseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': AppConstants.apiKey,
          'x-app-name': device.deviceName,
          'x-device-id': device.deviceId,
        },
        body: jsonEncode({
          'query': sql,
          if (params != null && params.isNotEmpty) 'params': params,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);

        // Handle array response (SELECT)
        if (data is List) {
          return DbResult(
            success: true,
            rows: List<Map<String, dynamic>>.from(data),
          );
        }

        // Handle object response (INSERT / UPDATE / DELETE)
        if (data is Map<String, dynamic>) {
          // Check for error field in body
          if (data.containsKey('error')) {
            return DbResult(
              success: false,
              error: data['error'].toString(),
            );
          }
          // Wrap single row selects
          if (data.containsKey('rows')) {
            return DbResult(
              success: true,
              rows: List<Map<String, dynamic>>.from(data['rows'] ?? []),
              affectedRows: data['affectedRows'] as int?,
            );
          }
          return DbResult(
            success: true,
            rows: [data],
            affectedRows: data['affectedRows'] as int?,
          );
        }

        return const DbResult(success: true);
      } else {
        final body = response.body;
        String errorMsg = 'HTTP ${response.statusCode}';
        try {
          final decoded = jsonDecode(body);
          errorMsg = decoded['error'] ?? decoded['message'] ?? errorMsg;
        } catch (_) {
          errorMsg = body.isNotEmpty ? body : errorMsg;
        }
        return DbResult(success: false, error: errorMsg);
      }
    } catch (e) {
      return DbResult(
        success: false,
        error: 'Network error: ${e.toString()}',
      );
    }
  }

  /// Initialize required tables on first run.
  Future<void> initializeSchema() async {
    await query('''
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        created_at TEXT NOT NULL,
        last_login TEXT
      )
    ''');
  }
}
