import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

import '../models/price_history_model.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';

/// Enterprise Product Catalog View — Multilingual, Barcode/QR Engine, Price Trends & History.
class CatalogView extends StatefulWidget {
  const CatalogView({super.key});

  @override
  State<CatalogView> createState() => _CatalogViewState();
}

class _CatalogViewState extends State<CatalogView> {
  final _productService = ProductService.instance;
  final _searchCtrl = TextEditingController();

  List<ProductModel> _allProducts = [];
  List<ProductModel> _filteredProducts = [];
  bool _isLoading = true;

  String _selectedStatusFilter = 'All';
  final String _activeLangCode = 'hi'; // Default active local language: Hindi

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    final list = await _productService.fetchProducts();
    if (!mounted) return;
    setState(() {
      _allProducts = list;
      _filteredProducts = list;
      _isLoading = false;
    });
  }

  void _onSearchChanged() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filteredProducts = _allProducts.where((p) {
        final matchesSearch = q.isEmpty ||
            p.productNameEnglish.toLowerCase().contains(q) ||
            p.productNameLocal.toLowerCase().contains(q) ||
            (p.barcode ?? '').toLowerCase().contains(q) ||
            (p.brand ?? '').toLowerCase().contains(q) ||
            (p.sku ?? '').toLowerCase().contains(q) ||
            (p.description ?? '').toLowerCase().contains(q);

        final matchesStatus = _selectedStatusFilter == 'All' ||
            p.statusBadge.toLowerCase() == _selectedStatusFilter.toLowerCase();

        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  // ── 1. Add / Edit Product Responsive Dialog (Tabbed) ────────────────
  void _showAddEditProductDialog([ProductModel? existingProduct]) {
    final formKey = GlobalKey<FormState>();

    final codeCtrl = TextEditingController(text: existingProduct?.productCode ?? 'PRD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}');
    final nameEngCtrl = TextEditingController(text: existingProduct?.productNameEnglish ?? '');
    final nameLocCtrl = TextEditingController(text: existingProduct?.productNameLocal ?? '');
    final brandCtrl = TextEditingController(text: existingProduct?.brand ?? '');
    final descCtrl = TextEditingController(text: existingProduct?.description ?? '');

    final currentPriceCtrl = TextEditingController(text: existingProduct != null ? existingProduct.currentPrice.toStringAsFixed(2) : '');
    final oldPriceCtrl = TextEditingController(text: existingProduct != null ? existingProduct.oldPrice.toStringAsFixed(2) : '');
    final marketPriceCtrl = TextEditingController(text: existingProduct != null ? existingProduct.marketPrice.toStringAsFixed(2) : '');
    final effectiveDateCtrl = TextEditingController(text: existingProduct?.effectiveDate ?? DateTime.now().toString().split(' ')[0]);

    final barcodeCtrl = TextEditingController(text: existingProduct?.barcode ?? '890${DateTime.now().millisecondsSinceEpoch.toString().substring(3)}');
    final skuCtrl = TextEditingController(text: existingProduct?.sku ?? 'SKU-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}');
    final hsnCtrl = TextEditingController(text: existingProduct?.hsnCode ?? '1006');
    final gstCtrl = TextEditingController(text: existingProduct?.gstPercentage.toStringAsFixed(0) ?? '5');
    final manufacturerCtrl = TextEditingController(text: existingProduct?.manufacturer ?? '');
    final countryCtrl = TextEditingController(text: existingProduct?.country ?? 'India');

    String selectedUnit = existingProduct?.unit ?? 'Kg';
    String selectedStatus = existingProduct?.statusBadge ?? 'Active';
    String barcodeType = existingProduct?.barcodeType ?? 'EAN-13';

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return AlertDialog(
              backgroundColor: AppTheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text(
                existingProduct == null ? 'Add Product to Catalog' : 'Edit Product Details',
                style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700),
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.85,
                height: 520,
                child: DefaultTabController(
                  length: 5,
                  child: Column(
                    children: [
                      TabBar(
                        isScrollable: true,
                        indicatorColor: AppTheme.primaryTeal,
                        labelColor: AppTheme.primaryTeal,
                        unselectedLabelColor: AppTheme.textSecondary,
                        tabs: const [
                          Tab(text: 'Basic Details'),
                          Tab(text: 'Pricing & Schedule'),
                          Tab(text: 'Barcode & QR'),
                          Tab(text: 'Specifications'),
                          Tab(text: 'Price History'),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: Form(
                          key: formKey,
                          child: TabBarView(
                            children: [
                              // Tab 1: Basic Details
                              SingleChildScrollView(
                                child: Column(
                                  children: [
                                    TextFormField(
                                      controller: nameEngCtrl,
                                      style: const TextStyle(color: AppTheme.textPrimary),
                                      decoration: const InputDecoration(
                                        labelText: 'Product Name (English) *',
                                        hintText: 'e.g. Basmati Rice',
                                      ),
                                      onChanged: (v) {
                                        // Auto-translate name when English name changes
                                        final translated = _productService.autoTranslate(v, _activeLangCode);
                                        nameLocCtrl.text = translated;
                                      },
                                      validator: (v) => (v == null || v.trim().isEmpty) ? 'English name is required' : null,
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: nameLocCtrl,
                                      style: const TextStyle(color: AppTheme.textPrimary),
                                      decoration: const InputDecoration(
                                        labelText: 'Local Name (Auto-translated / Editable)',
                                        hintText: 'e.g. बासमती चावल',
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller: codeCtrl,
                                            style: const TextStyle(color: AppTheme.textPrimary),
                                            decoration: const InputDecoration(labelText: 'Product Code'),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: TextFormField(
                                            controller: brandCtrl,
                                            style: const TextStyle(color: AppTheme.textPrimary),
                                            decoration: const InputDecoration(labelText: 'Brand Name'),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: DropdownButtonFormField<String>(
                                            initialValue: selectedUnit,
                                            dropdownColor: AppTheme.card,
                                            style: const TextStyle(color: AppTheme.textPrimary),
                                            decoration: const InputDecoration(labelText: 'Unit'),
                                            items: ['Kg', 'Gram', 'Liter', 'ml', 'Piece', 'Pack', 'Box', 'Bottle', 'Dozen', 'Meter']
                                                .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                                                .toList(),
                                            onChanged: (v) => setDlgState(() => selectedUnit = v!),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: DropdownButtonFormField<String>(
                                            initialValue: selectedStatus,
                                            dropdownColor: AppTheme.card,
                                            style: const TextStyle(color: AppTheme.textPrimary),
                                            decoration: const InputDecoration(labelText: 'Status Badge'),
                                            items: ['Active', 'Inactive', 'Discontinued', 'Out of Stock']
                                                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                                .toList(),
                                            onChanged: (v) => setDlgState(() => selectedStatus = v!),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Tab 2: Pricing & Schedule
                              SingleChildScrollView(
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller: currentPriceCtrl,
                                            keyboardType: TextInputType.number,
                                            style: const TextStyle(color: AppTheme.textPrimary),
                                            decoration: const InputDecoration(labelText: 'Current Price (₹) *'),
                                            validator: (v) => (v == null || double.tryParse(v) == null) ? 'Enter valid price' : null,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: TextFormField(
                                            controller: oldPriceCtrl,
                                            keyboardType: TextInputType.number,
                                            style: const TextStyle(color: AppTheme.textPrimary),
                                            decoration: const InputDecoration(labelText: 'Old Price (₹)'),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller: marketPriceCtrl,
                                            keyboardType: TextInputType.number,
                                            style: const TextStyle(color: AppTheme.textPrimary),
                                            decoration: const InputDecoration(labelText: 'Market Price (₹)'),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: TextFormField(
                                            controller: effectiveDateCtrl,
                                            style: const TextStyle(color: AppTheme.textPrimary),
                                            decoration: const InputDecoration(labelText: 'Effective Date (YYYY-MM-DD)'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Tab 3: Barcode & QR
                              SingleChildScrollView(
                                child: Column(
                                  children: [
                                    TextFormField(
                                      controller: barcodeCtrl,
                                      style: const TextStyle(color: AppTheme.textPrimary),
                                      decoration: const InputDecoration(labelText: 'Barcode Number'),
                                    ),
                                    const SizedBox(height: 12),
                                    DropdownButtonFormField<String>(
                                      initialValue: barcodeType,
                                      dropdownColor: AppTheme.card,
                                      style: const TextStyle(color: AppTheme.textPrimary),
                                      decoration: const InputDecoration(labelText: 'Barcode Standard'),
                                      items: ['EAN-13', 'Code128', 'UPC', 'Code39']
                                          .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                                          .toList(),
                                      onChanged: (v) => setDlgState(() => barcodeType = v!),
                                    ),
                                    const SizedBox(height: 20),
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(16)),
                                      child: Column(
                                        children: [
                                          const Icon(Icons.qr_code_2_rounded, size: 64, color: AppTheme.primaryTeal),
                                          const SizedBox(height: 8),
                                          Text('Payload: ${codeCtrl.text}|${nameEngCtrl.text}|${currentPriceCtrl.text}', style: const TextStyle(color: AppTheme.textHint, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Tab 4: Specifications
                              SingleChildScrollView(
                                child: Column(
                                  children: [
                                    TextFormField(
                                      controller: descCtrl,
                                      maxLines: 3,
                                      style: const TextStyle(color: AppTheme.textPrimary),
                                      decoration: const InputDecoration(labelText: 'Product Description'),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller: skuCtrl,
                                            style: const TextStyle(color: AppTheme.textPrimary),
                                            decoration: const InputDecoration(labelText: 'SKU'),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: TextFormField(
                                            controller: hsnCtrl,
                                            style: const TextStyle(color: AppTheme.textPrimary),
                                            decoration: const InputDecoration(labelText: 'HSN Code'),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller: gstCtrl,
                                            keyboardType: TextInputType.number,
                                            style: const TextStyle(color: AppTheme.textPrimary),
                                            decoration: const InputDecoration(labelText: 'GST Tax %'),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: TextFormField(
                                            controller: manufacturerCtrl,
                                            style: const TextStyle(color: AppTheme.textPrimary),
                                            decoration: const InputDecoration(labelText: 'Manufacturer'),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: countryCtrl,
                                      style: const TextStyle(color: AppTheme.textPrimary),
                                      decoration: const InputDecoration(labelText: 'Country of Origin'),
                                    ),
                                  ],
                                ),
                              ),

                              // Tab 5: Price History Timeline
                              FutureBuilder<List<PriceHistoryModel>>(
                                future: existingProduct != null
                                    ? _productService.fetchPriceHistory(existingProduct.id)
                                    : Future.value([]),
                                builder: (context, snapshot) {
                                  final history = snapshot.data ?? [];
                                  if (history.isEmpty) {
                                    return const Center(child: Text('No price changes recorded yet', style: TextStyle(color: AppTheme.textHint)));
                                  }
                                  return ListView.builder(
                                    itemCount: history.length,
                                    itemBuilder: (ctx, i) {
                                      final h = history[i];
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(12)),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(h.effectiveDate, style: const TextStyle(color: AppTheme.textHint, fontSize: 12)),
                                            Text('₹${h.oldPrice.toStringAsFixed(0)} ➔ ₹${h.newPrice.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.w700)),
                                            Text(h.updatedByUser, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
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

                    final cur = double.parse(currentPriceCtrl.text.trim());
                    final old = double.tryParse(oldPriceCtrl.text.trim()) ?? 0.0;
                    final mkt = double.tryParse(marketPriceCtrl.text.trim()) ?? 0.0;

                    final p = ProductModel(
                      id: existingProduct?.id ?? '',
                      createdAt: existingProduct?.createdAt ?? DateTime.now().toUtc().toIso8601String(),
                      updatedAt: DateTime.now().toUtc().toIso8601String(),
                      productCode: codeCtrl.text.trim(),
                      productNameEnglish: nameEngCtrl.text.trim(),
                      productNameLocal: nameLocCtrl.text.trim().isNotEmpty ? nameLocCtrl.text.trim() : nameEngCtrl.text.trim(),
                      languageCode: _activeLangCode,
                      brand: brandCtrl.text.trim().isNotEmpty ? brandCtrl.text.trim() : null,
                      description: descCtrl.text.trim().isNotEmpty ? descCtrl.text.trim() : null,
                      unit: selectedUnit,
                      oldPrice: old,
                      currentPrice: cur,
                      marketPrice: mkt,
                      effectiveDate: effectiveDateCtrl.text.trim(),
                      barcode: barcodeCtrl.text.trim().isNotEmpty ? barcodeCtrl.text.trim() : null,
                      barcodeType: barcodeType,
                      qrCode: '${codeCtrl.text.trim()}|${nameEngCtrl.text.trim()}|$cur',
                      sku: skuCtrl.text.trim(),
                      hsnCode: hsnCtrl.text.trim(),
                      gstPercentage: double.tryParse(gstCtrl.text.trim()) ?? 0.0,
                      manufacturer: manufacturerCtrl.text.trim().isNotEmpty ? manufacturerCtrl.text.trim() : null,
                      country: countryCtrl.text.trim(),
                      statusBadge: selectedStatus,
                    );

                    Navigator.pop(dialogCtx);
                    await _productService.saveProduct(p);
                    _loadProducts();
                  },
                  child: Text(existingProduct == null ? 'Save Product' : 'Update Product'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ── 2. Price History Modal ──────────────────────────────────────────
  void _openPriceHistoryModal(ProductModel product) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Price History — ${product.productNameEnglish}', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              FutureBuilder<List<PriceHistoryModel>>(
                future: _productService.fetchPriceHistory(product.id),
                builder: (context, snapshot) {
                  final history = snapshot.data ?? [];
                  if (history.isEmpty) {
                    return const Center(child: Text('No historical price changes recorded', style: TextStyle(color: AppTheme.textHint)));
                  }
                  return Column(
                    children: history.map((h) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(h.effectiveDate, style: const TextStyle(color: AppTheme.textHint, fontSize: 12)),
                            Text('₹${h.oldPrice.toStringAsFixed(0)} ➔ ₹${h.newPrice.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.w700)),
                            Text(h.updatedByUser, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditProductDialog(),
        backgroundColor: AppTheme.primaryViolet,
        icon: const Icon(Icons.add_shopping_cart_rounded, color: Colors.white),
        label: const Text('Add Product', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: RefreshIndicator(
        onRefresh: _loadProducts,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sticky Top Header (Search, Filters, Barcode Scanner Action)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(20)),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            style: const TextStyle(color: AppTheme.textPrimary),
                            decoration: InputDecoration(
                              hintText: 'Instant Search by Name, Local Name, Barcode, SKU, Brand...',
                              prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textHint),
                              fillColor: AppTheme.card,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          icon: const Icon(Icons.qr_code_scanner_rounded, color: AppTheme.primaryTeal, size: 28),
                          tooltip: 'Scan Barcode / QR',
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Barcode & QR Scanner Viewport Active')),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: ['All', 'Active', 'Out of Stock'].map((st) {
                            final sel = _selectedStatusFilter == st;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(st),
                                selected: sel,
                                selectedColor: AppTheme.primaryTeal.withValues(alpha: 0.25),
                                labelStyle: TextStyle(color: sel ? AppTheme.primaryTeal : AppTheme.textSecondary, fontSize: 12),
                                onSelected: (_) {
                                  setState(() => _selectedStatusFilter = st);
                                  _onSearchChanged();
                                },
                              ),
                            );
                          }).toList(),
                        ),
                        Text('${_filteredProducts.length} Items', style: const TextStyle(color: AppTheme.textHint, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              if (_isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: AppTheme.primaryTeal)))
              else if (_filteredProducts.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(20)),
                  child: Column(
                    children: const [
                      Icon(Icons.inventory_2_outlined, size: 48, color: AppTheme.textHint),
                      SizedBox(height: 12),
                      Text('No products found', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                      SizedBox(height: 4),
                      Text('Tap "Add Product" to create an enterprise catalog entry', style: TextStyle(color: AppTheme.textHint, fontSize: 12)),
                    ],
                  ),
                )
              else
                ..._filteredProducts.map((p) {
                  final isIncreased = p.priceTrend == 'increased';
                  final isReduced = p.priceTrend == 'reduced';

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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product Image / Thumbnail
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryViolet.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.shopping_bag_rounded, color: AppTheme.primaryTeal, size: 28),
                            ),
                            const SizedBox(width: 14),

                            // Name & Local Translation Badge
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        p.productNameEnglish,
                                        style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 16),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(color: AppTheme.primaryViolet.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                                        child: Text(
                                          p.productNameLocal,
                                          style: const TextStyle(color: AppTheme.primaryTeal, fontSize: 12, fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${p.brand ?? 'Generic'} • ${p.unit} • Effective ${p.effectiveDate}',
                                    style: const TextStyle(color: AppTheme.textHint, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),

                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: AppTheme.textHint, size: 20),
                              onPressed: () => _showAddEditProductDialog(p),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),
                        const Divider(color: Colors.white10),

                        // Price & Comparison Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '${p.currency}${p.currentPrice.toStringAsFixed(0)}/${p.unit}',
                                      style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w800, fontSize: 20),
                                    ),
                                    if (p.oldPrice > 0) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        '${p.currency}${p.oldPrice.toStringAsFixed(0)}',
                                        style: const TextStyle(color: AppTheme.textHint, decoration: TextDecoration.lineThrough, fontSize: 13),
                                      ),
                                    ],
                                  ],
                                ),
                                if (p.marketPrice > 0) ...[
                                  Text(
                                    'Market Price: ${p.currency}${p.marketPrice.toStringAsFixed(0)}',
                                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                  ),
                                ],
                              ],
                            ),

                            // Price Trend & Difference Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: (isIncreased ? AppTheme.error : (isReduced ? AppTheme.success : AppTheme.primaryViolet)).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    '${p.trendIcon} ${p.formattedPriceDiff}',
                                    style: TextStyle(
                                      color: isIncreased ? AppTheme.error : (isReduced ? AppTheme.success : AppTheme.primaryTeal),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Barcode & Action Shortcuts
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Barcode: ${p.barcode ?? 'N/A'}', style: const TextStyle(color: AppTheme.textHint, fontSize: 12)),
                            Row(
                              children: [
                                TextButton.icon(
                                  onPressed: () => _openPriceHistoryModal(p),
                                  icon: const Icon(Icons.history_rounded, size: 16, color: AppTheme.primaryTeal),
                                  label: const Text('Price History', style: TextStyle(color: AppTheme.primaryTeal, fontSize: 12)),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 20),
                                  onPressed: () async {
                                    await _productService.deleteProduct(p.id);
                                    _loadProducts();
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
}
