import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product.dart';
import '../data/master_product_catalog.dart';
import '../providers/finance_provider.dart';
import '../services/web_product_search_service.dart';
import '../utils/hinglish_translator.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _isSyncingPrices = false;
  final Set<int> _syncingProductIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performWebProductSearch(BuildContext context, FinanceProvider provider, String query) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121422),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('🌐 Web Product Search Results', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('Google & Web Product Results for "$query"', style: const TextStyle(color: Colors.tealAccent, fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(color: Colors.white10),
              Expanded(
                child: FutureBuilder<List<Product>>(
                  future: WebProductSearchService.searchWebProducts(query),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: Colors.tealAccent),
                            SizedBox(height: 16),
                            Text('Searching web for product details...', style: TextStyle(color: Colors.white70)),
                          ],
                        ),
                      );
                    }

                    final webProducts = snapshot.data ?? [];
                    if (webProducts.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off_outlined, size: 64, color: Colors.white38),
                            const SizedBox(height: 16),
                            Text('No web products found matching "$query"', style: const TextStyle(color: Colors.white70)),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: webProducts.length,
                      itemBuilder: (context, idx) {
                        final webP = webProducts[idx];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16192E),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (webP.imageUrl.startsWith('http'))
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        webP.imageUrl,
                                        width: 44,
                                        height: 44,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Container(
                                          width: 44,
                                          height: 44,
                                          color: Colors.tealAccent.withValues(alpha: 0.1),
                                          child: const Icon(Icons.shopping_bag, color: Colors.tealAccent),
                                        ),
                                      ),
                                    )
                                  else
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: Colors.tealAccent.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.shopping_bag, color: Colors.tealAccent),
                                    ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          webP.productName,
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                        if (webP.localName.isNotEmpty)
                                          Text(
                                            webP.localName,
                                            style: const TextStyle(color: Colors.amberAccent, fontSize: 12),
                                          ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.4)),
                                          ),
                                          child: Text(
                                            '🏷️ ${webP.category}',
                                            style: const TextStyle(color: Color(0xFFA5B4FC), fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.tealAccent.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${provider.defaultCurrency}${webP.currentPrice.toStringAsFixed(0)} / ${webP.quantity.toStringAsFixed(webP.quantity == webP.quantity.roundToDouble() ? 0 : 1)} ${webP.unit}',
                                      style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                              if (webP.description.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.04),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.white12),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.description_outlined, size: 14, color: Colors.tealAccent),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Description: ${webP.description}',
                                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Source: ${webP.appName}',
                                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                                  ),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.tealAccent,
                                      foregroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    icon: const Icon(Icons.add_task, size: 16),
                                    label: const Text('Select & Insert to DB', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                    onPressed: () async {
                                      await provider.addProduct(webP);
                                      if (ctx.mounted) {
                                        Navigator.pop(ctx);
                                      }
                                      if (context.mounted) {
                                        setState(() {
                                          _searchQuery = '';
                                          _searchController.clear();
                                          _selectedCategory = 'All';
                                        });
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('✅ Successfully inserted "${webP.productName}" into database with all details!'),
                                            backgroundColor: Colors.teal,
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteAllProducts(BuildContext context, FinanceProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16192E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Delete All Products?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete ALL products from your database? This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            icon: const Icon(Icons.delete_forever, size: 18),
            label: const Text('Delete All', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.deleteAllProducts();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🗑️ All products deleted from database.'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _showMasterCatalogSheet(BuildContext context, FinanceProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121422),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final catalog = MasterProductCatalog.items;
            String catSearch = '';
            String selectedCat = 'All';

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('📚 Master Product Catalog', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('Vegetables, Fruits, Groceries, Medicines, Personal Care', style: TextStyle(color: Colors.tealAccent, fontSize: 12)),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white10),
                  Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: ['All', 'Vegetables', 'Fruits', 'Groceries', 'Medicines', 'Personal Care'].map((cat) {
                              final isSel = selectedCat == cat;
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ChoiceChip(
                                  label: Text(cat),
                                  selected: isSel,
                                  selectedColor: Colors.tealAccent,
                                  labelStyle: TextStyle(color: isSel ? Colors.black : Colors.white70, fontWeight: FontWeight.bold, fontSize: 12),
                                  backgroundColor: const Color(0xFF16192E),
                                  onSelected: (selected) {
                                    if (selected) {
                                      setSheetState(() => selectedCat = cat);
                                    }
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search catalog (e.g. Mango, Potato, KitKat, Sugar)...',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                      prefixIcon: const Icon(Icons.search, color: Colors.tealAccent),
                      filled: true,
                      fillColor: const Color(0xFF16192E),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    onChanged: (val) => setSheetState(() => catSearch = val.trim().toLowerCase()),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final items = catalog.where((p) {
                          final matchCat = selectedCat == 'All' || p.category.toLowerCase() == selectedCat.toLowerCase();
                          if (catSearch.isEmpty) return matchCat;
                          return matchCat && (p.productName.toLowerCase().contains(catSearch) || p.localName.toLowerCase().contains(catSearch) || p.category.toLowerCase().contains(catSearch));
                        }).toList();

                        if (items.isEmpty) {
                          return const Center(
                            child: Text('No catalog products found', style: TextStyle(color: Colors.white54)),
                          );
                        }

                        return ListView.builder(
                          itemCount: items.length,
                          itemBuilder: (context, idx) {
                            final p = items[idx];
                            final existsInDb = provider.products.any((dp) => dp.productName.toLowerCase() == p.productName.toLowerCase());

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF16192E),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(p.productName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                        if (p.localName.isNotEmpty)
                                          Text(p.localName, style: const TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 2),
                                        Text('🏷️ ${p.category}  •  ${provider.defaultCurrency}${p.currentPrice.toStringAsFixed(0)} / ${p.quantity} ${p.unit}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: existsInDb ? Colors.white12 : Colors.tealAccent,
                                      foregroundColor: existsInDb ? Colors.white54 : Colors.black,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    ),
                                    icon: Icon(existsInDb ? Icons.check : Icons.add, size: 16),
                                    label: Text(existsInDb ? 'Added' : 'Add', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                    onPressed: existsInDb ? null : () async {
                                      await provider.addProduct(p);
                                      setSheetState(() {});
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('✅ Added "${p.productName}" (${p.localName}) to database!'), backgroundColor: Colors.teal, duration: const Duration(seconds: 2)),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);
    final allProds = provider.products;

    final categories = ['All', ...allProds.map((p) => p.category).toSet().toList()..sort()];

    final filtered = allProds.where((p) {
      final matchesCat = _selectedCategory == 'All' || p.category == _selectedCategory;
      if (_searchQuery.isEmpty) return matchesCat;
      final q = _searchQuery.toLowerCase();
      return matchesCat && (p.productName.toLowerCase().contains(q) ||
          p.localName.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q) ||
          p.appName.toLowerCase().contains(q) ||
          p.unit.toLowerCase().contains(q));
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Product Master / Catalog', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('${allProds.where((p) => p.active).length} Active Products', style: const TextStyle(fontSize: 12, color: Colors.tealAccent)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book_outlined, color: Colors.tealAccent),
            tooltip: 'Browse Master Catalog',
            onPressed: () => _showMasterCatalogSheet(context, provider),
          ),
          IconButton(
            icon: _isSyncingPrices
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amberAccent),
                  )
                : const Icon(Icons.bolt, color: Colors.amberAccent),
            tooltip: 'Sync Best Lowest Prices across Stores',
            onPressed: _isSyncingPrices
                ? null
                : () async {
                    setState(() => _isSyncingPrices = true);
                    final synced = await provider.batchSyncAllProductsBestPrices();
                    if (mounted) {
                      setState(() => _isSyncingPrices = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('⚡ Successfully benchmarked & updated lowest prices for $synced products!'),
                          backgroundColor: Colors.teal,
                        ),
                      );
                    }
                  },
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever_outlined, color: Colors.redAccent),
            tooltip: 'Delete All Products',
            onPressed: () => _confirmDeleteAllProducts(context, provider),
          ),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.tealAccent,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_shopping_cart, fontWeight: FontWeight.bold),
        label: const Text('Add Product', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _showAddEditProductSheet(context, provider),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF080914), Color(0xFF0E111F)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search product by name, local name, or category...',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: Colors.tealAccent),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white54),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFF16192E),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
                onChanged: (v) {
                  setState(() {
                    _searchQuery = v.trim();
                  });
                },
              ),
            ),

            if (_searchQuery.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 12.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amberAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.travel_explore, fontWeight: FontWeight.bold),
                    label: Text(
                      'Search Web for "$_searchQuery"',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    onPressed: () => _performWebProductSearch(context, provider, _searchQuery),
                  ),
                ),
              ),

            // Category Filter Chips
            Container(
              height: 38,
              margin: const EdgeInsets.only(bottom: 12),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: categories.length,
                itemBuilder: (context, idx) {
                  final cat = categories[idx];
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(cat),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.black : Colors.white,
                      ),
                      selected: isSelected,
                      selectedColor: Colors.tealAccent,
                      backgroundColor: const Color(0xFF16192E),
                      onSelected: (val) {
                        if (val) {
                          setState(() {
                            _selectedCategory = cat;
                          });
                        }
                      },
                    ),
                  );
                },
              ),
            ),

            // Product Cards List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.white.withValues(alpha: 0.2)),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty ? 'No products in catalog yet' : 'No products found matching "$_searchQuery"',
                            style: const TextStyle(color: Colors.white54, fontSize: 14),
                          ),
                          const SizedBox(height: 12),
                          if (_searchQuery.isNotEmpty) ...[
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.amberAccent, foregroundColor: Colors.black),
                              icon: const Icon(Icons.travel_explore),
                              label: Text('Search Web for "$_searchQuery"'),
                              onPressed: () => _performWebProductSearch(context, provider, _searchQuery),
                            ),
                            const SizedBox(height: 8),
                          ],
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.tealAccent, foregroundColor: Colors.black),
                            icon: const Icon(Icons.add),
                            label: const Text('Create Manually'),
                            onPressed: () => _showAddEditProductSheet(context, provider),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final p = filtered[index];
                        final hasPriceDrop = p.oldPrice > 0 && p.currentPrice < p.oldPrice;
                        final hasPriceIncrease = p.oldPrice > 0 && p.currentPrice > p.oldPrice;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16192E),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: p.active ? Colors.tealAccent.withValues(alpha: 0.2) : Colors.white10,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      color: p.active ? Colors.tealAccent.withValues(alpha: 0.15) : Colors.white10,
                                      child: p.imageUrl.startsWith('http')
                                          ? Image.network(
                                              p.imageUrl,
                                              width: 40,
                                              height: 40,
                                              fit: BoxFit.cover,
                                              errorBuilder: (ctx, err, stack) => Center(
                                                child: Text(
                                                  p.productName.isNotEmpty ? p.productName[0].toUpperCase() : '?',
                                                  style: TextStyle(
                                                    color: p.active ? Colors.tealAccent : Colors.white38,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ),
                                            )
                                          : Center(
                                              child: Text(
                                                p.productName.isNotEmpty ? p.productName[0].toUpperCase() : '?',
                                                style: TextStyle(
                                                  color: p.active ? Colors.tealAccent : Colors.white38,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                p.productName,
                                                style: TextStyle(
                                                  color: p.active ? Colors.white : Colors.white38,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  decoration: p.active ? null : TextDecoration.lineThrough,
                                                ),
                                              ),
                                            ),
                                            Switch(
                                              value: p.active,
                                              activeColor: Colors.tealAccent,
                                              onChanged: (val) {
                                                if (p.id != null) {
                                                  provider.toggleProductStatus(p.id!);
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 4,
                                          children: [
                                            if (p.category.isNotEmpty)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.4)),
                                                ),
                                                child: Text(
                                                  '🏷️ ${p.category}',
                                                  style: const TextStyle(color: Color(0xFFA5B4FC), fontSize: 11, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            if (p.localName.isNotEmpty)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withValues(alpha: 0.08),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: Colors.white24),
                                                ),
                                                child: Text(
                                                  p.localName,
                                                  style: const TextStyle(color: Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            if (p.barcode.isNotEmpty)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.tealAccent.withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.3)),
                                                ),
                                                child: Text(
                                                  '📊 Barcode: ${p.barcode}',
                                                  style: const TextStyle(color: Colors.tealAccent, fontSize: 11, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            if (p.qrCode.isNotEmpty)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.amberAccent.withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.3)),
                                                ),
                                                child: Text(
                                                  '📱 QR: ${p.qrCode}',
                                                  style: const TextStyle(color: Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                          ],
                                        ),
                                        if (p.description.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.04),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Colors.white12),
                                            ),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Icon(Icons.description_outlined, size: 14, color: Colors.tealAccent),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    p.description,
                                                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(color: Colors.white10, height: 20),
                              Row(
                                children: [
                                  // Price info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              '${provider.defaultCurrency}${p.effectivePrice.toStringAsFixed(0)}',
                                              style: const TextStyle(color: Colors.tealAccent, fontSize: 18, fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              '/ ${p.quantity.toStringAsFixed(p.quantity == p.quantity.roundToDouble() ? 0 : 1)} ${p.unit}',
                                              style: const TextStyle(color: Colors.white54, fontSize: 12),
                                            ),
                                            if (p.oldPrice > 0) ...[
                                              const SizedBox(width: 8),
                                              Text(
                                                '${provider.defaultCurrency}${p.oldPrice.toStringAsFixed(0)}',
                                                style: const TextStyle(color: Colors.white38, fontSize: 12, decoration: TextDecoration.lineThrough),
                                              ),
                                            ],
                                          ],
                                        ),
                                        if (hasPriceDrop)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4.0),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.arrow_downward, size: 12, color: Colors.greenAccent),
                                                const SizedBox(width: 2),
                                                Text(
                                                  'Price dropped by ${provider.defaultCurrency}${(p.oldPrice - p.currentPrice).toStringAsFixed(0)}',
                                                  style: const TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                          )
                                        else if (hasPriceIncrease)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4.0),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.arrow_upward, size: 12, color: Colors.redAccent),
                                                const SizedBox(width: 2),
                                                Text(
                                                  'Increased by ${provider.defaultCurrency}${(p.currentPrice - p.oldPrice).toStringAsFixed(0)}',
                                                  style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),

                                  // App / Store Name Badge
                                  if (p.appName.isNotEmpty)
                                    ActionChip(
                                      avatar: const Icon(Icons.shopping_bag_outlined, size: 14, color: Colors.black),
                                      label: Text('Lowest on ${p.appName}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black)),
                                      backgroundColor: Colors.tealAccent,
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () async {
                                        if (p.referenceLink.isNotEmpty) {
                                          final uri = Uri.tryParse(p.referenceLink);
                                          if (uri != null && await canLaunchUrl(uri)) {
                                            await launchUrl(uri);
                                          }
                                        }
                                      },
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  if (p.priceDate.isNotEmpty)
                                    Text(
                                      'Updated: ${p.priceDate}',
                                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                                    )
                                  else
                                    const SizedBox.shrink(),
                                  Row(
                                    children: [
                                      // Sync Best Price Button for this specific product
                                      ActionChip(
                                        avatar: _syncingProductIds.contains(p.id)
                                            ? const SizedBox(
                                                width: 12,
                                                height: 12,
                                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amberAccent),
                                              )
                                            : const Icon(Icons.bolt, size: 14, color: Colors.amberAccent),
                                        label: const Text('Sync Price ⚡', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amberAccent)),
                                        backgroundColor: Colors.amberAccent.withValues(alpha: 0.15),
                                        onPressed: p.id == null || _syncingProductIds.contains(p.id)
                                            ? null
                                            : () async {
                                                setState(() => _syncingProductIds.add(p.id!));
                                                final ok = await provider.syncProductBestPrice(p);
                                                if (mounted) {
                                                  setState(() => _syncingProductIds.remove(p.id!));
                                                  if (ok) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text('⚡ Lowest price updated for ${p.productName}!'),
                                                        backgroundColor: Colors.teal,
                                                      ),
                                                    );
                                                  }
                                                }
                                              },
                                      ),
                                      const SizedBox(width: 4),
                                      if (p.referenceLink.isNotEmpty)
                                        IconButton(
                                          icon: const Icon(Icons.open_in_new, size: 18, color: Colors.cyanAccent),
                                          tooltip: 'Open Reference Link',
                                          onPressed: () async {
                                            final uri = Uri.tryParse(p.referenceLink);
                                            if (uri != null && await canLaunchUrl(uri)) {
                                              await launchUrl(uri);
                                            }
                                          },
                                        ),
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 18, color: Colors.white70),
                                        onPressed: () => _showAddEditProductSheet(context, provider, product: p),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, size: 18, color: Colors.redAccent),
                                        onPressed: () {
                                          if (p.id != null) {
                                            provider.deleteProduct(p.id!);
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _scanCodeDialog(BuildContext context, String title) async {
    MobileScannerController controller = MobileScannerController();
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF16192E),
          title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 300,
            height: 250,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: MobileScanner(
                controller: controller,
                onDetect: (capture) {
                  final barcode = capture.barcodes.firstOrNull;
                  if (barcode?.rawValue != null) {
                    controller.dispose();
                    Navigator.pop(ctx, barcode!.rawValue!);
                  }
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
              onPressed: () {
                controller.dispose();
                Navigator.pop(ctx, null);
              },
            ),
          ],
        );
      },
    );
  }

  void _showAddEditProductSheet(BuildContext context, FinanceProvider provider, {Product? product}) {
    final isEdit = product != null;
    final nameCtrl = TextEditingController(text: product?.productName ?? '');
    final localNameCtrl = TextEditingController(text: product?.localName ?? '');
    final refLinkCtrl = TextEditingController(text: product?.referenceLink ?? '');
    final appNameCtrl = TextEditingController(text: product?.appName ?? '');
    final currentPriceCtrl = TextEditingController(text: product != null && product.currentPrice > 0 ? product.currentPrice.toStringAsFixed(0) : '');
    final oldPriceCtrl = TextEditingController(text: product != null && product.oldPrice > 0 ? product.oldPrice.toStringAsFixed(0) : '');
    final quantityCtrl = TextEditingController(text: product != null ? product.quantity.toStringAsFixed(0) : '1');
    final barcodeCtrl = TextEditingController(text: product?.barcode ?? '');
    final qrCodeCtrl = TextEditingController(text: product?.qrCode ?? '');
    final imageUrlCtrl = TextEditingController(text: product?.imageUrl ?? '');
    final descriptionCtrl = TextEditingController(text: product?.description ?? '');
    String selectedUnit = product?.unit ?? 'Pcs';
    String selectedCategory = product?.category ?? 'General';
    String priceDate = product?.priceDate ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
    bool isActive = product?.active ?? true;

    final formKey = GlobalKey<FormState>();

    final units = ['Pcs', 'Kg', 'Gram', 'Ltr', 'Ml', 'Pack', 'Box', 'Dozen', 'Bottle', 'Meter'];

    final categoryOptionsSet = <String>{
      'General',
      'Groceries',
      'Vegetables & Fruits',
      'Dairy & Bakery',
      'Electronics',
      'Household',
      'Personal Care',
      'Snacks & Drinks',
      'Medicines',
      ...provider.categories.map((c) => c.name),
    };
    final categoriesList = categoryOptionsSet.toList()..sort();

    if (!categoriesList.contains(selectedCategory)) {
      categoriesList.insert(0, selectedCategory);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121422),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 24,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isEdit ? 'Edit Catalog Product' : 'Add New Catalog Product',
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white54),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: nameCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Product Name (English) *',
                          hintText: 'e.g. Organic Basmati Rice',
                          prefixIcon: Icon(Icons.shopping_bag_outlined, color: Colors.tealAccent),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        onChanged: (val) async {
                          if (val.trim().isNotEmpty) {
                            final fastTranslated = HinglishTranslator.translateToHinglish(val);
                            setModalState(() {
                              localNameCtrl.text = fastTranslated;
                            });
                            final dynamicTranslated = await HinglishTranslator.translateDynamic(val);
                            if (mounted) {
                              setModalState(() {
                                localNameCtrl.text = dynamicTranslated;
                              });
                            }
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: localNameCtrl,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Local Name',
                                hintText: 'e.g. आलू (Aloo)',
                                prefixIcon: const Icon(Icons.translate, color: Colors.amberAccent),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 20),
                                  tooltip: 'Auto Dynamic Translation',
                                  onPressed: () async {
                                    final dynamicTranslated = await HinglishTranslator.translateDynamic(nameCtrl.text);
                                    setModalState(() {
                                      localNameCtrl.text = dynamicTranslated;
                                    });
                                  },
                                ),
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedCategory,
                              dropdownColor: const Color(0xFF1E2238),
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: 'Category (Picklist)',
                                prefixIcon: Icon(Icons.category_outlined, color: Color(0xFF6366F1)),
                                border: OutlineInputBorder(),
                              ),
                              items: categoriesList.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setModalState(() {
                                    selectedCategory = val;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: currentPriceCtrl,
                              style: const TextStyle(color: Colors.white),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: 'Current Price (${provider.defaultCurrency})',
                                hintText: '0',
                                prefixIcon: const Icon(Icons.currency_rupee, color: Colors.tealAccent),
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: oldPriceCtrl,
                              style: const TextStyle(color: Colors.white),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: 'Old Price (${provider.defaultCurrency})',
                                hintText: '0',
                                prefixIcon: const Icon(Icons.history, color: Colors.white54),
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: quantityCtrl,
                              style: const TextStyle(color: Colors.white),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Quantity',
                                hintText: '1',
                                prefixIcon: Icon(Icons.scale, color: Colors.cyanAccent),
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) {
                                if (v != null && v.isNotEmpty && double.tryParse(v) == null) {
                                  return 'Invalid';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedUnit,
                              dropdownColor: const Color(0xFF1E2238),
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: 'Unit',
                                border: OutlineInputBorder(),
                              ),
                              items: units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setModalState(() {
                                    selectedUnit = val;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: appNameCtrl,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: 'App / Store Name',
                                hintText: 'e.g. Blinkit, Zepto, Amazon',
                                prefixIcon: Icon(Icons.storefront, color: Colors.tealAccent),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.tryParse(priceDate) ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                );
                                if (picked != null) {
                                  setModalState(() {
                                    priceDate = DateFormat('yyyy-MM-dd').format(picked);
                                  });
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Price Date',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.calendar_today, color: Colors.white54, size: 18),
                                ),
                                child: Text(priceDate, style: const TextStyle(color: Colors.white, fontSize: 13)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: barcodeCtrl,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Barcode / EAN Code',
                                hintText: 'e.g. 8901030784910',
                                prefixIcon: const Icon(Icons.qr_code_2, color: Colors.tealAccent),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.camera_alt, color: Colors.tealAccent, size: 20),
                                  tooltip: 'Scan Barcode',
                                  onPressed: () async {
                                    final code = await _scanCodeDialog(context, 'Scan Barcode');
                                    if (code != null) {
                                      setModalState(() {
                                        barcodeCtrl.text = code;
                                      });
                                    }
                                  },
                                ),
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: qrCodeCtrl,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'QR Code Data',
                                hintText: 'e.g. QR text',
                                prefixIcon: const Icon(Icons.qr_code_scanner, color: Colors.amberAccent),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.camera_alt, color: Colors.amberAccent, size: 20),
                                  tooltip: 'Scan QR Code',
                                  onPressed: () async {
                                    final code = await _scanCodeDialog(context, 'Scan QR Code');
                                    if (code != null) {
                                      setModalState(() {
                                        qrCodeCtrl.text = code;
                                      });
                                    }
                                  },
                                ),
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: imageUrlCtrl,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: 'Product Image (URL / Path)',
                                hintText: 'https://... or photo',
                                prefixIcon: Icon(Icons.image, color: Colors.cyanAccent),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.tealAccent,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            ),
                            icon: const Icon(Icons.photo_camera, size: 16),
                            label: const Text('Photo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            onPressed: () async {
                              final picker = ImagePicker();
                              final XFile? img = await picker.pickImage(source: ImageSource.camera, maxWidth: 800, maxHeight: 800, imageQuality: 80);
                              if (img != null) {
                                setModalState(() {
                                  imageUrlCtrl.text = img.path;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: descriptionCtrl,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Product Description (Description)',
                          hintText: 'e.g. Detailed product description, ingredients, or specifications...',
                          prefixIcon: Icon(Icons.description, color: Colors.tealAccent),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: refLinkCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Reference Link / URL (Optional)',
                          hintText: 'https://...',
                          prefixIcon: Icon(Icons.link, color: Colors.cyanAccent),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Product Active Status', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          Switch(
                            value: isActive,
                            activeColor: Colors.tealAccent,
                            onChanged: (val) {
                              setModalState(() {
                                isActive = val;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.tealAccent,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
                            final cPrice = double.tryParse(currentPriceCtrl.text.trim()) ?? 0.0;
                            final oPrice = double.tryParse(oldPriceCtrl.text.trim()) ?? 0.0;
                            final qty = double.tryParse(quantityCtrl.text.trim()) ?? 1.0;

                            final newP = Product(
                              id: product?.id,
                              productName: nameCtrl.text.trim(),
                              localName: localNameCtrl.text.trim(),
                              category: selectedCategory,
                              referenceLink: refLinkCtrl.text.trim(),
                              appName: appNameCtrl.text.trim(),
                              priceDate: priceDate,
                              currentPrice: cPrice,
                              oldPrice: oPrice,
                              unit: selectedUnit,
                              quantity: qty,
                              barcode: barcodeCtrl.text.trim(),
                              qrCode: qrCodeCtrl.text.trim(),
                              imageUrl: imageUrlCtrl.text.trim(),
                              description: descriptionCtrl.text.trim(),
                              active: isActive,
                            );

                            if (isEdit) {
                              await provider.updateProduct(newP);
                            } else {
                              await provider.addProduct(newP);
                            }

                            if (context.mounted) {
                              Navigator.pop(ctx);
                              setState(() {
                                _searchQuery = '';
                                _searchController.clear();
                                _selectedCategory = 'All';
                              });
                            }
                          },
                          child: Text(
                            isEdit ? 'Update Product' : 'Add to Catalog',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
