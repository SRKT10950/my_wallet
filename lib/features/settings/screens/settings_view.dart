import 'package:flutter/material.dart';
import '../../../core/models/base_model.dart';
import '../../../core/theme/app_theme.dart';

import '../models/category_model.dart';
import '../services/category_service.dart';
import '../services/settings_service.dart';

/// System Setting View — Manage Category, Configure Currency, Set Default Income, Local Language.
class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final _settingsService = SettingsService.instance;
  final _categoryService = CategoryService.instance;

  CurrencyOption _selectedCurrency = SettingsService.availableCurrencies.first;
  LanguageOption _selectedLanguage = SettingsService.availableLanguages.first;
  double _defaultIncome = 85000.0;

  bool _darkMode = true;
  bool _biometrics = true;
  bool _notifications = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final curr = await _settingsService.getCurrency();
    final lang = await _settingsService.getLanguage();
    final income = await _settingsService.getDefaultIncome();

    if (!mounted) return;
    setState(() {
      _selectedCurrency = curr;
      _selectedLanguage = lang;
      _defaultIncome = income;
      _isLoading = false;
    });
  }

  // ── 1. Manage Categories Modal ──────────────────────────────────────
  void _openManageCategoriesModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return FutureBuilder<List<CategoryModel>>(
              future: _categoryService.fetchCategories(),
              builder: (context, snapshot) {
                final categories = snapshot.data ?? [];
                final incomeCats = categories.where((c) => c.isIncome).toList();
                final expenseCats = categories.where((c) => c.isExpense).toList();

                return Container(
                  height: MediaQuery.of(context).size.height * 0.75,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Manage Categories',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: AppTheme.textHint),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Expanded(
                        child: DefaultTabController(
                          length: 2,
                          child: Column(
                            children: [
                              TabBar(
                                indicatorColor: AppTheme.primaryTeal,
                                labelColor: AppTheme.primaryTeal,
                                unselectedLabelColor: AppTheme.textSecondary,
                                tabs: const [
                                  Tab(text: 'Expense Categories'),
                                  Tab(text: 'Income Categories'),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: TabBarView(
                                  children: [
                                    _buildCategoryList(expenseCats, setModalState),
                                    _buildCategoryList(incomeCats, setModalState),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _showAddCategoryDialog(setModalState),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Add New Category'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCategoryList(List<CategoryModel> list, StateSetter setModalState) {
    if (list.isEmpty) {
      return const Center(
        child: Text('No categories found', style: TextStyle(color: AppTheme.textHint)),
      );
    }

    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (ctx, i) {
        final cat = list[i];
        final color = _parseColorHex(cat.colorHex);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(14),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.2),
              child: Icon(_parseIconData(cat.iconName), color: color, size: 20),
            ),
            title: Text(cat.categoryName, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
            subtitle: Text(cat.categoryType.toUpperCase(), style: const TextStyle(color: AppTheme.textHint, fontSize: 11)),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 20),
              onPressed: () async {
                await _categoryService.deleteCategory(cat.id);
                setModalState(() {});
              },
            ),
          ),
        );
      },
    );
  }

  void _showAddCategoryDialog(StateSetter setModalState) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    String catType = 'expense';

    showDialog(
      context: context,
      builder: (dlgCtx) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return AlertDialog(
              backgroundColor: AppTheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Create New Category', style: TextStyle(color: AppTheme.textPrimary)),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Category Name *',
                        hintText: 'e.g. Subscriptions',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Name is required';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Expense')),
                            selected: catType == 'expense',
                            selectedColor: AppTheme.error.withValues(alpha: 0.3),
                            onSelected: (_) => setDlgState(() => catType = 'expense'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Income')),
                            selected: catType == 'income',
                            selectedColor: AppTheme.success.withValues(alpha: 0.3),
                            onSelected: (_) => setDlgState(() => catType = 'income'),
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
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final newCat = CategoryModel(
                      id: BaseModel.newId(),
                      createdAt: DateTime.now().toUtc().toIso8601String(),
                      updatedAt: DateTime.now().toUtc().toIso8601String(),
                      categoryName: nameCtrl.text.trim(),
                      categoryType: catType,
                      iconName: catType == 'income' ? 'account_balance' : 'receipt',
                      colorHex: catType == 'income' ? '#4CAF50' : '#6C3DE8',
                    );

                    Navigator.pop(dlgCtx);
                    await _categoryService.addCategory(newCat);
                    setModalState(() {});
                  },
                  child: const Text('Add Category'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ── 2. Configure Currency Picker ───────────────────────────────────
  void _openCurrencyPickerModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Configure Currency',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              ...SettingsService.availableCurrencies.map((curr) {
                final isSelected = _selectedCurrency.code == curr.code;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryViolet.withValues(alpha: 0.15) : AppTheme.card,
                    borderRadius: BorderRadius.circular(14),
                    border: isSelected ? Border.all(color: AppTheme.primaryTeal) : null,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryTeal.withValues(alpha: 0.2),
                      child: Text(curr.symbol, style: const TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.w700)),
                    ),
                    title: Text(curr.name, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                    trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppTheme.primaryTeal) : null,
                    onTap: () async {
                      await _settingsService.setCurrency(curr);
                      if (!mounted) return;
                      setState(() => _selectedCurrency = curr);
                      if (!ctx.mounted) return;
                      Navigator.of(ctx).pop();
                    },
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // ── 3. Set Default Income Dialog ───────────────────────────────────
  void _openDefaultIncomeDialog() {
    final incomeCtrl = TextEditingController(text: _defaultIncome.toStringAsFixed(0));
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Set Default Monthly Income', style: TextStyle(color: AppTheme.textPrimary)),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: incomeCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                labelText: 'Default Monthly Income (${_selectedCurrency.symbol})',
                hintText: 'e.g. 85000',
                prefixText: '${_selectedCurrency.symbol} ',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Income is required';
                if (double.tryParse(v.trim()) == null) return 'Enter a valid number';
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textHint)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final val = double.parse(incomeCtrl.text.trim());
                await _settingsService.setDefaultIncome(val);
                if (!mounted) return;
                setState(() => _defaultIncome = val);
                if (!ctx.mounted) return;
                Navigator.of(ctx).pop();
              },
              child: const Text('Save Income'),
            ),
          ],
        );
      },
    );
  }

  // ── 4. Local Language Selector ──────────────────────────────────────
  void _openLanguagePickerModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Display Language',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              ...SettingsService.availableLanguages.map((lang) {
                final isSelected = _selectedLanguage.code == lang.code;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryViolet.withValues(alpha: 0.15) : AppTheme.card,
                    borderRadius: BorderRadius.circular(14),
                    border: isSelected ? Border.all(color: AppTheme.primaryTeal) : null,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryViolet.withValues(alpha: 0.2),
                      child: Text(lang.code.toUpperCase(), style: const TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.w700, fontSize: 12)),
                    ),
                    title: Text(lang.name, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                    subtitle: Text(lang.nativeName, style: const TextStyle(color: AppTheme.textHint, fontSize: 12)),
                    trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppTheme.primaryTeal) : null,
                    onTap: () async {
                      await _settingsService.setLanguage(lang);
                      if (!mounted) return;
                      setState(() => _selectedLanguage = lang);
                      if (!ctx.mounted) return;
                      Navigator.of(ctx).pop();
                    },
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // Helper parsers
  Color _parseColorHex(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return AppTheme.primaryViolet;
    }
  }

  IconData _parseIconData(String name) {
    switch (name) {
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'receipt':
        return Icons.receipt_long_rounded;
      case 'shopping_bag':
        return Icons.shopping_bag_rounded;
      case 'directions_car':
        return Icons.directions_car_rounded;
      case 'account_balance':
        return Icons.account_balance_rounded;
      case 'work':
        return Icons.work_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryTeal));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppTheme.primaryViolet,
                  child: const Icon(Icons.person_rounded, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('My Wallet User', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
                      SizedBox(height: 2),
                      Text('+91 74007 00500', style: TextStyle(color: AppTheme.textHint, fontSize: 13)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppTheme.success.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                  child: const Text('PRO', style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.w800, fontSize: 12)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const Text('Configuration & Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 14),

          // 1. Manage Categories
          _buildActionTile(
            icon: Icons.category_rounded,
            title: 'Manage Categories',
            subtitle: 'Configure Income & Expense categories',
            trailingText: 'Manage',
            onTap: _openManageCategoriesModal,
          ),

          // 2. Configure Currency
          _buildActionTile(
            icon: Icons.currency_exchange_rounded,
            title: 'Configure Currency',
            subtitle: _selectedCurrency.name,
            trailingText: '${_selectedCurrency.symbol} (${_selectedCurrency.code})',
            onTap: _openCurrencyPickerModal,
          ),

          // 3. Set Default Income
          _buildActionTile(
            icon: Icons.account_balance_wallet_rounded,
            title: 'Set Default Income',
            subtitle: 'Base monthly income target',
            trailingText: '${_selectedCurrency.symbol} ${_defaultIncome.toStringAsFixed(0)}',
            onTap: _openDefaultIncomeDialog,
          ),

          // 4. Local Language
          _buildActionTile(
            icon: Icons.language_rounded,
            title: 'Local Language',
            subtitle: 'App display language',
            trailingText: '${_selectedLanguage.name} (${_selectedLanguage.nativeName})',
            onTap: _openLanguagePickerModal,
          ),

          const SizedBox(height: 24),

          const Text('App Security & System', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 14),

          _buildSwitchTile('Dark Mode Theme', 'Always use dark glassmorphism palette', _darkMode, (v) => setState(() => _darkMode = v)),
          _buildSwitchTile('Biometric / PIN Lock', 'Require PIN on app unlock', _biometrics, (v) => setState(() => _biometrics = v)),
          _buildSwitchTile('Push Notifications', 'Receive due date alerts & updates', _notifications, (v) => setState(() => _notifications = v)),

          const SizedBox(height: 20),

          // Cloud Sync Status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: const [
                Icon(Icons.cloud_done_rounded, color: AppTheme.primaryTeal, size: 22),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Cloud DB Sync', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                      Text('Connected • Last synced just now', style: TextStyle(color: AppTheme.textHint, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String trailingText,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppTheme.primaryViolet.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: AppTheme.primaryTeal, size: 20),
        ),
        title: Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppTheme.textHint, fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(trailingText, style: const TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.textHint, size: 14),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16)),
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppTheme.textHint, fontSize: 12)),
        value: value,
        activeTrackColor: AppTheme.primaryViolet,
        activeThumbColor: AppTheme.primaryTeal,
        onChanged: onChanged,
      ),
    );
  }
}
