import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
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
class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  final _client = http.Client();
  bool _isSchemaInitialized = false;

  /// Safely interpolates `?` placeholders with properly escaped values.
  String _interpolateSql(String sql, List<dynamic>? params) {
    if (params == null || params.isEmpty) return sql;

    int paramIndex = 0;
    final buffer = StringBuffer();

    for (int i = 0; i < sql.length; i++) {
      if (sql[i] == '?' && paramIndex < params.length) {
        final val = params[paramIndex++];
        if (val == null) {
          buffer.write('NULL');
        } else if (val is num) {
          buffer.write(val.toString());
        } else if (val is bool) {
          buffer.write(val ? '1' : '0');
        } else {
          final escaped = val.toString().replaceAll("'", "''");
          buffer.write("'$escaped'");
        }
      } else {
        buffer.write(sql[i]);
      }
    }
    return buffer.toString();
  }

  /// Execute a raw SQL query against the My Wallet database.
  Future<DbResult> query(String sql, [List<dynamic>? params]) async {
    try {
      final device = DeviceService.instance;
      final finalQuery = _interpolateSql(sql, params);

      final response = await _client.post(
        Uri.parse(AppConstants.dbBaseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': AppConstants.apiKey,
          'x-app-name': device.deviceName,
          'x-device-id': device.deviceId,
        },
        body: jsonEncode({
          'query': finalQuery,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);

        if (data is List) {
          return DbResult(
            success: true,
            rows: List<Map<String, dynamic>>.from(data),
          );
        }

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

  // ── Schema Initialization & Auto-Migration ─────────────────────────

  /// Creates required tables and auto-migrates missing columns on first run.
  /// Uses SharedPreferences caching so it runs in 1ms on subsequent opens.
  Future<void> initializeSchema() async {
    if (_isSchemaInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final isDone = prefs.getBool('db_schema_v3_ready') ?? false;
      if (isDone) {
        _isSchemaInitialized = true;
        return;
      }

      await _createUsersTable();
      await _migrateUsersTable();

      await prefs.setBool('db_schema_v3_ready', true);
      _isSchemaInitialized = true;
    } catch (_) {
      // Fallback silently if offline or network error
    }
  }

  Future<void> _createUsersTable() async {
    await query('''
      CREATE TABLE IF NOT EXISTS users (
        ${DbBaseFields.columnDefinitions},
        name           TEXT NOT NULL,
        mobile         TEXT NOT NULL UNIQUE,
        mobile_number  TEXT,
        password_hash  TEXT,
        pin            TEXT,
        otp_code       TEXT,
        otp_expires_at TEXT,
        is_verified    INTEGER NOT NULL DEFAULT 0,
        last_login     TEXT
      )
    ''');
  }

  Future<void> _migrateUsersTable() async {
    final migrations = [
      'ALTER TABLE users ADD COLUMN IF NOT EXISTS id VARCHAR(50)',
      'ALTER TABLE users ADD COLUMN IF NOT EXISTS mobile VARCHAR(50)',
      'ALTER TABLE users ADD COLUMN IF NOT EXISTS mobile_number VARCHAR(50)',
      'ALTER TABLE users ADD COLUMN IF NOT EXISTS password_hash VARCHAR(255)',
      'ALTER TABLE users ADD COLUMN IF NOT EXISTS pin VARCHAR(50)',
      'ALTER TABLE users ADD COLUMN IF NOT EXISTS otp_code VARCHAR(10)',
      'ALTER TABLE users ADD COLUMN IF NOT EXISTS otp_expires_at VARCHAR(50)',
      'ALTER TABLE users ADD COLUMN IF NOT EXISTS is_verified INTEGER DEFAULT 0',
      'ALTER TABLE users ADD COLUMN IF NOT EXISTS updated_at VARCHAR(50)',
      'ALTER TABLE users ADD COLUMN IF NOT EXISTS created_by VARCHAR(50)',
      'ALTER TABLE users ADD COLUMN IF NOT EXISTS updated_by VARCHAR(50)',
      'ALTER TABLE users ADD COLUMN IF NOT EXISTS deleted_at VARCHAR(50)',
      'ALTER TABLE users ADD COLUMN IF NOT EXISTS deleted_by VARCHAR(50)',
      'ALTER TABLE users ADD COLUMN IF NOT EXISTS is_deleted INTEGER DEFAULT 0',
      'ALTER TABLE users ADD COLUMN IF NOT EXISTS version INTEGER DEFAULT 1',
      'ALTER TABLE users ADD COLUMN IF NOT EXISTS status VARCHAR(20) DEFAULT \'active\'',
      'ALTER TABLE users ADD COLUMN IF NOT EXISTS tenant_id VARCHAR(50)',
      'ALTER TABLE users ADD COLUMN IF NOT EXISTS remarks TEXT',
      'ALTER TABLE users ADD COLUMN IF NOT EXISTS metadata TEXT',
      'ALTER TABLE users ADD COLUMN IF NOT EXISTS last_login VARCHAR(50)',
      'UPDATE users SET mobile = mobile_number WHERE mobile IS NULL AND mobile_number IS NOT NULL',
      'UPDATE users SET is_deleted = 0 WHERE is_deleted IS NULL',
      'UPDATE users SET is_verified = 1 WHERE is_verified IS NULL OR pin IS NOT NULL',
      'UPDATE users SET status = \'active\' WHERE status IS NULL',
      'UPDATE users SET version = 1 WHERE version IS NULL',
    ];

    for (final sql in migrations) {
      await query(sql);
    }
  }

  // ── Generic Helpers ───────────────────────────────────────────────

  Future<DbResult> insertRecord(
      String table, Map<String, dynamic> fields) async {
    final insert = DbBaseFields.buildInsertClause(fields);
    return query(
      'INSERT INTO $table (${insert.columns}) VALUES (${insert.placeholders})',
      insert.params,
    );
  }

  Future<DbResult> updateRecord(
    String table,
    String id,
    Map<String, dynamic> updateFields,
  ) async {
    final set = DbBaseFields.buildSetClause(updateFields);
    return query(
      'UPDATE $table SET ${set.clause} WHERE id = ? AND (is_deleted = 0 OR is_deleted IS NULL)',
      [...set.params, id],
    );
  }

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
