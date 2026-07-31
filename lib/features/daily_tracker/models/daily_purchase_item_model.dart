import '../../../core/models/base_model.dart';

/// Represents a line item inside a daily purchase bill.
///
/// Extends [BaseModel] to inherit all 13 standardized audit & control fields.
class DailyPurchaseItemModel extends BaseModel {
  final String purchaseId;
  final String? productId;
  final String productName;
  final String? barcode;
  final String category;
  final double quantity;
  final String unit;
  final double unitPrice;
  final double marketPrice;
  final double discount;
  final double tax;
  final double totalPrice;

  const DailyPurchaseItemModel({
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
    // Item fields
    required this.purchaseId,
    this.productId,
    required this.productName,
    this.barcode,
    this.category = 'General',
    this.quantity = 1.0,
    this.unit = 'Piece',
    required this.unitPrice,
    this.marketPrice = 0.0,
    this.discount = 0.0,
    this.tax = 0.0,
    required this.totalPrice,
  });

  // ── Deserialisation ───────────────────────────────────────────────

  factory DailyPurchaseItemModel.fromMap(Map<String, dynamic> map) {
    final base = BaseModel.baseFromMap(map);
    final qty = (map['quantity'] as num?)?.toDouble() ?? 1.0;
    final price = (map['unit_price'] as num?)?.toDouble() ?? 0.0;
    final disc = (map['discount'] as num?)?.toDouble() ?? 0.0;
    final tx = (map['tax'] as num?)?.toDouble() ?? 0.0;
    final tot = (map['total_price'] as num?)?.toDouble() ?? ((qty * price) - disc + tx);

    return DailyPurchaseItemModel(
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
      // Item fields
      purchaseId: map['purchase_id']?.toString() ?? '',
      productId: map['product_id']?.toString(),
      productName: map['product_name']?.toString() ?? 'Item',
      barcode: map['barcode']?.toString(),
      category: map['category']?.toString() ?? 'General',
      quantity: qty,
      unit: map['unit']?.toString() ?? 'Piece',
      unitPrice: price,
      marketPrice: (map['market_price'] as num?)?.toDouble() ?? 0.0,
      discount: disc,
      tax: tx,
      totalPrice: tot,
    );
  }

  // ── Serialisation ─────────────────────────────────────────────────

  @override
  Map<String, dynamic> toMap() => {
        ...baseToMap(),
        'purchase_id': purchaseId,
        'product_id': productId,
        'product_name': productName,
        'barcode': barcode,
        'category': category,
        'quantity': quantity,
        'unit': unit,
        'unit_price': unitPrice,
        'market_price': marketPrice,
        'discount': discount,
        'tax': tax,
        'total_price': totalPrice,
      };
}
