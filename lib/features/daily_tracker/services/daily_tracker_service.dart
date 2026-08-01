import '../../../core/db/db_base_fields.dart';
import '../../../core/models/base_model.dart';
import '../../../core/services/database_service.dart';
import '../models/daily_payment_history_model.dart';
import '../models/daily_purchase_item_model.dart';
import '../models/daily_purchase_model.dart';

/// Calculation result structure for the 17 Dashboard Metrics.
class DailyDashboardMetrics {
  final double todayExpenses;
  final double weekExpenses;
  final double monthExpenses;
  final double yearExpenses;
  final double totalOutstandingDue;
  final double totalPaidAmount;
  final int pendingBillsCount;
  final int overdueBillsCount;
  final String highestExpenseCategory;
  final String mostPurchasedProduct;
  final double avgDailySpending;
  final double avgMonthlySpending;
  final double totalSavings;
  final int totalBillsCount;
  final double cashbackEarned;
  final int rewardPoints;
  final double monthlyBudgetUsedPct;

  const DailyDashboardMetrics({
    required this.todayExpenses,
    required this.weekExpenses,
    required this.monthExpenses,
    required this.yearExpenses,
    required this.totalOutstandingDue,
    required this.totalPaidAmount,
    required this.pendingBillsCount,
    required this.overdueBillsCount,
    required this.highestExpenseCategory,
    required this.mostPurchasedProduct,
    required this.avgDailySpending,
    required this.avgMonthlySpending,
    required this.totalSavings,
    required this.totalBillsCount,
    required this.cashbackEarned,
    required this.rewardPoints,
    required this.monthlyBudgetUsedPct,
  });
}

/// Data service for managing Daily Tracker Purchases, Line Items, and Split Payments.
class DailyTrackerService {
  DailyTrackerService._();
  static final DailyTrackerService instance = DailyTrackerService._();

  final _db = DatabaseService.instance;

  // ── Default Purchases (Initial Sample Data) ────────────────────────
  static final List<DailyPurchaseModel> _defaultPurchases = [
    DailyPurchaseModel(
      id: 'pur_1',
      createdAt: DateTime.now().toUtc().toIso8601String(),
      updatedAt: DateTime.now().toUtc().toIso8601String(),
      purchaseId: 'pur_1',
      billNumber: 'BILL-901',
      shopName: 'Supermarket Superstore',
      shopType: 'Groceries',
      billingDate: DateTime.now().toString().split(' ')[0],
      currency: '₹',
      subtotal: 3450.0,
      grandTotal: 3450.0,
      amountPaid: 3450.0,
      dueAmount: 0.0,
      paymentStatus: 'Paid',
      paymentMethod: 'UPI',
      cashback: 50.0,
      rewardPoints: 120,
      items: [
        DailyPurchaseItemModel(
          id: 'item_1',
          createdAt: DateTime.now().toUtc().toIso8601String(),
          updatedAt: DateTime.now().toUtc().toIso8601String(),
          purchaseId: 'pur_1',
          productName: 'Basmati Rice 5kg',
          category: 'Food & Dining',
          quantity: 1,
          unit: 'Pack',
          unitPrice: 300.0,
          marketPrice: 320.0,
          totalPrice: 300.0,
        ),
      ],
      paymentHistory: [
        DailyPaymentHistoryModel(
          id: 'pay_1',
          createdAt: DateTime.now().toUtc().toIso8601String(),
          updatedAt: DateTime.now().toUtc().toIso8601String(),
          purchaseId: 'pur_1',
          paymentMethod: 'UPI',
          amount: 3450.0,
          paymentDate: DateTime.now().toString().split(' ')[0],
        ),
      ],
    ),
  ];

  // ── Fetch Purchases ───────────────────────────────────────────────
  Future<List<DailyPurchaseModel>> fetchPurchases() async {
    final res = await _db.query(
      'SELECT * FROM daily_purchases WHERE (is_deleted = 0 OR is_deleted IS NULL) ORDER BY created_at DESC',
    );

    if (res.success && res.isNotEmpty) {
      final List<DailyPurchaseModel> list = [];
      for (final row in res.rows) {
        final pId = row['purchase_id']?.toString() ?? row['id'].toString();

        // Fetch items
        final itemsRes = await _db.query(
          'SELECT * FROM daily_purchase_items WHERE purchase_id = ? AND (is_deleted = 0 OR is_deleted IS NULL)',
          [pId],
        );
        final items = itemsRes.rows.map((r) => DailyPurchaseItemModel.fromMap(r)).toList();

        // Fetch payments
        final payRes = await _db.query(
          'SELECT * FROM daily_payment_history WHERE purchase_id = ? AND (is_deleted = 0 OR is_deleted IS NULL)',
          [pId],
        );
        final payments = payRes.rows.map((r) => DailyPaymentHistoryModel.fromMap(r)).toList();

        list.add(DailyPurchaseModel.fromMap(row, items: items, paymentHistory: payments));
      }

      final defaultsToKeep = _defaultPurchases.where((d) => !list.any((p) => p.id == d.id || p.billNumber == d.billNumber));
      return [...list, ...defaultsToKeep];
    }

    return _defaultPurchases;
  }

  // ── Save / Update Purchase with Items & Split Payments ────────────
  Future<bool> savePurchase(
    DailyPurchaseModel purchase,
    List<DailyPurchaseItemModel> items,
    List<DailyPaymentHistoryModel> payments,
  ) async {
    final pId = purchase.purchaseId.isNotEmpty ? purchase.purchaseId : BaseModel.newId();

    final existing = await _db.query(
      'SELECT id FROM daily_purchases WHERE id = ? OR purchase_id = ? LIMIT 1',
      [pId, pId],
    );

    if (existing.success && existing.isNotEmpty) {
      // Update purchase
      final updateFields = {
        ...DbBaseFields.updatedRecord(updatedBy: 'system', currentVersion: purchase.version),
        'purchase_id': pId,
        'bill_number': purchase.billNumber,
        'invoice_number': purchase.invoiceNumber,
        'shop_name': purchase.shopName,
        'shop_type': purchase.shopType,
        'billing_date': purchase.billingDate,
        'due_date': purchase.dueDate,
        'payment_date': purchase.paymentDate,
        'currency': purchase.currency,
        'subtotal': purchase.subtotal,
        'discount': purchase.discount,
        'tax': purchase.tax,
        'delivery_charge': purchase.deliveryCharge,
        'packing_charge': purchase.packingCharge,
        'other_charge': purchase.otherCharge,
        'round_off': purchase.roundOff,
        'grand_total': purchase.grandTotal,
        'amount_paid': purchase.amountPaid,
        'due_amount': purchase.dueAmount,
        'payment_status': purchase.paymentStatus,
        'payment_method': purchase.paymentMethod,
        'cashback': purchase.cashback,
        'reward_points': purchase.rewardPoints,
        'notes': purchase.notes,
      };

      final set = DbBaseFields.buildSetClause(updateFields);
      await _db.query('UPDATE daily_purchases SET ${set.clause} WHERE id = ?', [...set.params, pId]);
    } else {
      // Insert purchase
      final fields = {
        ...DbBaseFields.newRecord(),
        'id': pId,
        'purchase_id': pId,
        'bill_number': purchase.billNumber,
        'invoice_number': purchase.invoiceNumber,
        'shop_name': purchase.shopName,
        'shop_type': purchase.shopType,
        'billing_date': purchase.billingDate,
        'due_date': purchase.dueDate,
        'payment_date': purchase.paymentDate,
        'currency': purchase.currency,
        'subtotal': purchase.subtotal,
        'discount': purchase.discount,
        'tax': purchase.tax,
        'delivery_charge': purchase.deliveryCharge,
        'packing_charge': purchase.packingCharge,
        'other_charge': purchase.otherCharge,
        'round_off': purchase.roundOff,
        'grand_total': purchase.grandTotal,
        'amount_paid': purchase.amountPaid,
        'due_amount': purchase.dueAmount,
        'payment_status': purchase.paymentStatus,
        'payment_method': purchase.paymentMethod,
        'cashback': purchase.cashback,
        'reward_points': purchase.rewardPoints,
        'notes': purchase.notes,
      };

      await _db.insertRecord('daily_purchases', fields);
    }

    // Insert Line Items
    for (final item in items) {
      final itemFields = {
        ...DbBaseFields.newRecord(),
        'id': item.id.isNotEmpty ? item.id : BaseModel.newId(),
        'purchase_id': pId,
        'product_id': item.productId,
        'product_name': item.productName,
        'barcode': item.barcode,
        'category': item.category,
        'quantity': item.quantity,
        'unit': item.unit,
        'unit_price': item.unitPrice,
        'market_price': item.marketPrice,
        'discount': item.discount,
        'tax': item.tax,
        'total_price': item.totalPrice,
      };
      await _db.insertRecord('daily_purchase_items', itemFields);
    }

    // Insert Split Payment Records
    for (final pay in payments) {
      final payFields = {
        ...DbBaseFields.newRecord(),
        'id': pay.id.isNotEmpty ? pay.id : BaseModel.newId(),
        'purchase_id': pId,
        'payment_method': pay.paymentMethod,
        'amount': pay.amount,
        'reference_no': pay.referenceNo,
        'payment_date': pay.paymentDate,
      };
      await _db.insertRecord('daily_payment_history', payFields);
    }

    return true;
  }

  // ── Soft Delete Purchase ──────────────────────────────────────────
  Future<bool> deletePurchase(String purchaseId) async {
    final res = await _db.softDelete('daily_purchases', purchaseId, deletedBy: 'system', currentVersion: 1);
    return res.success;
  }

  // ── Calculate 17 Dashboard Summary Metrics ─────────────────────────
  DailyDashboardMetrics calculateMetrics(List<DailyPurchaseModel> purchases) {
    final now = DateTime.now();
    final todayStr = now.toString().split(' ')[0];

    double todayExp = 0.0;
    double weekExp = 0.0;
    double monthExp = 0.0;
    double yearExp = 0.0;
    double totalDue = 0.0;
    double totalPaid = 0.0;
    int pendingBills = 0;
    int overdueBills = 0;
    double totalSavings = 0.0;
    double cashback = 0.0;
    int rewards = 0;

    final categoryTotals = <String, double>{};
    final productCounts = <String, int>{};

    for (final p in purchases) {
      final billDate = DateTime.tryParse(p.billingDate) ?? now;
      final diffDays = now.difference(billDate).inDays;

      // Expenses by timeframe
      if (p.billingDate == todayStr) todayExp += p.grandTotal;
      if (diffDays <= 7) weekExp += p.grandTotal;
      if (billDate.month == now.month && billDate.year == now.year) monthExp += p.grandTotal;
      if (billDate.year == now.year) yearExp += p.grandTotal;

      // Dues & Payments
      totalDue += p.dueAmount;
      totalPaid += p.amountPaid;
      cashback += p.cashback;
      rewards += p.rewardPoints;

      if (p.dueAmount > 0) {
        pendingBills++;
        if (p.dueDate != null) {
          final due = DateTime.tryParse(p.dueDate!) ?? now;
          if (due.isBefore(now)) overdueBills++;
        }
      }

      // Line items breakdown
      for (final item in p.items) {
        categoryTotals[item.category] = (categoryTotals[item.category] ?? 0.0) + item.totalPrice;
        productCounts[item.productName] = (productCounts[item.productName] ?? 0) + item.quantity.toInt();

        if (item.marketPrice > item.unitPrice) {
          totalSavings += (item.marketPrice - item.unitPrice) * item.quantity;
        }
      }
    }

    // Top category
    String topCat = 'Food & Dining';
    double maxCatExp = -1.0;
    categoryTotals.forEach((cat, amt) {
      if (amt > maxCatExp) {
        maxCatExp = amt;
        topCat = cat;
      }
    });

    // Top product
    String topProd = 'Basmati Rice';
    int maxProdQty = -1;
    productCounts.forEach((prod, qty) {
      if (qty > maxProdQty) {
        maxProdQty = qty;
        topProd = prod;
      }
    });

    return DailyDashboardMetrics(
      todayExpenses: todayExp > 0 ? todayExp : 180.0,
      weekExpenses: weekExp > 0 ? weekExp : 4350.0,
      monthExpenses: monthExp > 0 ? monthExp : 36480.0,
      yearExpenses: yearExp > 0 ? yearExp : 185000.0,
      totalOutstandingDue: totalDue,
      totalPaidAmount: totalPaid > 0 ? totalPaid : 36480.0,
      pendingBillsCount: pendingBills,
      overdueBillsCount: overdueBills,
      highestExpenseCategory: topCat,
      mostPurchasedProduct: topProd,
      avgDailySpending: (monthExp > 0 ? monthExp : 36480.0) / 30,
      avgMonthlySpending: monthExp > 0 ? monthExp : 36480.0,
      totalSavings: totalSavings > 0 ? totalSavings : 1240.0,
      totalBillsCount: purchases.length,
      cashbackEarned: cashback > 0 ? cashback : 250.0,
      rewardPoints: rewards > 0 ? rewards : 480,
      monthlyBudgetUsedPct: ((monthExp > 0 ? monthExp : 36480.0) / 85000.0) * 100,
    );
  }
}
