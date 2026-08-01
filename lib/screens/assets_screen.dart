import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../models/asset.dart';
import 'dart:math';

class AssetsScreen extends StatefulWidget {
  const AssetsScreen({super.key});

  @override
  State<AssetsScreen> createState() => _AssetsScreenState();
}

class _AssetsScreenState extends State<AssetsScreen> {
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshRates(silent: true);
    });
  }

  Future<void> _refreshRates({bool silent = false}) async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    
    final provider = Provider.of<FinanceProvider>(context, listen: false);
    try {
      await provider.updateAssetPrices();
      if (mounted && !silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Asset market rates updated!'), backgroundColor: Colors.teal),
        );
      }
    } catch (e) {
      if (mounted && !silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rate update failed: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  void _showAssetModal(BuildContext context, {Asset? asset}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AssetSheet(asset: asset),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);
    final curSymbol = provider.defaultCurrency;
    final assets = provider.assets;
    final totalVal = provider.totalPortfolioValue;
    final totalInv = provider.totalPortfolioInvested;
    final totalGain = totalVal - totalInv;
    final gainPercent = totalInv > 0 ? (totalGain / totalInv) * 100 : 0.0;
    final gainColor = totalGain >= 0 ? Colors.greenAccent : Colors.redAccent;

    // Group assets by category
    final Map<String, List<Asset>> grouped = {};
    final Map<String, double> categoryAllocation = {};
    for (var a in assets) {
      grouped.putIfAbsent(a.category, () => []).add(a);
      categoryAllocation[a.category] = (categoryAllocation[a.category] ?? 0.0) + a.totalCurrentValue;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asset Portfolio'),
        actions: [
          IconButton(
            icon: _isRefreshing 
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.cyanAccent, strokeWidth: 2))
                : const Icon(Icons.refresh, color: Colors.cyanAccent),
            tooltip: 'Refresh live rates',
            onPressed: () => _refreshRates(),
          ),
        ],
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
            // Portfolio Wealth Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF121422),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'PORTFOLIO VALUE',
                    style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$curSymbol${totalVal.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 32, color: Colors.white, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('INVESTED VALUE', style: TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('$curSymbol${totalInv.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('UNREALIZED GAINS', style: TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                            '${totalGain >= 0 ? '+' : ''}$curSymbol${totalGain.toStringAsFixed(0)} (${gainPercent.toStringAsFixed(2)}%)',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: gainColor),
                          ),
                        ],
                      ),
                    ],
                  )
                ],
              ),
            ),

            // Allocation Donut Chart
            if (assets.isNotEmpty) ...[
              AssetAllocationChart(categoryValues: categoryAllocation),
              const SizedBox(height: 8),
            ],
            
            // Asset Category Headers / List
            Expanded(
              child: assets.isEmpty
                  ? const Center(child: Text('No assets added yet. Build your portfolio!', style: TextStyle(color: Colors.white54)))
                  : RefreshIndicator(
                      color: Colors.cyanAccent,
                      backgroundColor: const Color(0xFF121422),
                      onRefresh: () => _refreshRates(),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          ...grouped.entries.map((entry) {
                            final catName = entry.key;
                            final catAssets = entry.value;
                            final catTotal = catAssets.fold(0.0, (sum, a) => sum + a.totalCurrentValue);
                            
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 16, bottom: 8, left: 4),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        catName.toUpperCase(),
                                        style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                                      ),
                                      Text(
                                        '$curSymbol${catTotal.toStringAsFixed(0)}',
                                        style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                                ...catAssets.map((asset) {
                                  final gain = asset.unrealizedGainLoss;
                                  final Color assetGainColor = gain >= 0 ? Colors.greenAccent : Colors.redAccent;
                                  
                                  // Generate deterministic weekly price walk for visual sparkline
                                  final List<double> priceHistory = [];
                                  final rand = Random(asset.symbol.hashCode + 2);
                                  double val = asset.currentPrice * 0.96;
                                  priceHistory.add(val);
                                  for (int i = 0; i < 5; i++) {
                                    val = val * (1.0 + (rand.nextDouble() * 0.04 - 0.018));
                                    priceHistory.add(val);
                                  }
                                  priceHistory.add(asset.currentPrice); // Ensure it ends at current CMP

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF121422),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                                    ),
                                    child: ListTile(
                                      onTap: () => _showAssetModal(context, asset: asset),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                      title: Row(
                                        children: [
                                          Text(asset.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(4)),
                                            child: Text(asset.symbol, style: const TextStyle(color: Colors.white54, fontSize: 8, fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ),
                                      subtitle: Padding(
                                        padding: const EdgeInsets.only(top: 4.0),
                                        child: Text(
                                          'Qty: ${asset.quantity} • Buy: $curSymbol${asset.buyPrice.toStringAsFixed(0)} • CMP: $curSymbol${asset.currentPrice.toStringAsFixed(1)}',
                                          style: const TextStyle(color: Colors.white30, fontSize: 10),
                                        ),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Sparkline Chart (Trend)
                                          SizedBox(
                                            width: 50,
                                            height: 25,
                                            child: CustomPaint(
                                              painter: SparklinePainter(
                                                data: priceHistory,
                                                color: assetGainColor,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                '$curSymbol${asset.totalCurrentValue.toStringAsFixed(1)}',
                                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.white),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '${gain >= 0 ? '+' : ''}$curSymbol${gain.toStringAsFixed(0)} (${asset.unrealizedGainLossPercentage.toStringAsFixed(1)}%)',
                                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: assetGainColor),
                                              )
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            );
                          }),
                          const SizedBox(height: 80), // spacer for FAB
                        ],
                      ),
                    ),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAssetModal(context),
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text('Add Asset', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.cyanAccent,
      ),
    );
  }
}

class AssetSheet extends StatefulWidget {
  final Asset? asset;
  const AssetSheet({super.key, this.asset});

  @override
  State<AssetSheet> createState() => _AssetSheetState();
}

class _AssetSheetState extends State<AssetSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _buyPriceController = TextEditingController();
  final _purchaseDateController = TextEditingController();
  final _symbolController = TextEditingController();
  String _selectedCategory = 'Stock';

  final List<String> _categories = ['Stock', 'MF', 'Precious Metals', 'Crypto', 'Real Estate', 'Other'];

  @override
  void initState() {
    super.initState();
    if (widget.asset != null) {
      _nameController.text = widget.asset!.name;
      _quantityController.text = widget.asset!.quantity.toString();
      _buyPriceController.text = widget.asset!.buyPrice.toString();
      _purchaseDateController.text = widget.asset!.dateAdded.substring(0, 10);
      _symbolController.text = widget.asset!.symbol;
      _selectedCategory = widget.asset!.category;
    } else {
      _purchaseDateController.text = DateTime.now().toIso8601String().substring(0, 10);
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<FinanceProvider>(context, listen: false);
      final double qty = double.parse(_quantityController.text);
      final double buy = double.parse(_buyPriceController.text);

      final asset = Asset(
        id: widget.asset?.id,
        name: _nameController.text,
        category: _selectedCategory,
        quantity: qty,
        buyPrice: buy,
        currentPrice: widget.asset?.currentPrice ?? buy,
        symbol: _symbolController.text.toUpperCase(),
        dateAdded: _purchaseDateController.text,
      );

      if (widget.asset == null) {
        provider.addAsset(asset);
      } else {
        provider.updateAsset(asset);
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);
    final isEdit = widget.asset != null;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF121422),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(top: BorderSide(color: Colors.white12, width: 1.5)),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEdit ? 'Edit Portfolio Asset' : 'Add New Wealth Asset',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                dropdownColor: const Color(0xFF121422),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Asset Category',
                  labelStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedCategory = val!;
                    // Autoconfigure standard symbols
                    if (_selectedCategory == 'Precious Metals' && _nameController.text.isEmpty) {
                      _nameController.text = 'Gold Asset';
                      _symbolController.text = 'GOLD';
                    } else if (_selectedCategory == 'Crypto' && _nameController.text.isEmpty) {
                      _nameController.text = 'Bitcoin';
                      _symbolController.text = 'BTC';
                    }
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Asset Name (e.g. HDFC Index Fund, Gold)',
                  labelStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                validator: (val) => val!.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _symbolController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Symbol (e.g. BTC)',
                        labelStyle: const TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      validator: (val) => val!.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Quantity (e.g. 15.5)',
                        labelStyle: const TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (double.tryParse(v) == null) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _buyPriceController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Buy Price / Unit (${provider.defaultCurrency})',
                        labelStyle: const TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (double.tryParse(v) == null) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _purchaseDateController,
                      style: const TextStyle(color: Colors.white),
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Purchase Date',
                        labelStyle: const TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        suffixIcon: const Icon(Icons.calendar_today, color: Colors.grey, size: 18),
                      ),
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: widget.asset != null
                              ? DateTime.tryParse(widget.asset!.dateAdded) ?? DateTime.now()
                              : DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: Color(0xFF6366F1),
                                  onPrimary: Colors.white,
                                  surface: Color(0xFF121422),
                                  onSurface: Colors.white,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setState(() {
                            _purchaseDateController.text = picked.toIso8601String().substring(0, 10);
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  if (isEdit) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: const Color(0xFF121422),
                              title: const Text('Remove Asset?'),
                              content: const Text('This will delete this asset from your wealth portfolio.', style: TextStyle(color: Colors.white70)),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                TextButton(
                                  onPressed: () {
                                    provider.deleteAsset(widget.asset!.id!);
                                    Navigator.pop(ctx);
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(Icons.delete),
                        label: const Text('Remove', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.cyanAccent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _submit,
                      child: Text(
                        isEdit ? 'Update Asset' : 'Save Asset',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AssetAllocationChart extends StatelessWidget {
  final Map<String, double> categoryValues;

  const AssetAllocationChart({super.key, required this.categoryValues});

  @override
  Widget build(BuildContext context) {
    final total = categoryValues.values.fold(0.0, (sum, val) => sum + val);
    if (total == 0) return const SizedBox();

    final categoryColors = {
      'Stock': const Color(0xFF6366F1),
      'MF': Colors.blueAccent,
      'Precious Metals': Colors.amberAccent,
      'Crypto': Colors.purpleAccent,
      'Real Estate': Colors.orangeAccent,
      'Other': Colors.tealAccent,
      'Stocks/MFs': const Color(0xFF6366F1),
    };

    // Filter out categories with zero value
    final activeCategories = categoryValues.entries.where((e) => e.value > 0).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121422),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          // Donut Chart
          SizedBox(
            width: 80,
            height: 80,
            child: CustomPaint(
              painter: DonutChartPainter(
                categoryValues: categoryValues,
                colors: categoryColors,
                total: total,
              ),
            ),
          ),
          const SizedBox(width: 20),
          // Legend
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: activeCategories.map((entry) {
                final color = categoryColors[entry.key] ?? Colors.grey;
                final percentage = (entry.value / total) * 100;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.key,
                          style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${percentage.toStringAsFixed(0)}%',
                        style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class DonutChartPainter extends CustomPainter {
  final Map<String, double> categoryValues;
  final Map<String, Color> colors;
  final double total;

  DonutChartPainter({
    required this.categoryValues,
    required this.colors,
    required this.total,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2);
    final strokeWidth = radius * 0.35;
    
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..isAntiAlias = true;

    double startAngle = -pi / 2;

    for (final entry in categoryValues.entries) {
      final value = entry.value;
      if (value == 0) continue;

      final sweepAngle = (value / total) * 2 * pi;
      paint.color = colors[entry.key] ?? Colors.grey;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;

  SparklinePainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final path = Path();
    final minVal = data.reduce(min);
    final maxVal = data.reduce(max);
    final range = maxVal - minVal == 0 ? 1.0 : maxVal - minVal;

    final stepX = size.width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = size.height - ((data[i] - minVal) / range) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
