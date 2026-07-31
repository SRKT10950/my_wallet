import '../../../core/models/base_model.dart';

/// Represents a split payment transaction entry for a purchase bill.
///
/// Extends [BaseModel] to inherit all 13 standardized audit & control fields.
class DailyPaymentHistoryModel extends BaseModel {
  final String purchaseId;
  final String paymentMethod; // Cash, UPI, Wallet, Credit Card, Debit Card, etc.
  final double amount;
  final String? referenceNo;
  final String paymentDate;

  const DailyPaymentHistoryModel({
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
    // Payment fields
    required this.purchaseId,
    required this.paymentMethod,
    required this.amount,
    this.referenceNo,
    required this.paymentDate,
  });

  // ── Deserialisation ───────────────────────────────────────────────

  factory DailyPaymentHistoryModel.fromMap(Map<String, dynamic> map) {
    final base = BaseModel.baseFromMap(map);
    return DailyPaymentHistoryModel(
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
      // Payment fields
      purchaseId: map['purchase_id']?.toString() ?? '',
      paymentMethod: map['payment_method']?.toString() ?? 'Cash',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      referenceNo: map['reference_no']?.toString(),
      paymentDate: map['payment_date']?.toString() ?? DateTime.now().toString().split(' ')[0],
    );
  }

  // ── Serialisation ─────────────────────────────────────────────────

  @override
  Map<String, dynamic> toMap() => {
        ...baseToMap(),
        'purchase_id': purchaseId,
        'payment_method': paymentMethod,
        'amount': amount,
        'reference_no': referenceNo,
        'payment_date': paymentDate,
      };
}
