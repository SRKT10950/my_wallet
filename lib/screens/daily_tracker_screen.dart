import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/finance_provider.dart';
import '../models/transaction.dart';
import '../models/category.dart';

class DailyTrackerScreen extends StatelessWidget {
  const DailyTrackerScreen({super.key});

  void _showAddTransactionModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const AddTransactionSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);
    final transactions = provider.transactions.reversed.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Tracker')),
      body: transactions.isEmpty
          ? const Center(child: Text('No recent transactions.', style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final tx = transactions[index];
                final cat = provider.categories.firstWhere((c) => c.id == tx.categoryId, orElse: () => Category(name: 'Unknown', plannedAmount: 0));
                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      child: Icon(Icons.receipt, color: Theme.of(context).colorScheme.primary),
                    ),
                    title: Text(tx.itemService, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Text('${cat.name}\n${DateFormat('MMM dd, yyyy').format(DateTime.parse(tx.date))}'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('₹${tx.cost.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        if (tx.cleared)
                          const Text('Cleared', style: TextStyle(color: Colors.green, fontSize: 12))
                        else
                          Text('Paid: ₹${tx.paidAmount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.orange, fontSize: 12)),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTransactionModal(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Entry'),
      ),
    );
  }
}

class AddTransactionSheet extends StatefulWidget {
  const AddTransactionSheet({super.key});

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now();
  Category? _selectedCategory;
  final _itemController = TextEditingController();
  final _costController = TextEditingController();
  final _paidController = TextEditingController();
  bool _cleared = false;

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<FinanceProvider>(context, listen: false);
      final tx = DailyTransaction(
        date: _selectedDate.toIso8601String(),
        categoryId: _selectedCategory!.id!,
        itemService: _itemController.text,
        cost: double.parse(_costController.text),
        paidAmount: double.parse(_paidController.text),
        cleared: _cleared,
      );
      provider.addTransaction(tx);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);
    
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('New Transaction', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
              ),
              DropdownButtonFormField<Category>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                items: provider.categories.map<DropdownMenuItem<Category>>((c) => DropdownMenuItem<Category>(value: c, child: Text(c.name))).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val),
                validator: (val) => val == null ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _itemController,
                decoration: const InputDecoration(labelText: 'Item/Service', border: OutlineInputBorder()),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _costController,
                      decoration: const InputDecoration(labelText: 'Cost', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      onChanged: (val) {
                        if (!_cleared) _paidController.text = val;
                      },
                      validator: (val) => val!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _paidController,
                      decoration: const InputDecoration(labelText: 'Paid Amount', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (val) => val!.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Mark as Cleared'),
                value: _cleared,
                onChanged: (val) {
                  setState(() {
                    _cleared = val ?? false;
                    if (_cleared) _paidController.text = _costController.text;
                  });
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  onPressed: _submit,
                  child: const Text('Save Entry', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
