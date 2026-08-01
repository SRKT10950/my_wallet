import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../providers/finance_provider.dart';
import '../models/income_config.dart';
import 'category_manager_screen.dart';
import '../services/pwa_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showSetIncomeModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const SetIncomeSheet(),
    );
  }

  void _showExportDialog(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context, listen: false);
    final csv = provider.exportTransactionsToCsv();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF121422),
        title: const Text('Exported CSV Data', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Copy the transaction logs below in CSV format for Excel/Google Sheets:',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Container(
              height: 200,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  csv,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.tealAccent),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: csv));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('CSV Copied to Clipboard!'), backgroundColor: Colors.teal),
              );
              Navigator.pop(ctx);
            },
            child: const Text('Copy to Clipboard', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.tealAccent)),
          ),
        ],
      ),
    );
  }

  void _showImportDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF121422),
        title: const Text('Import CSV Data', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Paste your transaction logs in CSV format (Header format: ID,Date,Category,Type,Item/Service,Cost,Paid Amount,Cleared,Account,To Account,Tags,Note):',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace'),
              maxLines: 8,
              decoration: InputDecoration(
                hintText: 'Paste CSV text here...',
                hintStyle: const TextStyle(color: Colors.white30),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                final provider = Provider.of<FinanceProvider>(context, listen: false);
                await provider.importTransactionsFromCsv(controller.text);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Import completed successfully!'), backgroundColor: Colors.green),
                  );
                  Navigator.pop(ctx);
                }
              }
            },
            child: const Text('Import Data', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.greenAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF080914), Color(0xFF0E111F)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              color: const Color(0xFF121422),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: const Icon(Icons.category, color: Colors.tealAccent, size: 30),
                title: const Text('Manage Categories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                subtitle: Text('${provider.categories.length} Categories Configured', style: const TextStyle(color: Colors.white54)),
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CategoryManagerScreen()),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: Text('Localization & Currency', style: TextStyle(fontSize: 14, color: Colors.white54, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
            ),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              color: const Color(0xFF121422),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.monetization_on_outlined, color: Colors.cyanAccent, size: 28),
                        SizedBox(width: 16),
                        Text('App Currency', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                    DropdownButton<String>(
                      value: provider.defaultCurrency,
                      dropdownColor: const Color(0xFF121422),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      underline: Container(),
                      items: ['₹', '\$', '€', '£', '¥'].map((c) {
                        return DropdownMenuItem<String>(
                          value: c,
                          child: Text(c, style: const TextStyle(fontSize: 18)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          provider.setDefaultCurrency(val);
                        }
                      },
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: Text('Income Configuration', style: TextStyle(fontSize: 14, color: Colors.white54, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
            ),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              color: const Color(0xFF121422),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: const Icon(Icons.account_balance_wallet, color: Colors.deepPurpleAccent, size: 30),
                    title: const Text('Set Default Income', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.deepPurpleAccent),
                      onPressed: () => _showSetIncomeModal(context),
                    ),
                  ),
                  const Divider(height: 1, color: Colors.white10),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    title: const Text('Current Default Income', style: TextStyle(color: Colors.white70)),
                    trailing: Text(
                      '${provider.defaultCurrency}${provider.getMonthlyIncome(DateTime.now().month, DateTime.now().year).toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: Text('Data Backup & Recovery', style: TextStyle(fontSize: 14, color: Colors.white54, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
            ),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              color: const Color(0xFF121422),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: const Icon(Icons.file_upload_outlined, color: Colors.tealAccent, size: 28),
                    title: const Text('Export Transactions (CSV)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    subtitle: const Text('View and copy spreadsheet compatible data', style: TextStyle(color: Colors.white30, fontSize: 11)),
                    trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                    onTap: () => _showExportDialog(context),
                  ),
                  const Divider(height: 1, color: Colors.white10),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: const Icon(Icons.file_download_outlined, color: Colors.greenAccent, size: 28),
                    title: const Text('Import Transactions (CSV)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    subtitle: const Text('Paste transaction records to recover data', style: TextStyle(color: Colors.white30, fontSize: 11)),
                    trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                    onTap: () => _showImportDialog(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: Text('PWA App Updates & Offline Sync', style: TextStyle(fontSize: 14, color: Colors.white54, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
            ),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              color: const Color(0xFF121422),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: const Icon(Icons.system_update_sharp, color: Colors.cyanAccent, size: 28),
                    title: const Text('Check for App Updates', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    subtitle: const Text('Instantly fetch latest releases without deleting/reinstalling app', style: TextStyle(color: Colors.white30, fontSize: 11)),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyanAccent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      onPressed: () async {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Checking for latest updates...'), backgroundColor: Colors.cyan),
                        );
                        await PwaService().checkForUpdates();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('App is synced! Force purging cache & reloading...'),
                              backgroundColor: Colors.teal,
                            ),
                          );
                        }
                        PwaService().forcePurgeAndReload();
                      },
                      child: const Text('UPDATE NOW', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const Divider(height: 1, color: Colors.white10),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: const Icon(Icons.notifications_active_outlined, color: Colors.amberAccent, size: 28),
                    title: const Text('Web Push Notifications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    subtitle: const Text('Test iOS / Android / Desktop push alerts', style: TextStyle(color: Colors.white30, fontSize: 11)),
                    trailing: TextButton(
                      onPressed: () async {
                        final success = await PwaService().sendTestNotification();
                        if (context.mounted) {
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Test notification dispatched! Check system tray.'), backgroundColor: Colors.green),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Requesting notification permission...'), backgroundColor: Colors.amber),
                            );
                            await PwaService().requestNotificationPermission();
                          }
                        }
                      },
                      child: const Text('TEST PUSH', style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                  const Divider(height: 1, color: Colors.white10),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: const Icon(Icons.touch_app_outlined, color: Colors.pinkAccent, size: 28),
                    title: const Text('App Version & Platform', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    subtitle: Text(
                      PwaService().isStandalone() ? 'v1.0.1+2 • Standalone Native PWA Mode' : 'v1.0.1+2 • Web Browser Mode',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class SetIncomeSheet extends StatefulWidget {
  const SetIncomeSheet({super.key});

  @override
  State<SetIncomeSheet> createState() => _SetIncomeSheetState();
}

class _SetIncomeSheetState extends State<SetIncomeSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<FinanceProvider>(context, listen: false);
      provider.addOrUpdateIncomeConfig(IncomeConfig(
        month: DateTime.now().month,
        year: DateTime.now().year,
        amount: double.parse(_amountController.text),
        isDefault: true,
      ));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Set Default Income', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 20),
            TextFormField(
              controller: _amountController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Monthly Income',
                labelStyle: const TextStyle(color: Colors.grey),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.payments_outlined, color: Colors.deepPurpleAccent),
                prefixText: provider.defaultCurrency,
                prefixStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                final amt = double.tryParse(v);
                if (amt == null) return 'Must be a valid number';
                if (amt < 0) return 'Cannot be negative';
                return null;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.deepPurpleAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _submit,
                child: const Text('Save Income', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
