import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/finance_provider.dart';
import '../models/transaction.dart';
import '../models/category.dart';

class DailyTrackerScreen extends StatelessWidget {
  const DailyTrackerScreen({super.key});

  void _showTransactionModal(BuildContext context, {DailyTransaction? transaction}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TransactionSheet(transaction: transaction),
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
                    onTap: () => _showTransactionModal(context, transaction: tx),
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
                          const Text('Cleared', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold))
                        else
                          Text('Paid: ₹${tx.paidAmount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.orange, fontSize: 12)),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTransactionModal(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Entry'),
      ),
    );
  }
}

class TransactionSheet extends StatefulWidget {
  final DailyTransaction? transaction;
  const TransactionSheet({super.key, this.transaction});

  @override
  State<TransactionSheet> createState() => _TransactionSheetState();
}

class _TransactionSheetState extends State<TransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now();
  Category? _selectedCategory;
  final _itemController = TextEditingController();
  final _costController = TextEditingController();
  final _paidController = TextEditingController();
  bool _cleared = false;

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      _selectedDate = DateTime.parse(widget.transaction!.date);
      _itemController.text = widget.transaction!.itemService;
      _costController.text = widget.transaction!.cost.toString();
      _paidController.text = widget.transaction!.paidAmount.toString();
      _cleared = widget.transaction!.cleared;
      
      // We'll set the category in the build method after provider is available
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<FinanceProvider>(context, listen: false);
      final tx = DailyTransaction(
        id: widget.transaction?.id,
        date: _selectedDate.toIso8601String(),
        categoryId: _selectedCategory!.id!,
        itemService: _itemController.text,
        cost: double.parse(_costController.text),
        paidAmount: double.parse(_paidController.text),
        cleared: _cleared,
      );
      
      if (widget.transaction == null) {
        provider.addTransaction(tx);
      } else {
        provider.updateTransaction(tx);
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);
    
    // Set selected category if it's an edit and not already set
    if (widget.transaction != null && _selectedCategory == null) {
      try {
        _selectedCategory = provider.categories.firstWhere((c) => c.id == widget.transaction!.categoryId);
      } catch (e) {
        // Handle if category was deleted
      }
    }

    final isEdit = widget.transaction != null;
    
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
              Text(isEdit ? 'Edit Transaction' : 'New Transaction', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}'),
                trailing: const Icon(Icons.calendar_today, color: Colors.tealAccent),
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
              if (isEdit) ...[
                const SizedBox(height: 10),
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
                  activeColor: Colors.tealAccent,
                  checkColor: Colors.black,
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  if (isEdit) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete Entry'),
                              content: const Text('Are you sure you want to delete this transaction?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    provider.deleteTransaction(widget.transaction!.id!);
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
                        label: const Text('Delete', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: isEdit ? Colors.blueAccent : Colors.tealAccent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _submit,
                      child: Text(isEdit ? 'Update' : 'Save Entry', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
