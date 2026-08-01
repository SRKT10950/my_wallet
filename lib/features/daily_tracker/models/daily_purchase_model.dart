import '../../../core/models/base_model.dart';
import 'daily_payment_history_model.dart';
import 'daily_purchase_item_model.dart';

/// Represents a daily purchase or expense bill.
///
/// Extends [BaseModel] to inherit all 13 standardized audit & control fields.
class DailyPurchaseModel extends BaseModel {
  final String purchaseId;
  final String billNumber;
  final String? invoiceNumber;
  final String shopName;
  final String shopType;
  final String billingDate;
  final String? dueDate;
  final String? paymentDate;
  final String currency;
  final double subtotal;
  final double discount;
  final double tax;
  final double deliveryCharge;
  final double packingCharge;
  final double otherCharge;
  final double roundOff;
  final double grandTotal;
  final double amountPaid;
  final double dueAmount;
  final String paymentStatus; // 'Paid', 'Partially Paid', 'Due', 'Cancelled', 'Refunded'
  final String paymentMethod; // Primary payment method or 'Split'
  final double cashback;
  final int rewardPoints;
  final String? notes;

  final List<DailyPurchaseItemModel> items;
  final List<DailyPaymentHistoryModel> paymentHistory;

  const DailyPurchaseModel({
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
    // Purchase fields
    required this.purchaseId,
    required this.billNumber,
    this.invoiceNumber,
    required this.shopName,
    this.shopType = 'General',
    required this.billingDate,
    this.dueDate,
    this.paymentDate,
    this.currency = '₹',
    this.subtotal = 0.0,
    this.discount = 0.0,
    this.tax = 0.0,
    this.deliveryCharge = 0.0,
    this.packingCharge = 0.0,
    this.otherCharge = 0.0,
    this.roundOff = 0.0,
    required this.grandTotal,
    required this.amountPaid,
    required this.dueAmount,
    this.paymentStatus = 'Paid',
    this.paymentMethod = 'Cash',
    this.cashback = 0.0,
    this.rewardPoints = 0,
    this.notes,
    this.items = const [],
    this.paymentHistory = const [],
  });

  bool get isFullyPaid => paymentStatus.toLowerCase() == 'paid' || dueAmount <= 0;
  bool get isPartiallyPaid => paymentStatus.toLowerCase() == 'partially paid' || (amountPaid > 0 && dueAmount > 0);
  bool get isDue => paymentStatus.toLowerCase() == 'due' || (amountPaid == 0 && dueAmount > 0);

  // ── Deserialisation ───────────────────────────────────────────────

  factory DailyPurchaseModel.fromMap(
    Map<String, dynamic> map, {
    List<DailyPurchaseItemModel> items = const [],
    List<DailyPaymentHistoryModel> paymentHistory = const [],
  }) {
    final base = BaseModel.baseFromMap(map);
    final tot = BaseModel.toDouble(map['grand_total']);
    final paid = BaseModel.toDouble(map['amount_paid'], tot);
    final due = BaseModel.toDouble(map['due_amount'], (tot - paid > 0 ? tot - paid : 0.0));

    String status = map['payment_status']?.toString() ?? 'Paid';
    if (due <= 0) {
      status = 'Paid';
    } else if (paid > 0 && due > 0) {
      status = 'Partially Paid';
    } else if (paid == 0 && due > 0) {
      status = 'Due';
    }

    return DailyPurchaseModel(
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
      // Purchase fields
      purchaseId: map['purchase_id']?.toString() ?? base['id'] as String,
      billNumber: map['bill_number']?.toString() ?? 'BILL-001',
      invoiceNumber: map['invoice_number']?.toString(),
      shopName: map['shop_name']?.toString() ?? 'General Store',
      shopType: map['shop_type']?.toString() ?? 'General',
      billingDate: map['billing_date']?.toString() ?? DateTime.now().toString().split(' ')[0],
      dueDate: map['due_date']?.toString(),
      paymentDate: map['payment_date']?.toString(),
      currency: map['currency']?.toString() ?? '₹',
      subtotal: BaseModel.toDouble(map['subtotal'], tot),
      discount: BaseModel.toDouble(map['discount']),
      tax: BaseModel.toDouble(map['tax']),
      deliveryCharge: BaseModel.toDouble(map['delivery_charge']),
      packingCharge: BaseModel.toDouble(map['packing_charge']),
      otherCharge: BaseModel.toDouble(map['other_charge']),
      roundOff: BaseModel.toDouble(map['round_off']),
      grandTotal: tot,
      amountPaid: paid,
      dueAmount: due,
      paymentStatus: status,
      paymentMethod: map['payment_method']?.toString() ?? 'Cash',
      cashback: BaseModel.toDouble(map['cashback']),
      rewardPoints: BaseModel.toInt(map['reward_points']),
      notes: map['notes']?.toString(),
      items: items,
      paymentHistory: paymentHistory,
    );
  }

  // ── Serialisation ─────────────────────────────────────────────────

  @override
  Map<String, dynamic> toMap() => {
        ...baseToMap(),
        'purchase_id': purchaseId,
        'bill_number': billNumber,
        'invoice_number': invoiceNumber,
        'shop_name': shopName,
        'shop_type': shopType,
        'billing_date': billingDate,
        'due_date': dueDate,
        'payment_date': paymentDate,
        'currency': currency,
        'subtotal': subtotal,
        'discount': discount,
        'tax': tax,
        'delivery_charge': deliveryCharge,
        'packing_charge': packingCharge,
        'other_charge': otherCharge,
        'round_off': roundOff,
        'grand_total': grandTotal,
        'amount_paid': amountPaid,
        'due_amount': dueAmount,
        'payment_status': paymentStatus,
        'payment_method': paymentMethod,
        'cashback': cashback,
        'reward_points': rewardPoints,
        'notes': notes,
      };
}
