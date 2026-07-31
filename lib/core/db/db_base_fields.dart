import 'package:uuid/uuid.dart';
import '../models/base_model.dart';

/// SQL helpers for the standardized base fields.
///
/// Use this class to:
///  - Generate consistent `CREATE TABLE` column definitions
///  - Build pre-filled maps for INSERT operations
///  - Build partial maps for UPDATE operations
///  - Compose safe `WHERE` clauses that exclude soft-deleted rows
class DbBaseFields {
  DbBaseFields._();

  // ── Column Definitions ────────────────────────────────────────────

  /// SQL column block to include in every `CREATE TABLE` statement.
  ///
  /// Usage:
  /// ```sql
  /// CREATE TABLE IF NOT EXISTS my_table (
  ///   ${DbBaseFields.columnDefinitions},
  ///   name TEXT NOT NULL,
  ///   ...
  /// )
  /// ```
  static const String columnDefinitions = '''
    id           TEXT PRIMARY KEY,
    created_at   TEXT NOT NULL,
    updated_at   TEXT NOT NULL,
    created_by   TEXT,
    updated_by   TEXT,
    deleted_at   TEXT,
    deleted_by   TEXT,
    is_deleted   INTEGER NOT NULL DEFAULT 0,
    version      INTEGER NOT NULL DEFAULT 1,
    status       TEXT NOT NULL DEFAULT 'active',
    tenant_id    TEXT,
    remarks      TEXT,
    metadata     TEXT''';

  // ── WHERE Clauses ─────────────────────────────────────────────────

  /// WHERE clause fragment that filters out soft-deleted records.
  /// Append to your query: `WHERE ${DbBaseFields.notDeleted}`
  static const String notDeleted = 'is_deleted = 0';

  /// AND clause fragment to further filter by active status.
  static const String andActive =
      "AND is_deleted = 0 AND status = '${BaseModelStatus.active}'";

  // ── Record factories ──────────────────────────────────────────────

  /// Returns a map pre-filled with all base fields for an INSERT.
  ///
  /// [createdBy] — UUID of the user performing the action.
  ///              Pass `null` for system-generated records.
  static Map<String, dynamic> newRecord({String? createdBy}) {
    final now = DateTime.now().toUtc().toIso8601String();
    return {
      'id': const Uuid().v4(),
      'created_at': now,
      'updated_at': now,
      'created_by': createdBy,
      'updated_by': createdBy,
      'deleted_at': null,
      'deleted_by': null,
      'is_deleted': 0,
      'version': 1,
      'status': BaseModelStatus.active,
      'tenant_id': null,
      'remarks': null,
      'metadata': null,
    };
  }

  /// Returns a partial map of fields to UPDATE on modification.
  ///
  /// [updatedBy]      — UUID of the user performing the update.
  /// [currentVersion] — The record's current version (will be incremented).
  static Map<String, dynamic> updatedRecord({
    required String updatedBy,
    required int currentVersion,
  }) {
    return {
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      'updated_by': updatedBy,
      'version': currentVersion + 1,
    };
  }

  /// Returns a partial map for performing a soft delete.
  ///
  /// [deletedBy]      — UUID of the user performing the deletion.
  /// [currentVersion] — The record's current version (will be incremented).
  static Map<String, dynamic> softDeleteRecord({
    required String deletedBy,
    required int currentVersion,
  }) {
    final now = DateTime.now().toUtc().toIso8601String();
    return {
      'deleted_at': now,
      'deleted_by': deletedBy,
      'is_deleted': 1,
      'status': BaseModelStatus.archived,
      'updated_at': now,
      'updated_by': deletedBy,
      'version': currentVersion + 1,
    };
  }

  // ── SQL Builders ──────────────────────────────────────────────────

  /// Builds a SET clause string and params list from a map.
  ///
  /// Returns a record with:
  ///  - `clause`: e.g. `"updated_at = ?, version = ?"`
  ///  - `params`: ordered list of values matching the clause
  static ({String clause, List<dynamic> params}) buildSetClause(
      Map<String, dynamic> fields) {
    final keys = fields.keys.toList();
    final clause = keys.map((k) => '$k = ?').join(', ');
    final params = keys.map((k) => fields[k]).toList();
    return (clause: clause, params: params);
  }

  /// Builds a column name list and matching params list for an INSERT.
  ///
  /// Returns a record with:
  ///  - `columns`: e.g. `"id, created_at, name"`
  ///  - `placeholders`: e.g. `"?, ?, ?"`
  ///  - `params`: ordered list of values
  static ({
    String columns,
    String placeholders,
    List<dynamic> params,
  }) buildInsertClause(Map<String, dynamic> fields) {
    final keys = fields.keys.toList();
    return (
      columns: keys.join(', '),
      placeholders: keys.map((_) => '?').join(', '),
      params: keys.map((k) => fields[k]).toList(),
    );
  }
}
