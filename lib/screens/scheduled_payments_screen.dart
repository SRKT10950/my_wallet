import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/finance_provider.dart';
import '../models/scheduled_payment.dart';
import '../models/category.dart';
import '../models/wallet_account.dart';

class ScheduledPaymentsScreen extends StatelessWidget {
  const ScheduledPaymentsScreen({super.key});

  void _showScheduledPaymentModal(BuildContext context, {ScheduledPayment? payment}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ScheduledPaymentSheet(payment: payment),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);
    final payments = provider.scheduledPayments;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recurring Bills & Income'),
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
        child: payments.isEmpty
            ? const Center(
                child: Text(
                  'No recurring bills or income scheduled.',
                  style: TextStyle(color: Colors.white54),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: payments.length,
                itemBuilder: (context, index) {
                  final payment = payments[index];
                  final cat = provider.categories.firstWhere((c) => c.id == payment.categoryId, orElse: () => Category(name: 'Unknown', plannedAmount: 0));
                  final acc = provider.accounts.firstWhere((a) => a.id == payment.accountId, orElse: () => WalletAccount(name: 'Cash', type: 'Cash', initialBalance: 0, currencySymbol: '₹', color: ''));
                  final dueDate = DateTime.parse(payment.nextDueDate);
                  final isOverdue = dueDate.isBefore(DateTime.now());
                  final color = payment.type == 'Expense' ? Colors.redAccent : Colors.greenAccent;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF121422),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.06), width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    payment.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${cat.name} • ${payment.frequency.toUpperCase()}',
                                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                                  ),
                                ],
                              ),
                              Text(
                                '${payment.type == 'Expense' ? '-' : '+'}${acc.currencySymbol}${payment.amount.toStringAsFixed(0)}',
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: color),
                              ),
                            ],
                          ),
                          const Divider(height: 24, color: Colors.white10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'NEXT DUE DATE',
                                    style: TextStyle(color: Colors.white30, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    DateFormat('MMM dd, yyyy').format(dueDate),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isOverdue ? Colors.redAccent : Colors.tealAccent,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.white54),
                                    onPressed: () => _showScheduledPaymentModal(context, payment: payment),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: color.withValues(alpha: 0.15),
                                      foregroundColor: color,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onPressed: () async {
                                      await provider.payScheduledPayment(payment.id!);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Processed payment: ${payment.name}!'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }
                                    },
                                    child: Text(
                                      payment.type == 'Expense' ? 'PAY BILL' : 'RECEIVE',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                                    ),
                                  ),
                                ],
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showScheduledPaymentModal(context),
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text('Add Scheduled', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }
}

class ScheduledPaymentSheet extends StatefulWidget {
  final ScheduledPayment? payment;
  const ScheduledPaymentSheet({super.key, this.payment});

  @override
  State<ScheduledPaymentSheet> createState() => _ScheduledPaymentSheetState();
}

class _ScheduledPaymentSheetState extends State<ScheduledPaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedType = 'Expense';
  Category? _selectedCategory;
  WalletAccount? _selectedAccount;
  String _selectedFrequency = 'Monthly';
  DateTime _selectedDate = DateTime.now();

  final List<String> _frequencies = ['Daily', 'Weekly', 'Monthly', 'Yearly'];

  @override
  void initState() {
    super.initState();
    if (widget.payment != null) {
      _nameController.text = widget.payment!.name;
      _amountController.text = widget.payment!.amount.toString();
      _selectedType = widget.payment!.type;
      _selectedFrequency = widget.payment!.frequency;
      _selectedDate = DateTime.parse(widget.payment!.nextDueDate);
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<FinanceProvider>(context, listen: false);
      final payment = ScheduledPayment(
        id: widget.payment?.id,
        name: _nameController.text,
        amount: double.parse(_amountController.text),
        type: _selectedType,
        categoryId: _selectedCategory!.id!,
        accountId: _selectedAccount!.id!,
        frequency: _selectedFrequency,
        nextDueDate: _selectedDate.toIso8601String(),
        active: true,
      );

      if (widget.payment == null) {
        provider.addScheduledPayment(payment);
      } else {
        provider.updateScheduledPayment(payment);
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);
    final isEdit = widget.payment != null;

    if (_selectedCategory == null && provider.categories.isNotEmpty) {
      if (widget.payment != null) {
        try {
          _selectedCategory = provider.categories.firstWhere((c) => c.id == widget.payment!.categoryId);
        } catch (_) {
          _selectedCategory = provider.categories.first;
        }
      } else {
        _selectedCategory = provider.categories.first;
      }
    }

    if (_selectedAccount == null && provider.accounts.isNotEmpty) {
      if (widget.payment != null) {
        try {
          _selectedAccount = provider.accounts.firstWhere((a) => a.id == widget.payment!.accountId);
        } catch (_) {
          _selectedAccount = provider.accounts.first;
        }
      } else {
        _selectedAccount = provider.accounts.first;
      }
    }

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
                isEdit ? 'Edit Scheduled Bill' : 'Add Scheduled Bill/Income',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment<String>(value: 'Expense', label: Text('Expense'), icon: Icon(Icons.remove_circle_outline)),
                  ButtonSegment<String>(value: 'Income', label: Text('Income'), icon: Icon(Icons.add_circle_outline)),
                ],
                selected: {_selectedType},
                onSelectionChanged: (val) => setState(() => _selectedType = val.first),
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                    if (states.contains(WidgetState.selected)) {
                      return _selectedType == 'Expense' ? Colors.redAccent.withValues(alpha: 0.2) : Colors.greenAccent.withValues(alpha: 0.2);
                    }
                    return Colors.transparent;
                  }),
                  foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                    if (states.contains(WidgetState.selected)) {
                      return _selectedType == 'Expense' ? Colors.redAccent : Colors.greenAccent;
                    }
                    return Colors.white70;
                  }),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Title (e.g., Netflix, Salary)',
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
                      controller: _amountController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        labelStyle: const TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (double.tryParse(v) == null) return 'Invalid amount';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedFrequency,
                      dropdownColor: const Color(0xFF121422),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Frequency',
                        labelStyle: const TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      items: _frequencies.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                      onChanged: (val) => setState(() => _selectedFrequency = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Category>(
                initialValue: _selectedCategory,
                dropdownColor: const Color(0xFF121422),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Category',
                  labelStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                items: provider.categories.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<WalletAccount>(
                initialValue: _selectedAccount,
                dropdownColor: const Color(0xFF121422),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Wallet Account',
                  labelStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                items: provider.accounts.map((a) => DropdownMenuItem(value: a, child: Text(a.name))).toList(),
                onChanged: (val) => setState(() => _selectedAccount = val),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Start / Next Due Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}', style: const TextStyle(color: Colors.white)),
                trailing: const Icon(Icons.calendar_today, color: Color(0xFF6366F1)),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 30)),
                    lastDate: DateTime(2101),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
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
                              title: const Text('Delete Schedule?'),
                              content: const Text('Are you sure you want to stop this recurring schedule?', style: TextStyle(color: Colors.white70)),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                TextButton(
                                  onPressed: () {
                                    provider.deleteScheduledPayment(widget.payment!.id!);
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
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _submit,
                      child: Text(
                        isEdit ? 'Update Schedule' : 'Save Schedule',
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
