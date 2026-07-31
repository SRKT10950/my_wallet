import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/base_model.dart';
import '../../../core/theme/app_theme.dart';

import '../../catalog/models/product_model.dart';
import '../../catalog/services/product_service.dart';
import '../../contacts/models/contact_model.dart';
import '../../contacts/services/contact_service.dart';
import '../models/daily_payment_history_model.dart';
import '../models/daily_purchase_item_model.dart';
import '../models/daily_purchase_model.dart';
import '../services/daily_tracker_service.dart';

/// Enterprise Daily Tracker View — 17 Dashboard Metrics, Itemized Bills, Contact Picklist & Auto Invoice Dispatcher.
class DailyTrackerView extends StatefulWidget {
  const DailyTrackerView({super.key});

  @override
  State<DailyTrackerView> createState() => _DailyTrackerViewState();
}

class _DailyTrackerViewState extends State<DailyTrackerView> {
  final _trackerService = DailyTrackerService.instance;
  final _productService = ProductService.instance;
  final _contactService = ContactService.instance;
  final _searchCtrl = TextEditingController();

  List<DailyPurchaseModel> _allPurchases = [];
  List<DailyPurchaseModel> _filteredPurchases = [];
  List<ProductModel> _catalogProducts = [];
  List<ContactModel> _contacts = [];
  bool _isLoading = true;

  String _statusFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    final purchases = await _trackerService.fetchPurchases();
    final prods = await _productService.fetchProducts();
    final contacts = await _contactService.fetchContacts();
    if (!mounted) return;
    setState(() {
      _allPurchases = purchases;
      _filteredPurchases = purchases;
      _catalogProducts = prods;
      _contacts = contacts;
      _isLoading = false;
    });
  }

  void _onSearchChanged() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filteredPurchases = _allPurchases.where((p) {
        final matchesSearch = q.isEmpty ||
            p.billNumber.toLowerCase().contains(q) ||
            p.shopName.toLowerCase().contains(q) ||
            p.paymentStatus.toLowerCase().contains(q) ||
            p.items.any((i) => i.productName.toLowerCase().contains(q));

        final matchesStatus = _statusFilter == 'All' ||
            p.paymentStatus.toLowerCase() == _statusFilter.toLowerCase();

        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  // ── Auto Invoice & Notification Dispatcher ─────────────────────────
  Future<void> _autoDispatchInvoice(DailyPurchaseModel purchase, ContactModel? contact) async {
    if (contact == null || !contact.enableNotification || contact.mobileNumber.trim().isEmpty) {
      return;
    }

    final cleanMobile = contact.mobileNumber.replaceAll(RegExp(r'\D'), '');
    final fullPhone = cleanMobile.length == 10 ? '91$cleanMobile' : cleanMobile;

    final itemSummary = purchase.items.isEmpty
        ? 'General Purchase'
        : purchase.items.map((i) => '${i.productName} (${i.quantity} ${i.unit})').join(', ');

    final msg = '''
🧾 *INVOICE RECEIPT — My Wallet*
----------------------------------
*Bill No:* ${purchase.billNumber}
*Merchant:* ${purchase.shopName}
*Date:* ${purchase.billingDate}
*Items:* $itemSummary
*Grand Total:* ₹${purchase.grandTotal.toStringAsFixed(2)}
*Amount Paid:* ₹${purchase.amountPaid.toStringAsFixed(2)}
*Remaining Due:* ₹${purchase.dueAmount.toStringAsFixed(2)}
*Payment Status:* ${purchase.paymentStatus.toUpperCase()}
----------------------------------
Thank you for your transaction!
''';

    final encodedMsg = Uri.encodeComponent(msg);
    final isWhatsApp = contact.notificationMethod.toLowerCase() == 'whatsapp';

    final urlStr = isWhatsApp
        ? 'https://wa.me/$fullPhone?text=$encodedMsg'
        : 'sms:+$fullPhone?body=$encodedMsg';

    try {
      final uri = Uri.parse(urlStr);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚡ Auto-sent invoice via ${contact.notificationMethod} to +$fullPhone'),
          backgroundColor: AppTheme.primaryTeal,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ── Monthly Invoice Statement Generator Modal ─────────────────────
  void _showMonthlyInvoiceModal() {
    ContactModel? selectedContact = _contacts.isNotEmpty ? _contacts.first : null;
    int selectedMonth = DateTime.now().month;
    int selectedYear = DateTime.now().year;

    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    showDialog(
      context: context,
      builder: (dlgCtx) {
        return StatefulBuilder(
          builder: (context, setMonthlyState) {
            final monthPurchases = _allPurchases.where((p) {
              final d = DateTime.tryParse(p.billingDate);
              if (d == null) return false;
              final matchesMonth = d.month == selectedMonth && d.year == selectedYear;
              final matchesContact = selectedContact == null ||
                  p.shopName.toLowerCase().contains(selectedContact!.businessShopName.toLowerCase()) ||
                  p.shopName.toLowerCase().contains(selectedContact!.ownerName.toLowerCase());
              return matchesMonth && matchesContact;
            }).toList();

            double monthTotal = 0.0;
            double monthPaid = 0.0;
            double monthDue = 0.0;

            for (final p in monthPurchases) {
              monthTotal += p.grandTotal;
              monthPaid += p.amountPaid;
              monthDue += p.dueAmount;
            }

            return AlertDialog(
              backgroundColor: AppTheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Row(
                children: [
                  Icon(Icons.calendar_month_rounded, color: AppTheme.primaryTeal),
                  SizedBox(width: 10),
                  Text('Send Monthly Statement Invoice', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 18)),
                ],
              ),
              content: SizedBox(
                width: 440,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<ContactModel>(
                      initialValue: selectedContact,
                      dropdownColor: AppTheme.card,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: const InputDecoration(labelText: 'Select Merchant / Contact'),
                      items: _contacts.map((c) {
                        return DropdownMenuItem(
                          value: c,
                          child: Text('${c.businessShopName} (${c.ownerName})'),
                        );
                      }).toList(),
                      onChanged: (v) => setMonthlyState(() => selectedContact = v),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: selectedMonth,
                            dropdownColor: AppTheme.card,
                            style: const TextStyle(color: AppTheme.textPrimary),
                            decoration: const InputDecoration(labelText: 'Month'),
                            items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text(months[i]))),
                            onChanged: (v) => setMonthlyState(() => selectedMonth = v!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: selectedYear,
                            dropdownColor: AppTheme.card,
                            style: const TextStyle(color: AppTheme.textPrimary),
                            decoration: const InputDecoration(labelText: 'Year'),
                            items: [2025, 2026, 2027].map((y) => DropdownMenuItem(value: y, child: Text(y.toString()))).toList(),
                            onChanged: (v) => setMonthlyState(() => selectedYear = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Statement Summary — ${months[selectedMonth - 1]} $selectedYear', style: const TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          _buildSummaryRow('Total Bills Count:', '${monthPurchases.length} Bills'),
                          _buildSummaryRow('Total Billed Amount:', '₹${monthTotal.toStringAsFixed(2)}'),
                          _buildSummaryRow('Total Paid Amount:', '₹${monthPaid.toStringAsFixed(2)}'),
                          const Divider(color: Colors.white10),
                          _buildSummaryRow('Outstanding Balance Due:', '₹${monthDue.toStringAsFixed(2)}', isBold: true),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dlgCtx),
                  child: const Text('Cancel', style: TextStyle(color: AppTheme.textHint)),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    if (selectedContact == null) return;
                    Navigator.pop(dlgCtx);

                    final cleanMobile = selectedContact!.mobileNumber.replaceAll(RegExp(r'\D'), '');
                    final fullPhone = cleanMobile.length == 10 ? '91$cleanMobile' : cleanMobile;

                    final statementMsg = '''
📅 *MONTHLY STATEMENT INVOICE — My Wallet*
------------------------------------------
*Merchant:* ${selectedContact!.businessShopName}
*Owner:* ${selectedContact!.ownerName}
*Period:* ${months[selectedMonth - 1]} $selectedYear
------------------------------------------
*Total Bills:* ${monthPurchases.length}
*Total Billed:* ₹${monthTotal.toStringAsFixed(2)}
*Total Paid:* ₹${monthPaid.toStringAsFixed(2)}
*Outstanding Due:* ₹${monthDue.toStringAsFixed(2)}
------------------------------------------
Please clear outstanding balance if due. Thank you!
''';

                    final encoded = Uri.encodeComponent(statementMsg);
                    final isWA = selectedContact!.notificationMethod.toLowerCase() == 'whatsapp';
                    final urlStr = isWA ? 'https://wa.me/$fullPhone?text=$encoded' : 'sms:+$fullPhone?body=$encoded';

                    try {
                      final uri = Uri.parse(urlStr);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    } catch (_) {}

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('⚡ Monthly Statement dispatched via ${selectedContact!.notificationMethod} to +$fullPhone'),
                          backgroundColor: AppTheme.primaryTeal,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text('Dispatch Statement'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ── 1. Tabbed Add / Edit Purchase Responsive Dialog ────────────────
  void _showAddEditPurchaseDialog([DailyPurchaseModel? existing]) {
    final formKey = GlobalKey<FormState>();

    final billNoCtrl = TextEditingController(text: existing?.billNumber ?? 'BILL-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}');
    final invoiceCtrl = TextEditingController(text: existing?.invoiceNumber ?? '');
    final shopNameCtrl = TextEditingController(text: existing?.shopName ?? '');
    final shopTypeCtrl = TextEditingController(text: existing?.shopType ?? 'Groceries');
    final billingDateCtrl = TextEditingController(text: existing?.billingDate ?? DateTime.now().toString().split(' ')[0]);
    final dueDateCtrl = TextEditingController(text: existing?.dueDate ?? '');

    final deliveryCtrl = TextEditingController(text: existing?.deliveryCharge.toStringAsFixed(0) ?? '0');
    final packingCtrl = TextEditingController(text: existing?.packingCharge.toStringAsFixed(0) ?? '0');
    final discountCtrl = TextEditingController(text: existing?.discount.toStringAsFixed(0) ?? '0');
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');

    ContactModel? selectedContact = _contacts.firstWhere(
      (c) => c.businessShopName.toLowerCase() == (existing?.shopName ?? '').toLowerCase() || c.ownerName.toLowerCase() == (existing?.shopName ?? '').toLowerCase(),
      orElse: () => _contacts.isNotEmpty ? _contacts.first : ContactModel(
        id: 'c_default',
        createdAt: '',
        updatedAt: '',
        ownerName: 'General Store',
        mobileNumber: '',
        businessShopName: 'DMart Supermarket',
      ),
    );

    if (existing == null && _contacts.isNotEmpty) {
      shopNameCtrl.text = selectedContact.businessShopName;
    }

    List<DailyPurchaseItemModel> draftItems = existing != null ? List.from(existing.items) : [];
    List<DailyPaymentHistoryModel> draftPayments = existing != null ? List.from(existing.paymentHistory) : [];

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            // Calculations
            double subtotal = 0.0;
            double totalTax = 0.0;
            for (final item in draftItems) {
              subtotal += item.totalPrice;
              totalTax += item.tax;
            }

            final deliv = double.tryParse(deliveryCtrl.text.trim()) ?? 0.0;
            final pack = double.tryParse(packingCtrl.text.trim()) ?? 0.0;
            final disc = double.tryParse(discountCtrl.text.trim()) ?? 0.0;
            final grandTotal = subtotal + totalTax + deliv + pack - disc;

            double paid = 0.0;
            for (final pay in draftPayments) {
              paid += pay.amount;
            }
            final due = grandTotal - paid > 0 ? grandTotal - paid : 0.0;

            String status = 'Paid';
            if (due <= 0) {
              status = 'Paid';
            } else if (paid > 0 && due > 0) {
              status = 'Partially Paid';
            } else {
              status = 'Due';
            }

            return AlertDialog(
              backgroundColor: AppTheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text(
                existing == null ? 'Record New Purchase Bill' : 'Edit Purchase Bill',
                style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700),
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.88,
                height: 560,
                child: DefaultTabController(
                  length: 4,
                  child: Column(
                    children: [
                      TabBar(
                        isScrollable: true,
                        indicatorColor: AppTheme.primaryTeal,
                        labelColor: AppTheme.primaryTeal,
                        unselectedLabelColor: AppTheme.textSecondary,
                        tabs: const [
                          Tab(text: 'Shop & Bill Info'),
                          Tab(text: 'Purchased Items'),
                          Tab(text: 'Summary & Charges'),
                          Tab(text: 'Payment & Split'),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: Form(
                          key: formKey,
                          child: TabBarView(
                            children: [
                              // Tab 1: Shop & Invoice Details (With Contact Picklist)
                              SingleChildScrollView(
                                child: Column(
                                  children: [
                                    // Interactive Contact / Merchant Picklist
                                    Autocomplete<ContactModel>(
                                      initialValue: TextEditingValue(text: shopNameCtrl.text),
                                      displayStringForOption: (c) => '${c.businessShopName} (${c.ownerName})',
                                      optionsBuilder: (textVal) {
                                        if (textVal.text.isEmpty) return _contacts;
                                        return _contacts.where((c) =>
                                            c.businessShopName.toLowerCase().contains(textVal.text.toLowerCase()) ||
                                            c.ownerName.toLowerCase().contains(textVal.text.toLowerCase()) ||
                                            c.mobileNumber.contains(textVal.text));
                                      },
                                      onSelected: (c) {
                                        setDlgState(() {
                                          selectedContact = c;
                                          shopNameCtrl.text = c.businessShopName;
                                        });
                                      },
                                      fieldViewBuilder: (ctx, ctrl, focusNode, onSubmitted) {
                                        return TextFormField(
                                          controller: ctrl,
                                          focusNode: focusNode,
                                          style: const TextStyle(color: AppTheme.textPrimary),
                                          decoration: InputDecoration(
                                            labelText: 'Select Merchant from Contact Picklist *',
                                            prefixIcon: const Icon(Icons.storefront_rounded, color: AppTheme.primaryTeal),
                                            suffixIcon: PopupMenuButton<ContactModel>(
                                              icon: const Icon(Icons.arrow_drop_down_rounded, color: AppTheme.textHint),
                                              onSelected: (c) {
                                                setDlgState(() {
                                                  selectedContact = c;
                                                  ctrl.text = c.businessShopName;
                                                  shopNameCtrl.text = c.businessShopName;
                                                });
                                              },
                                              itemBuilder: (ctx) => _contacts.map((c) {
                                                return PopupMenuItem(
                                                  value: c,
                                                  child: Text('${c.businessShopName} • ${c.ownerName}'),
                                                );
                                              }).toList(),
                                            ),
                                          ),
                                          onChanged: (v) => shopNameCtrl.text = v,
                                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Shop name is required' : null,
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 12),

                                    // Display Auto Notification Preference Pill
                                    if (selectedContact != null && selectedContact!.mobileNumber.isNotEmpty) ...[
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryTeal.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.bolt_rounded, color: AppTheme.primaryTeal, size: 18),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                selectedContact!.enableNotification
                                                    ? 'Auto-dispatch invoice via ${selectedContact!.notificationMethod} to +91 ${selectedContact!.mobileNumber}'
                                                    : 'Notifications disabled for ${selectedContact!.ownerName}',
                                                style: const TextStyle(color: AppTheme.primaryTeal, fontSize: 12, fontWeight: FontWeight.w600),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                    ],

                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller: billNoCtrl,
                                            style: const TextStyle(color: AppTheme.textPrimary),
                                            decoration: const InputDecoration(labelText: 'Bill / Receipt No *'),
                                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Bill number required' : null,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: TextFormField(
                                            controller: invoiceCtrl,
                                            style: const TextStyle(color: AppTheme.textPrimary),
                                            decoration: const InputDecoration(labelText: 'GST Invoice No (Optional)'),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller: billingDateCtrl,
                                            style: const TextStyle(color: AppTheme.textPrimary),
                                            decoration: const InputDecoration(labelText: 'Billing Date (YYYY-MM-DD)'),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: TextFormField(
                                            controller: dueDateCtrl,
                                            style: const TextStyle(color: AppTheme.textPrimary),
                                            decoration: const InputDecoration(labelText: 'Due Date (If Unpaid)'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Tab 2: Itemized Products
                              Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Items List (${draftItems.length})', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
                                      ElevatedButton.icon(
                                        onPressed: () => _showAddItemDialog((newItem) {
                                          setDlgState(() => draftItems.add(newItem));
                                        }),
                                        icon: const Icon(Icons.add_rounded, size: 16),
                                        label: const Text('Add Item'),
                                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Expanded(
                                    child: draftItems.isEmpty
                                        ? const Center(child: Text('Tap "+ Add Item" to attach products to this bill', style: TextStyle(color: AppTheme.textHint)))
                                        : ListView.builder(
                                            itemCount: draftItems.length,
                                            itemBuilder: (ctx, i) {
                                              final it = draftItems[i];
                                              return Container(
                                                margin: const EdgeInsets.only(bottom: 8),
                                                padding: const EdgeInsets.all(12),
                                                decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(14)),
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(it.productName, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                                                          Text('${it.quantity} ${it.unit} x ₹${it.unitPrice.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.textHint, fontSize: 12)),
                                                        ],
                                                      ),
                                                    ),
                                                    Text('₹${it.totalPrice.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.w700)),
                                                    IconButton(
                                                      icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 18),
                                                      onPressed: () => setDlgState(() => draftItems.removeAt(i)),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                  ),
                                ],
                              ),

                              // Tab 3: Summary Charges & Calculations
                              SingleChildScrollView(
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller: deliveryCtrl,
                                            keyboardType: TextInputType.number,
                                            style: const TextStyle(color: AppTheme.textPrimary),
                                            decoration: const InputDecoration(labelText: 'Delivery Charge (₹)'),
                                            onChanged: (_) => setDlgState(() {}),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: TextFormField(
                                            controller: packingCtrl,
                                            keyboardType: TextInputType.number,
                                            style: const TextStyle(color: AppTheme.textPrimary),
                                            decoration: const InputDecoration(labelText: 'Packing Charge (₹)'),
                                            onChanged: (_) => setDlgState(() {}),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: discountCtrl,
                                      keyboardType: TextInputType.number,
                                      style: const TextStyle(color: AppTheme.textPrimary),
                                      decoration: const InputDecoration(labelText: 'Total Bill Discount (₹)'),
                                      onChanged: (_) => setDlgState(() {}),
                                    ),
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(16)),
                                      child: Column(
                                        children: [
                                          _buildSummaryRow('Subtotal Items:', '₹${subtotal.toStringAsFixed(2)}'),
                                          _buildSummaryRow('Tax / GST Total:', '₹${totalTax.toStringAsFixed(2)}'),
                                          _buildSummaryRow('Delivery & Packing:', '₹${(deliv + pack).toStringAsFixed(2)}'),
                                          _buildSummaryRow('Discount Applied:', '-₹${disc.toStringAsFixed(2)}'),
                                          const Divider(color: Colors.white10),
                                          _buildSummaryRow('Grand Total:', '₹${grandTotal.toStringAsFixed(2)}', isBold: true),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Tab 4: Multi / Split Payment Engine
                              Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Split Payments (Paid: ₹${paid.toStringAsFixed(0)})', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
                                      ElevatedButton.icon(
                                        onPressed: () => _showAddPaymentDialog(due > 0 ? due : grandTotal, (newPay) {
                                          setDlgState(() => draftPayments.add(newPay));
                                        }),
                                        icon: const Icon(Icons.add_card_rounded, size: 16),
                                        label: const Text('Add Payment'),
                                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: (due <= 0 ? AppTheme.success : AppTheme.error).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Status: $status', style: TextStyle(color: due <= 0 ? AppTheme.success : AppTheme.error, fontWeight: FontWeight.w700)),
                                        Text('Remaining Due: ₹${due.toStringAsFixed(2)}', style: TextStyle(color: due <= 0 ? AppTheme.success : AppTheme.error, fontWeight: FontWeight.w800)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Expanded(
                                    child: draftPayments.isEmpty
                                        ? const Center(child: Text('Tap "+ Add Payment" to log cash, UPI, or card entries', style: TextStyle(color: AppTheme.textHint)))
                                        : ListView.builder(
                                            itemCount: draftPayments.length,
                                            itemBuilder: (ctx, i) {
                                              final py = draftPayments[i];
                                              return Container(
                                                margin: const EdgeInsets.only(bottom: 8),
                                                padding: const EdgeInsets.all(12),
                                                decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(14)),
                                                child: Row(
                                                  children: [
                                                    const Icon(Icons.payment_rounded, color: AppTheme.primaryTeal, size: 20),
                                                    const SizedBox(width: 10),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(py.paymentMethod, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                                                          Text(py.paymentDate, style: const TextStyle(color: AppTheme.textHint, fontSize: 12)),
                                                        ],
                                                      ),
                                                    ),
                                                    Text('₹${py.amount.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.w700)),
                                                    IconButton(
                                                      icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 18),
                                                      onPressed: () => setDlgState(() => draftPayments.removeAt(i)),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel', style: TextStyle(color: AppTheme.textHint)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;

                    final p = DailyPurchaseModel(
                      id: existing?.id ?? '',
                      createdAt: existing?.createdAt ?? DateTime.now().toUtc().toIso8601String(),
                      updatedAt: DateTime.now().toUtc().toIso8601String(),
                      purchaseId: existing?.purchaseId ?? '',
                      billNumber: billNoCtrl.text.trim(),
                      invoiceNumber: invoiceCtrl.text.trim().isNotEmpty ? invoiceCtrl.text.trim() : null,
                      shopName: shopNameCtrl.text.trim(),
                      shopType: shopTypeCtrl.text.trim(),
                      billingDate: billingDateCtrl.text.trim(),
                      dueDate: dueDateCtrl.text.trim().isNotEmpty ? dueDateCtrl.text.trim() : null,
                      subtotal: subtotal,
                      discount: disc,
                      tax: totalTax,
                      deliveryCharge: deliv,
                      packingCharge: pack,
                      grandTotal: grandTotal,
                      amountPaid: paid,
                      dueAmount: due,
                      paymentStatus: status,
                      paymentMethod: draftPayments.isNotEmpty ? draftPayments.first.paymentMethod : 'Cash',
                      notes: notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
                    );

                    Navigator.pop(dialogCtx);
                    await _trackerService.savePurchase(p, draftItems, draftPayments);

                    // Auto dispatch transaction invoice if enabled
                    _autoDispatchInvoice(p, selectedContact);

                    _loadInitialData();
                  },
                  child: Text(existing == null ? 'Save Purchase' : 'Update Purchase'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ── Inline Add Line Item Dialog ────────────────────────────────────
  void _showAddItemDialog(Function(DailyPurchaseItemModel) onAdded) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    final priceCtrl = TextEditingController();
    final mktCtrl = TextEditingController();
    String unit = 'Piece';
    String category = 'Food & Dining';

    showDialog(
      context: context,
      builder: (dlgCtx) {
        return StatefulBuilder(
          builder: (context, setItemState) {
            return AlertDialog(
              backgroundColor: AppTheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Add Product to Bill', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Catalog Auto-complete or custom text
                    Autocomplete<ProductModel>(
                      displayStringForOption: (p) => p.productNameEnglish,
                      optionsBuilder: (textValue) {
                        if (textValue.text.isEmpty) return const Iterable<ProductModel>.empty();
                        return _catalogProducts.where((p) => p.productNameEnglish.toLowerCase().contains(textValue.text.toLowerCase()));
                      },
                      onSelected: (p) {
                        nameCtrl.text = p.productNameEnglish;
                        priceCtrl.text = p.currentPrice.toStringAsFixed(0);
                        mktCtrl.text = p.marketPrice.toStringAsFixed(0);
                        unit = p.unit;
                        category = p.categoryName;
                      },
                      fieldViewBuilder: (ctx, ctrl, focusNode, onFieldSubmitted) {
                        return TextFormField(
                          controller: ctrl,
                          focusNode: focusNode,
                          style: const TextStyle(color: AppTheme.textPrimary),
                          decoration: const InputDecoration(labelText: 'Search Product Catalog or Type Name *'),
                          onChanged: (v) => nameCtrl.text = v,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Product name is required' : null,
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: qtyCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: AppTheme.textPrimary),
                            decoration: const InputDecoration(labelText: 'Quantity *'),
                            validator: (v) => (v == null || double.tryParse(v) == null) ? 'Enter qty' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: priceCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: AppTheme.textPrimary),
                            decoration: const InputDecoration(labelText: 'Unit Price (₹) *'),
                            validator: (v) => (v == null || double.tryParse(v) == null) ? 'Enter price' : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dlgCtx),
                  child: const Text('Cancel', style: TextStyle(color: AppTheme.textHint)),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    final q = double.parse(qtyCtrl.text.trim());
                    final p = double.parse(priceCtrl.text.trim());
                    final mkt = double.tryParse(mktCtrl.text.trim()) ?? p;

                    final item = DailyPurchaseItemModel(
                      id: BaseModel.newId(),
                      createdAt: DateTime.now().toUtc().toIso8601String(),
                      updatedAt: DateTime.now().toUtc().toIso8601String(),
                      purchaseId: '',
                      productName: nameCtrl.text.trim(),
                      category: category,
                      quantity: q,
                      unit: unit,
                      unitPrice: p,
                      marketPrice: mkt,
                      totalPrice: q * p,
                    );

                    Navigator.pop(dlgCtx);
                    onAdded(item);
                  },
                  child: const Text('Add Item'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ── Inline Add Split Payment Dialog ────────────────────────────────
  void _showAddPaymentDialog(double remainingDue, Function(DailyPaymentHistoryModel) onAdded) {
    final amtCtrl = TextEditingController(text: remainingDue.toStringAsFixed(0));
    String method = 'UPI';

    showDialog(
      context: context,
      builder: (dlgCtx) {
        return StatefulBuilder(
          builder: (context, setPayState) {
            return AlertDialog(
              backgroundColor: AppTheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Add Split Payment Entry', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: amtCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(labelText: 'Payment Amount (₹)'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: method,
                    dropdownColor: AppTheme.card,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(labelText: 'Payment Method'),
                    items: ['Cash', 'UPI', 'Wallet', 'Credit Card', 'Debit Card', 'Net Banking']
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (v) => setPayState(() => method = v!),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dlgCtx),
                  child: const Text('Cancel', style: TextStyle(color: AppTheme.textHint)),
                ),
                ElevatedButton(
                  onPressed: () {
                    final amt = double.tryParse(amtCtrl.text.trim()) ?? 0.0;
                    if (amt <= 0) return;

                    final pay = DailyPaymentHistoryModel(
                      id: BaseModel.newId(),
                      createdAt: DateTime.now().toUtc().toIso8601String(),
                      updatedAt: DateTime.now().toUtc().toIso8601String(),
                      purchaseId: '',
                      paymentMethod: method,
                      amount: amt,
                      paymentDate: DateTime.now().toString().split(' ')[0],
                    );

                    Navigator.pop(dlgCtx);
                    onAdded(pay);
                  },
                  child: const Text('Save Payment'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isBold ? AppTheme.textPrimary : AppTheme.textHint, fontWeight: isBold ? FontWeight.w700 : FontWeight.w500)),
          Text(value, style: TextStyle(color: isBold ? AppTheme.primaryTeal : AppTheme.textPrimary, fontWeight: isBold ? FontWeight.w800 : FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final metrics = _trackerService.calculateMetrics(_allPurchases);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditPurchaseDialog(),
        backgroundColor: AppTheme.primaryViolet,
        icon: const Icon(Icons.receipt_long_rounded, color: Colors.white),
        label: const Text('Record Purchase', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: RefreshIndicator(
        onRefresh: _loadInitialData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Action Header with Send Monthly Invoice Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Daily Expense & Financial Metrics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                  ElevatedButton.icon(
                    onPressed: _showMonthlyInvoiceModal,
                    icon: const Icon(Icons.send_rounded, size: 16),
                    label: const Text('Send Monthly Invoice'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryTeal,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── 17 Dashboard Metrics Summary Grid ────────────────────────
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildMetricCard('Today', '₹${metrics.todayExpenses.toStringAsFixed(0)}', Icons.today_rounded, AppTheme.primaryTeal),
                    _buildMetricCard('This Week', '₹${metrics.weekExpenses.toStringAsFixed(0)}', Icons.date_range_rounded, AppTheme.primaryViolet),
                    _buildMetricCard('This Month', '₹${metrics.monthExpenses.toStringAsFixed(0)}', Icons.calendar_month_rounded, Colors.orangeAccent),
                    _buildMetricCard('This Year', '₹${metrics.yearExpenses.toStringAsFixed(0)}', Icons.calendar_today_rounded, Colors.pinkAccent),
                    _buildMetricCard('Outstanding Due', '₹${metrics.totalOutstandingDue.toStringAsFixed(0)}', Icons.warning_amber_rounded, AppTheme.error),
                    _buildMetricCard('Total Paid', '₹${metrics.totalPaidAmount.toStringAsFixed(0)}', Icons.check_circle_outline_rounded, AppTheme.success),
                    _buildMetricCard('Savings (vs Mkt)', '₹${metrics.totalSavings.toStringAsFixed(0)}', Icons.savings_rounded, AppTheme.accentGold),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Sticky Search Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(20)),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchCtrl,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Search by Bill No, Shop Name, Item, or Status...',
                        prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textHint),
                        fillColor: AppTheme.card,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: ['All', 'Paid', 'Partially Paid', 'Due'].map((st) {
                            final sel = _statusFilter == st;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(st),
                                selected: sel,
                                selectedColor: AppTheme.primaryTeal.withValues(alpha: 0.25),
                                labelStyle: TextStyle(color: sel ? AppTheme.primaryTeal : AppTheme.textSecondary, fontSize: 12),
                                onSelected: (_) {
                                  setState(() => _statusFilter = st);
                                  _onSearchChanged();
                                },
                              ),
                            );
                          }).toList(),
                        ),
                        Text('${_filteredPurchases.length} Bills', style: const TextStyle(color: AppTheme.textHint, fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              if (_isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: AppTheme.primaryTeal)))
              else if (_filteredPurchases.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(20)),
                  child: Column(
                    children: const [
                      Icon(Icons.receipt_long_outlined, size: 48, color: AppTheme.textHint),
                      SizedBox(height: 12),
                      Text('No purchase bills recorded', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                      SizedBox(height: 4),
                      Text('Tap "Record Purchase" to log daily items and expenses', style: TextStyle(color: AppTheme.textHint, fontSize: 12)),
                    ],
                  ),
                )
              else
                ..._filteredPurchases.map((p) {
                  final isFullyPaid = p.isFullyPaid;
                  final isDue = p.isDue;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppTheme.primaryViolet.withValues(alpha: 0.2),
                                  child: const Icon(Icons.storefront_rounded, color: AppTheme.primaryTeal, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p.shopName, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
                                    Text('${p.billNumber} • ${p.billingDate}', style: const TextStyle(color: AppTheme.textHint, fontSize: 12)),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: (isFullyPaid ? AppTheme.success : (isDue ? AppTheme.error : Colors.orangeAccent)).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                p.paymentStatus,
                                style: TextStyle(
                                  color: isFullyPaid ? AppTheme.success : (isDue ? AppTheme.error : Colors.orangeAccent),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),
                        const Divider(color: Colors.white10),

                        // Item preview
                        if (p.items.isNotEmpty) ...[
                          Text(
                            'Items (${p.items.length}): ${p.items.map((i) => '${i.productName} (${i.quantity} ${i.unit})').join(', ')}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                          ),
                          const SizedBox(height: 10),
                        ],

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Grand Total: ${p.currency}${p.grandTotal.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w800, fontSize: 16)),
                                if (p.dueAmount > 0) ...[
                                  Text('Remaining Due: ${p.currency}${p.dueAmount.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.error, fontWeight: FontWeight.w600, fontSize: 12)),
                                ],
                              ],
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, color: AppTheme.textHint, size: 20),
                                  onPressed: () => _showAddEditPurchaseDialog(p),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 20),
                                  onPressed: () async {
                                    await _trackerService.deletePurchase(p.id);
                                    _loadInitialData();
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(String label, String amount, IconData icon, Color color) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(color: AppTheme.textHint, fontSize: 11)),
          const SizedBox(height: 2),
          Text(amount, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
