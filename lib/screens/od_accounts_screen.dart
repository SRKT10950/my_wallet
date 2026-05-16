import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../models/od_account.dart';
import 'od_transactions_screen.dart';

class OdAccountsScreen extends StatelessWidget {
  const OdAccountsScreen({super.key});

  void _showAddAccountModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const AddOdAccountSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);
    final accounts = provider.odAccounts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('OD Accounts', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: accounts.isEmpty
              ? const Center(child: Text('No OD Accounts added.', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: accounts.length,
                  itemBuilder: (context, index) {
                    final acc = accounts[index];
                    final used = provider.getOdUsedAmount(acc.id!);
                    final remaining = acc.limit - used;
                    final interestToday = provider.calculateOdInterest(acc);
                    final interestBilling = provider.calculateOdInterest(acc, upToBillingDate: true);

                    return Card(
                      elevation: 8,
                      margin: const EdgeInsets.only(bottom: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      color: const Color(0xFF0F3460).withOpacity(0.8),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => OdTransactionsScreen(account: acc)),
                          );
                        },
                        borderRadius: BorderRadius.circular(24),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(acc.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
                                    child: Text('Day ${acc.billingDay} Billing', style: const TextStyle(fontSize: 12, color: Colors.white70)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              _buildStatRow('Limit', acc.limit, 'Used', used),
                              const SizedBox(height: 12),
                              _buildStatRow('Remaining', remaining, 'Interest Rate', acc.interestRate, isPercent: true),
                              const Divider(color: Colors.white12, height: 32),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildSmallStat('Interest (Today)', interestToday, Colors.orangeAccent),
                                  ),
                                  Expanded(
                                    child: _buildSmallStat('Interest (Billing)', interestBilling, Colors.redAccent),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddAccountModal(context),
        icon: const Icon(Icons.add),
        label: const Text('Add OD Account'),
        backgroundColor: Colors.cyanAccent,
        foregroundColor: Colors.black,
      ),
    );
  }

  Widget _buildStatRow(String label1, double val1, String label2, double val2, {bool isPercent = false}) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label1, style: const TextStyle(color: Colors.white60, fontSize: 13)),
              const SizedBox(height: 4),
              Text('₹${val1.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label2, style: const TextStyle(color: Colors.white60, fontSize: 13)),
              const SizedBox(height: 4),
              Text(isPercent ? '${val2.toStringAsFixed(2)}%' : '₹${val2.toStringAsFixed(0)}', 
                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isPercent ? Colors.tealAccent : Colors.white)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSmallStat(String label, double val, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
        const SizedBox(height: 4),
        Text('₹${val.toStringAsFixed(2)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

class AddOdAccountSheet extends StatefulWidget {
  const AddOdAccountSheet({super.key});

  @override
  State<AddOdAccountSheet> createState() => _AddOdAccountSheetState();
}

class _AddOdAccountSheetState extends State<AddOdAccountSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _limitController = TextEditingController();
  final _rateController = TextEditingController();
  final _billingDayController = TextEditingController();

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<FinanceProvider>(context, listen: false);
      provider.addOdAccount(OdAccount(
        name: _nameController.text,
        limit: double.parse(_limitController.text),
        interestRate: double.parse(_rateController.text),
        billingDay: int.parse(_billingDayController.text),
      ));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Setup OD Account', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 24),
              _buildField(_nameController, 'Bank / Account Name', Icons.account_balance),
              const SizedBox(height: 16),
              _buildField(_limitController, 'OD Limit (Principal)', Icons.account_balance_wallet, isNumeric: true),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildField(_rateController, 'Annual Interest %', Icons.percent, isNumeric: true)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildField(_billingDayController, 'Billing Day (1-31)', Icons.calendar_today, isNumeric: true)),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _submit,
                  child: const Text('Create Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, {bool isNumeric = false}) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60),
        prefixIcon: Icon(icon, color: Colors.cyanAccent),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.white12)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.cyanAccent)),
      ),
      validator: (v) => v!.isEmpty ? 'Required' : null,
    );
  }
}
