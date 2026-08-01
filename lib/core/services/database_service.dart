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
  Future<void> initializeSchema() async {
    if (_isSchemaInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final isDone = prefs.getBool('db_schema_v8_daily_purchases_ready') ?? false;
      if (isDone) {
        _isSchemaInitialized = true;
        return;
      }

      await _createUsersTable();
      await _migrateUsersTable();
      await _createContactsTable();
      await _createCategoriesTable();
      await _createProductsTable();
      await _createProductPriceHistoryTable();
      await _createDailyPurchasesTable();
      await _createDailyPurchaseItemsTable();
      await _createDailyPaymentHistoryTable();

      await prefs.setBool('db_schema_v8_daily_purchases_ready', true);
      _isSchemaInitialized = true;
    } catch (_) {
      // Fallback silently if offline
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

  Future<void> _createContactsTable() async {
    await query('''
      CREATE TABLE IF NOT EXISTS contacts (
        ${DbBaseFields.columnDefinitions},
        owner_name           TEXT NOT NULL,
        mobile_number        TEXT NOT NULL,
        business_shop_name   TEXT,
        place_city           TEXT,
        is_active            INTEGER NOT NULL DEFAULT 1,
        enable_notification  INTEGER NOT NULL DEFAULT 1,
        notification_method  TEXT NOT NULL DEFAULT 'WhatsApp'
      )
    ''');
  }

  Future<void> _createCategoriesTable() async {
    await query('''
      CREATE TABLE IF NOT EXISTS categories (
        ${DbBaseFields.columnDefinitions},
        category_name  TEXT NOT NULL,
        category_type  TEXT NOT NULL DEFAULT 'expense',
        icon_name      TEXT DEFAULT 'category',
        color_hex      TEXT DEFAULT '#6C3DE8'
      )
    ''');
  }

  Future<void> _createProductsTable() async {
    await query('''
      CREATE TABLE IF NOT EXISTS products (
        ${DbBaseFields.columnDefinitions},
        product_code          TEXT NOT NULL,
        product_name_english  TEXT NOT NULL,
        product_name_local    TEXT,
        language_code         TEXT DEFAULT 'hi',
        category_id           TEXT,
        category_name         TEXT DEFAULT 'General',
        brand                 TEXT,
        description           TEXT,
        unit                  TEXT DEFAULT 'Piece',
        old_price             NUMERIC(12,2) DEFAULT 0.00,
        current_price         NUMERIC(12,2) NOT NULL DEFAULT 0.00,
        market_price          NUMERIC(12,2) DEFAULT 0.00,
        currency              TEXT DEFAULT '₹',
        effective_date        TEXT,
        expiry_date           TEXT,
        price_difference      NUMERIC(12,2) DEFAULT 0.00,
        price_trend           TEXT DEFAULT 'no_change',
        barcode               TEXT,
        barcode_type          TEXT DEFAULT 'Code128',
        qr_code               TEXT,
        sku                   TEXT,
        hsn_code              TEXT,
        gst_percentage        NUMERIC(5,2) DEFAULT 0.00,
        manufacturer          TEXT,
        country               TEXT DEFAULT 'India',
        reference_link        TEXT,
        application_name      TEXT DEFAULT 'My Wallet',
        image_url             TEXT,
        thumbnail_url         TEXT,
        status_badge          TEXT DEFAULT 'Active',
        is_active             INTEGER NOT NULL DEFAULT 1
      )
    ''');
  }

  Future<void> _createProductPriceHistoryTable() async {
    await query('''
      CREATE TABLE IF NOT EXISTS product_price_history (
        ${DbBaseFields.columnDefinitions},
        product_id      TEXT NOT NULL,
        old_price       NUMERIC(12,2) DEFAULT 0.00,
        new_price       NUMERIC(12,2) NOT NULL DEFAULT 0.00,
        market_price    NUMERIC(12,2) DEFAULT 0.00,
        effective_date  TEXT NOT NULL,
        updated_by_user TEXT NOT NULL DEFAULT 'System'
      )
    ''');
  }

  Future<void> _createDailyPurchasesTable() async {
    await query('''
      CREATE TABLE IF NOT EXISTS daily_purchases (
        ${DbBaseFields.columnDefinitions},
        purchase_id       TEXT NOT NULL,
        bill_number       TEXT NOT NULL,
        invoice_number    TEXT,
        shop_name         TEXT NOT NULL,
        shop_type         TEXT DEFAULT 'General',
        billing_date      TEXT NOT NULL,
        due_date          TEXT,
        payment_date      TEXT,
        currency          TEXT DEFAULT '₹',
        subtotal          NUMERIC(12,2) NOT NULL DEFAULT 0.00,
        discount          NUMERIC(12,2) DEFAULT 0.00,
        tax               NUMERIC(12,2) DEFAULT 0.00,
        delivery_charge   NUMERIC(12,2) DEFAULT 0.00,
        packing_charge    NUMERIC(12,2) DEFAULT 0.00,
        other_charge      NUMERIC(12,2) DEFAULT 0.00,
        round_off         NUMERIC(12,2) DEFAULT 0.00,
        grand_total       NUMERIC(12,2) NOT NULL DEFAULT 0.00,
        amount_paid       NUMERIC(12,2) NOT NULL DEFAULT 0.00,
        due_amount        NUMERIC(12,2) NOT NULL DEFAULT 0.00,
        payment_status    TEXT DEFAULT 'Paid',
        payment_method    TEXT DEFAULT 'Cash',
        cashback          NUMERIC(12,2) DEFAULT 0.00,
        reward_points     INTEGER DEFAULT 0,
        notes             TEXT
      )
    ''');
  }

  Future<void> _createDailyPurchaseItemsTable() async {
    await query('''
      CREATE TABLE IF NOT EXISTS daily_purchase_items (
        ${DbBaseFields.columnDefinitions},
        purchase_id    TEXT NOT NULL,
        product_id     TEXT,
        product_name   TEXT NOT NULL,
        barcode        TEXT,
        category       TEXT DEFAULT 'General',
        quantity       NUMERIC(10,3) NOT NULL DEFAULT 1,
        unit           TEXT DEFAULT 'Piece',
        unit_price     NUMERIC(12,2) NOT NULL DEFAULT 0.00,
        market_price   NUMERIC(12,2) DEFAULT 0.00,
        discount       NUMERIC(12,2) DEFAULT 0.00,
        tax            NUMERIC(12,2) DEFAULT 0.00,
        total_price    NUMERIC(12,2) NOT NULL DEFAULT 0.00
      )
    ''');
  }

  Future<void> _createDailyPaymentHistoryTable() async {
    await query('''
      CREATE TABLE IF NOT EXISTS daily_payment_history (
        ${DbBaseFields.columnDefinitions},
        purchase_id     TEXT NOT NULL,
        payment_method  TEXT NOT NULL,
        amount          NUMERIC(12,2) NOT NULL DEFAULT 0.00,
        reference_no    TEXT,
        payment_date    TEXT NOT NULL
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
