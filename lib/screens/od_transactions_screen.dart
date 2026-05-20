import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/finance_provider.dart';
import '../models/od_account.dart';

class OdTransactionsScreen extends StatelessWidget {
  final OdAccount account;
  const OdTransactionsScreen({super.key, required this.account});

  void _showAddTxModal(BuildContext context, {OdTransaction? transaction}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddOdTransactionSheet(
        accountId: account.id!,
        transaction: transaction,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);
    final transactions = provider.odTransactions
        .where((t) => t.odAccountId == account.id)
        .toList()
        .reversed
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(account.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Text('Transaction History', style: TextStyle(fontSize: 12, color: Colors.white60)),
          ],
        ),
        backgroundColor: const Color(0xFF1A1A2E),
      ),
      body: Container(
        color: const Color(0xFF1A1A2E),
        child: transactions.isEmpty
            ? const Center(child: Text('No transactions yet.', style: TextStyle(color: Colors.grey)))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final tx = transactions[index];
                  final isDebit = tx.type == 'Debit';

                  // Calculate balance after this transaction
                  double balanceAfter = 0.0;
                  // We need to sum all transactions up to this one (since list is reversed, it's index to end)
                  for (int i = transactions.length - 1; i >= index; i--) {
                    if (transactions[i].type == 'Debit') {
                      balanceAfter += transactions[i].amount;
                    } else {
                      balanceAfter -= transactions[i].amount;
                    }
                  }
                  
                  final dailyInterest = (balanceAfter * account.interestRate) / (365 * 100);

                  return InkWell(
                    onTap: () => _showAddTxModal(context, transaction: tx),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: isDebit ? Colors.redAccent.withOpacity(0.1) : Colors.greenAccent.withOpacity(0.1),
                                    child: Icon(
                                      isDebit ? Icons.arrow_outward : Icons.arrow_downward,
                                      color: isDebit ? Colors.redAccent : Colors.greenAccent,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(isDebit ? 'Withdrawal (Debit)' : 'Deposit (Credit)', 
                                           style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                      Text(DateFormat('MMM dd, yyyy').format(DateTime.parse(tx.date)), 
                                           style: const TextStyle(fontSize: 12, color: Colors.white54)),
                                    ],
                                  ),
                                ],
                              ),
                              Text(
                                '${isDebit ? '-' : '+'}₹${tx.amount.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 18, 
                                  fontWeight: FontWeight.bold, 
                                  color: isDebit ? Colors.redAccent : Colors.greenAccent
                                ),
                              ),
                            ],
                          ),
                          if (balanceAfter > 0) ...[
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Divider(color: Colors.white10, height: 1),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Resulting Balance: ₹${balanceAfter.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: Colors.white38)),
                                Text('Daily Interest: ₹${dailyInterest.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTxModal(context),
        backgroundColor: Colors.cyanAccent,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}

class AddOdTransactionSheet extends StatefulWidget {
  final int accountId;
  final OdTransaction? transaction;
  const AddOdTransactionSheet({super.key, required this.accountId, this.transaction});

  @override
  State<AddOdTransactionSheet> createState() => _AddOdTransactionSheetState();
}

class _AddOdTransactionSheetState extends State<AddOdTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  String _type = 'Debit';
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      _amountController.text = widget.transaction!.amount.toStringAsFixed(0);
      _type = widget.transaction!.type;
      _selectedDate = DateTime.parse(widget.transaction!.date);
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<FinanceProvider>(context, listen: false);
      final isEdit = widget.transaction != null;
      final updated = OdTransaction(
        id: isEdit ? widget.transaction!.id : null,
        odAccountId: widget.accountId,
        amount: double.parse(_amountController.text),
        type: _type,
        date: _selectedDate.toIso8601String(),
      );

      if (isEdit) {
        provider.updateOdTransaction(updated);
      } else {
        provider.addOdTransaction(updated);
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.transaction != null;
    final provider = Provider.of<FinanceProvider>(context);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF16213E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        top: 32,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isEdit ? 'Edit Transaction' : 'New OD Transaction', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 24),
            
            // Toggle for Debit/Credit
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _type = 'Debit'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _type == 'Debit' ? Colors.redAccent : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(child: Text('Debit', style: TextStyle(fontWeight: FontWeight.bold, color: _type == 'Debit' ? Colors.white : Colors.white60))),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _type = 'Credit'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _type == 'Credit' ? Colors.greenAccent : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(child: Text('Credit', style: TextStyle(fontWeight: FontWeight.bold, color: _type == 'Credit' ? Colors.white : Colors.white60))),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            TextFormField(
              controller: _amountController,
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '₹0',
                hintStyle: const TextStyle(color: Colors.white24),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent)),
              ),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 24),
            
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today, color: Colors.cyanAccent),
              title: Text(DateFormat('MMMM dd, yyyy').format(_selectedDate), style: const TextStyle(color: Colors.white)),
              trailing: const Icon(Icons.edit, color: Colors.white54, size: 18),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
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
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete Transaction'),
                            content: const Text('Are you sure you want to delete this transaction?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  provider.deleteOdTransaction(widget.transaction!.id!);
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
                  const SizedBox(width: 16),
                ],
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyanAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _submit,
                    child: Text(isEdit ? 'Update' : 'Add Transaction', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
