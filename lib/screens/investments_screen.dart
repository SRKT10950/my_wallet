import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/finance_provider.dart';
import '../models/investment.dart';

class InvestmentsScreen extends StatelessWidget {
  const InvestmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Investments', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Consumer<FinanceProvider>(
        builder: (context, provider, child) {
          if (provider.investments.isEmpty) {
            return const Center(child: Text('No investments added yet.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16.0).copyWith(bottom: 80),
            itemCount: provider.investments.length,
            itemBuilder: (context, index) {
              final inv = provider.investments[index];
              final totalInvested = provider.getTotalInvested(inv);
              final currentMaturity = provider.getCurrentMaturity(inv);
              final finalMaturity = provider.getFinalMaturity(inv);
              final isMonthly = ['RD', 'SIP', 'PPF'].contains(inv.type);
              
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: InkWell(
                  onTap: () => _showAddInvestmentSheet(context, investment: inv),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(child: Text(inv.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18), overflow: TextOverflow.ellipsis)),
                            const SizedBox(width: 8),
                            Chip(
                              label: Text(inv.type, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                              backgroundColor: Colors.purpleAccent,
                              side: BorderSide.none,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(isMonthly ? 'Installment: ₹${inv.amount.toStringAsFixed(0)} / month' : 'Principal: ₹${inv.amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14)),
                        Text('ROI: ${inv.expectedRoi}% p.a.  •  Tenure: ${inv.tenureMonths} months', style: const TextStyle(fontSize: 14)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _buildColumnDetail('Total Invested', totalInvested, color: Colors.white70)),
                            Expanded(child: _buildColumnDetail('Current Value', currentMaturity, color: Colors.greenAccent)),
                            Expanded(child: _buildColumnDetail('Final Value', finalMaturity, color: Colors.blueAccent)),
                          ],
                        ),
                        const Divider(height: 24, color: Colors.white24),
                        Text('Start Date: ${DateFormat('MMM dd, yyyy').format(DateTime.parse(inv.startDate))}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddInvestmentSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Investment'),
        backgroundColor: Colors.purpleAccent,
      ),
    );
  }

  Widget _buildColumnDetail(String label, double value, {Color color = Colors.white}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '₹${value.toStringAsFixed(0)}',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
          ),
        ),
      ],
    );
  }

  void _showAddInvestmentSheet(BuildContext context, {Investment? investment}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => AddInvestmentSheet(investment: investment),
    );
  }
}

class AddInvestmentSheet extends StatefulWidget {
  final Investment? investment;
  const AddInvestmentSheet({super.key, this.investment});

  @override
  State<AddInvestmentSheet> createState() => _AddInvestmentSheetState();
}

class _AddInvestmentSheetState extends State<AddInvestmentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _roiController = TextEditingController();
  final _tenureController = TextEditingController();
  String _selectedType = 'FD';
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.investment != null) {
      _nameController.text = widget.investment!.name;
      _amountController.text = widget.investment!.amount.toStringAsFixed(0);
      _roiController.text = widget.investment!.expectedRoi.toString();
      _tenureController.text = widget.investment!.tenureMonths.toString();
      _selectedType = widget.investment!.type;
      _selectedDate = DateTime.parse(widget.investment!.startDate);
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<FinanceProvider>(context, listen: false);
      final isEdit = widget.investment != null;
      final updatedInvestment = Investment(
        id: isEdit ? widget.investment!.id : null,
        name: _nameController.text,
        type: _selectedType,
        amount: double.parse(_amountController.text),
        expectedRoi: double.parse(_roiController.text),
        tenureMonths: int.parse(_tenureController.text),
        startDate: _selectedDate.toIso8601String(),
      );

      if (isEdit) {
        provider.updateInvestment(updatedInvestment);
      } else {
        provider.addInvestment(updatedInvestment);
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.investment != null;
    final isMonthly = ['RD', 'SIP', 'PPF'].contains(_selectedType);
    final provider = Provider.of<FinanceProvider>(context);
    
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(isEdit ? 'Edit Investment' : 'Add Investment', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  initialValue: _selectedType,
                  decoration: const InputDecoration(labelText: 'Investment Type', border: OutlineInputBorder()),
                  items: ['FD', 'RD', 'Mutual Fund', 'Stock', 'SIP', 'PPF'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) => setState(() => _selectedType = v!),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name (e.g. HDFC FD)', border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _amountController,
                  decoration: InputDecoration(labelText: isMonthly ? 'Monthly Installment (₹)' : 'Principal Amount (₹)', border: const OutlineInputBorder()),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    final amt = double.tryParse(v);
                    if (amt == null) return 'Must be a valid number';
                    if (amt <= 0) return 'Must be greater than 0';
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _roiController,
                        decoration: const InputDecoration(labelText: 'Expected ROI (% p.a.)', border: OutlineInputBorder()),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          final roiVal = double.tryParse(v);
                          if (roiVal == null) return 'Must be a valid number';
                          if (roiVal < 0) return 'Cannot be negative';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _tenureController,
                        decoration: const InputDecoration(labelText: 'Tenure (Months)', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          final months = int.tryParse(v);
                          if (months == null) return 'Must be a whole number';
                          if (months <= 0) return 'Must be greater than 0';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Start Date: ${DateFormat('MMM dd, yyyy').format(_selectedDate)}'),
                  trailing: const Icon(Icons.calendar_today, color: Colors.purpleAccent),
                  onTap: () async {
                    final picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2000), lastDate: DateTime(2101));
                    if (picked != null) setState(() => _selectedDate = picked);
                  },
                ),
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
                                title: const Text('Delete Investment'),
                                content: const Text('Are you sure you want to delete this investment?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      provider.deleteInvestment(widget.investment!.id!);
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
                          backgroundColor: Colors.purpleAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _submit,
                        child: Text(isEdit ? 'Update' : 'Add Investment', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
