import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../providers/finance_provider.dart';

class GlobalSearchModal extends StatefulWidget {
  const GlobalSearchModal({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (ctx) => const GlobalSearchModal(),
    );
  }

  @override
  State<GlobalSearchModal> createState() => _GlobalSearchModalState();
}

class _GlobalSearchModalState extends State<GlobalSearchModal> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredTransactions = _query.isEmpty
        ? []
        : provider.allTransactions
            .where((t) =>
                t.itemService.toLowerCase().contains(_query.toLowerCase()) ||
                t.merchantName.toLowerCase().contains(_query.toLowerCase()))
            .take(5)
            .toList();

    final filteredContacts = _query.isEmpty
        ? []
        : provider.contacts
            .where((c) =>
                c.name.toLowerCase().contains(_query.toLowerCase()) ||
                (c.mobile != null && c.mobile!.contains(_query)))
            .take(5)
            .toList();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 640),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Search Input Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.search, color: AppColors.primary, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      onChanged: (val) => setState(() => _query = val),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      decoration: const InputDecoration(
                        hintText: 'Search transactions, contacts, loans, products...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.black12,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'ESC',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Search Results List
            Container(
              constraints: const BoxConstraints(maxHeight: 380),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_query.isEmpty) ...[
                      const Text(
                        'QUICK SHORTCUTS',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.darkTextMuted),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildShortcutChip(Icons.add, 'New Expense'),
                          _buildShortcutChip(Icons.arrow_downward, 'New Income'),
                          _buildShortcutChip(Icons.person_add, 'Add Contact'),
                          _buildShortcutChip(Icons.account_balance, 'Add Loan'),
                        ],
                      ),
                    ] else ...[
                      if (filteredTransactions.isNotEmpty) ...[
                        const Text(
                          'TRANSACTIONS',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.darkTextMuted),
                        ),
                        const SizedBox(height: 8),
                        ...filteredTransactions.map((t) => ListTile(
                              dense: true,
                              leading: const Icon(Icons.receipt_long, color: AppColors.primary, size: 20),
                              title: Text(t.itemService, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(t.date),
                              trailing: Text(
                                '${provider.defaultCurrency}${t.cost.toStringAsFixed(0)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.rose),
                              ),
                            )),
                        const SizedBox(height: 12),
                      ],
                      if (filteredContacts.isNotEmpty) ...[
                        const Text(
                          'CONTACTS',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.darkTextMuted),
                        ),
                        const SizedBox(height: 8),
                        ...filteredContacts.map((c) => ListTile(
                              dense: true,
                              leading: const Icon(Icons.person, color: AppColors.secondary, size: 20),
                              title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(c.mobile ?? 'No phone'),
                            )),
                      ],
                      if (filteredTransactions.isEmpty && filteredContacts.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Center(
                            child: Text(
                              'No matching records found',
                              style: TextStyle(color: AppColors.darkTextMuted),
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShortcutChip(IconData icon, String label) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: AppColors.primary),
      label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      onPressed: () => Navigator.pop(context),
    );
  }
}
