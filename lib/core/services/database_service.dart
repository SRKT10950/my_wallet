import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../db/db_base_fields.dart';
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
          if (data.containsKey('error')) {
            return DbResult(
              success: false,
              error: data['error'].toString(),
            );
          }
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

  // ── Schema Initialization ─────────────────────────────────────────

  /// Creates all required tables on first run (if not exist).
  /// All tables use the standardized base fields from [DbBaseFields].
  Future<void> initializeSchema() async {
    await _createUsersTable();
  }

  Future<void> _createUsersTable() async {
    await query('''
      CREATE TABLE IF NOT EXISTS users (
        ${DbBaseFields.columnDefinitions},
        name          TEXT NOT NULL,
        email         TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        last_login    TEXT
      )
    ''');
  }

  // ── Generic Helpers ───────────────────────────────────────────────

  /// Insert a record into [table] using a pre-built fields map.
  /// Returns the DbResult from the API.
  Future<DbResult> insertRecord(
      String table, Map<String, dynamic> fields) async {
    final insert = DbBaseFields.buildInsertClause(fields);
    return query(
      'INSERT INTO $table (${insert.columns}) VALUES (${insert.placeholders})',
      insert.params,
    );
  }

  /// Update a record in [table] identified by [id],
  /// applying only the fields in [updateFields].
  Future<DbResult> updateRecord(
    String table,
    String id,
    Map<String, dynamic> updateFields,
  ) async {
    final set = DbBaseFields.buildSetClause(updateFields);
    return query(
      'UPDATE $table SET ${set.clause} WHERE id = ? AND ${DbBaseFields.notDeleted}',
      [...set.params, id],
    );
  }

  /// Soft-delete a record in [table] by [id].
  Future<DbResult> softDelete(
    String table,
    String id, {
    required String deletedBy,
    required int currentVersion,
  }) async {
    final fields = DbBaseFields.softDeleteRecord(
      deletedBy: deletedBy,
      currentVersion: currentVersion,
    );
    final set = DbBaseFields.buildSetClause(fields);
    return query(
      'UPDATE $table SET ${set.clause} WHERE id = ?',
      [...set.params, id],
    );
  }
}
