import 'package:uuid/uuid.dart';

/// Abstract base class that every My Wallet model must extend.
///
/// Provides the 13 standardized audit/control fields that every
/// database table includes for consistency, auditing, soft-delete,
/// optimistic locking, and multi-tenant readiness.
abstract class BaseModel {
  // ── Identity ──────────────────────────────────────────────────────
  /// UUID v4 primary key — generated client-side.
  final String id;

  // ── Audit timestamps ──────────────────────────────────────────────
  /// ISO 8601 timestamp of record creation.
  final String createdAt;

  /// ISO 8601 timestamp of last modification.
  final String updatedAt;

  // ── Audit actors ──────────────────────────────────────────────────
  /// UUID of the user who created this record (null for system).
  final String? createdBy;

  /// UUID of the user who last updated this record.
  final String? updatedBy;

  // ── Soft delete ───────────────────────────────────────────────────
  /// ISO 8601 timestamp of soft-deletion. NULL means not deleted.
  final String? deletedAt;

  /// UUID of the user who soft-deleted this record.
  final String? deletedBy;

  /// Boolean soft-delete flag (true = deleted).
  final bool isDeleted;

  // ── Versioning ────────────────────────────────────────────────────
  /// Optimistic locking counter — increments on every UPDATE.
  final int version;

  // ── Lifecycle ─────────────────────────────────────────────────────
  /// Record lifecycle status: active | inactive | pending | archived.
  final String status;

  // ── Multi-tenancy ─────────────────────────────────────────────────
  /// Reserved for future multi-tenant support. Currently null.
  final String? tenantId;

  // ── Extensibility ─────────────────────────────────────────────────
  /// Optional human-readable notes.
  final String? remarks;

  /// JSON-encoded flexible metadata blob.
  final String? metadata;

  const BaseModel({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.deletedAt,
    this.deletedBy,
    this.isDeleted = false,
    this.version = 1,
    this.status = 'active',
    this.tenantId,
    this.remarks,
    this.metadata,
  });

  // ── Helpers ───────────────────────────────────────────────────────

  /// Generate a new UUID v4 string.
  static String newId() => const Uuid().v4();

  /// Safely parse dynamic values into double (handles String, int, double, null).
  static double toDouble(dynamic val, [double defaultValue = 0.0]) {
    if (val == null) return defaultValue;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? defaultValue;
    return defaultValue;
  }

  /// Safely parse dynamic values into int (handles String, int, double, null).
  static int toInt(dynamic val, [int defaultValue = 0]) {
    if (val == null) return defaultValue;
    if (val is num) return val.toInt();
    if (val is String) return int.tryParse(val) ?? defaultValue;
    return defaultValue;
  }

  /// Whether this record has been soft-deleted.
  bool get isSoftDeleted => isDeleted || deletedAt != null;

  /// Whether this record is in active status.
  bool get isActive => status == BaseModelStatus.active && !isSoftDeleted;

  /// Serialise all base fields to a map (for DB insert/update).
  Map<String, dynamic> baseToMap() => {
        'id': id,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'created_by': createdBy,
        'updated_by': updatedBy,
        'deleted_at': deletedAt,
        'deleted_by': deletedBy,
        'is_deleted': isDeleted ? 1 : 0,
        'version': version,
        'status': status,
        'tenant_id': tenantId,
        'remarks': remarks,
        'metadata': metadata,
      };

  /// Parse all base fields from a DB row map.
  static Map<String, dynamic> baseFromMap(Map<String, dynamic> map) => {
        'id': map['id']?.toString() ?? '',
        'created_at': map['created_at']?.toString() ?? '',
        'updated_at': map['updated_at']?.toString() ?? '',
        'created_by': map['created_by']?.toString(),
        'updated_by': map['updated_by']?.toString(),
        'deleted_at': map['deleted_at']?.toString(),
        'deleted_by': map['deleted_by']?.toString(),
        'is_deleted': (map['is_deleted'] as num?)?.toInt() == 1,
        'version': (map['version'] as num?)?.toInt() ?? 1,
        'status': map['status']?.toString() ?? BaseModelStatus.active,
        'tenant_id': map['tenant_id']?.toString(),
        'remarks': map['remarks']?.toString(),
        'metadata': map['metadata']?.toString(),
      };

  /// Subclasses must implement their own full serialisation.
  Map<String, dynamic> toMap();
}

/// Standardised status values for the [BaseModel.status] field.
class BaseModelStatus {
  BaseModelStatus._();

  static const String active = 'active';
  static const String inactive = 'inactive';
  static const String pending = 'pending';
  static const String archived = 'archived';
}
