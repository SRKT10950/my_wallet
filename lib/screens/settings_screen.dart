import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../models/income_config.dart';
import 'category_manager_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: const Icon(Icons.category, color: Colors.tealAccent, size: 30),
              title: const Text('Manage Categories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              subtitle: Text('${provider.categories.length} Categories Configured'),
              trailing: const Icon(Icons.arrow_forward_ios),
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
            child: Text('Income Configuration', style: TextStyle(fontSize: 16, color: Colors.grey)),
          ),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: const Icon(Icons.account_balance_wallet, color: Colors.deepPurpleAccent, size: 30),
                  title: const Text('Set Default Income', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.deepPurpleAccent),
                    onPressed: () => _showSetIncomeModal(context),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  title: const Text('Current Default Income'),
                  trailing: Text(
                    '₹${provider.getMonthlyIncome(DateTime.now().month, DateTime.now().year).toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
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
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
            const Text('Set Default Income', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Monthly Income', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: _submit,
                child: const Text('Save Income', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
