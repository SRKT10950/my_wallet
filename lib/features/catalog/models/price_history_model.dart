import '../../../core/models/base_model.dart';

/// Represents an immutable historical price audit record for a product.
///
/// Extends [BaseModel] to inherit all 13 standardized audit & control fields.
class PriceHistoryModel extends BaseModel {
  final String productId;
  final double oldPrice;
  final double newPrice;
  final double marketPrice;
  final String effectiveDate;
  final String updatedByUser;

  const PriceHistoryModel({
    // Base fields
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    super.createdBy,
    super.updatedBy,
    super.deletedAt,
    super.deletedBy,
    super.isDeleted,
    super.version,
    super.status,
    super.tenantId,
    super.remarks,
    super.metadata,
    // Price history fields
    required this.productId,
    required this.oldPrice,
    required this.newPrice,
    required this.marketPrice,
    required this.effectiveDate,
    this.updatedByUser = 'System',
  });

  // ── Deserialisation ───────────────────────────────────────────────

  factory PriceHistoryModel.fromMap(Map<String, dynamic> map) {
    final base = BaseModel.baseFromMap(map);
    return PriceHistoryModel(
      // Base fields
      id: base['id'] as String,
      createdAt: base['created_at'] as String,
      updatedAt: base['updated_at'] as String,
      createdBy: base['created_by'] as String?,
      updatedBy: base['updated_by'] as String?,
      deletedAt: base['deleted_at'] as String?,
      deletedBy: base['deleted_by'] as String?,
      isDeleted: base['is_deleted'] as bool,
      version: base['version'] as int,
      status: base['status'] as String,
      tenantId: base['tenant_id'] as String?,
      remarks: base['remarks'] as String?,
      metadata: base['metadata'] as String?,
      // Price history fields
      productId: map['product_id']?.toString() ?? '',
      oldPrice: (map['old_price'] as num?)?.toDouble() ?? 0.0,
      newPrice: (map['new_price'] as num?)?.toDouble() ?? 0.0,
      marketPrice: (map['market_price'] as num?)?.toDouble() ?? 0.0,
      effectiveDate: map['effective_date']?.toString() ?? DateTime.now().toString().split(' ')[0],
      updatedByUser: map['updated_by_user']?.toString() ?? map['created_by']?.toString() ?? 'System',
    );
  }

  // ── Serialisation ─────────────────────────────────────────────────

  @override
  Map<String, dynamic> toMap() => {
        ...baseToMap(),
        'product_id': productId,
        'old_price': oldPrice,
        'new_price': newPrice,
        'market_price': marketPrice,
        'effective_date': effectiveDate,
        'updated_by_user': updatedByUser,
      };
}
