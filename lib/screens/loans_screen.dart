import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/finance_provider.dart';
import '../models/loan.dart';

class LoansScreen extends StatelessWidget {
  const LoansScreen({super.key});

  void _showAddLoanModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const AddLoanSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);
    final activeLoans = provider.loans.where((l) => l.status == 'Active').toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Active Loans')),
      body: activeLoans.isEmpty
          ? const Center(child: Text('No active loans.', style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 88),
              itemCount: activeLoans.length,
              itemBuilder: (context, index) {
                final loan = activeLoans[index];
                return _buildLoanCard(context, loan);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddLoanModal(context),
        icon: const Icon(Icons.add),
        label: const Text('New Loan'),
      ),
    );
  }

  Widget _buildLoanCard(BuildContext context, Loan loan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [Theme.of(context).colorScheme.surface, Theme.of(context).colorScheme.surface.withOpacity(0.5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: Text(loan.lender, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 8),
              Chip(
                label: Text(loan.status, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                backgroundColor: loan.status == 'Active' ? Colors.green : Colors.grey,
                side: BorderSide.none,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDetailRow('Start Date', DateFormat('MMM dd, yyyy').format(DateTime.parse(loan.startDate))),
          _buildDetailRow('End Date', DateFormat('MMM dd, yyyy').format(DateTime.parse(loan.endDate))),
          const Divider(height: 24, color: Colors.white24),
          Row(
            children: [
              Expanded(child: _buildColumnDetail('Principal', loan.principal)),
              Expanded(child: _buildColumnDetail('EMI / mo', loan.emi)),
              Expanded(child: _buildColumnDetail('ROI (Flat)', loan.roi, isPercent: true)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildColumnDetail('Total Interest', loan.interest)),
              Expanded(child: _buildColumnDetail('Total Payable', loan.total)),
              Expanded(child: _buildColumnDetail('Total Tenure', loan.tenure.toDouble(), isMonths: true)),
            ],
          ),
          const Divider(height: 24, color: Colors.white24),
          Row(
            children: [
              Expanded(child: _buildColumnDetail('Paid Amount', loan.paid, color: Colors.greenAccent)),
              Expanded(child: _buildColumnDetail('Pending Amount', loan.balance, color: Colors.redAccent)),
              Expanded(child: _buildColumnDetail('Pending Tenure', loan.tenurePending.toDouble(), isMonths: true)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildColumnDetail(String label, double value, {Color color = Colors.white, bool isPercent = false, bool isMonths = false}) {
    String displayValue;
    if (isPercent) {
      displayValue = '${value.toStringAsFixed(2)}%';
    } else if (isMonths) {
      displayValue = '${value.toInt()} mo';
    } else {
      displayValue = '₹${value.toStringAsFixed(0)}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        const SizedBox(height: 4),
        Text(displayValue, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}

class AddLoanSheet extends StatefulWidget {
  const AddLoanSheet({super.key});

  @override
  State<AddLoanSheet> createState() => _AddLoanSheetState();
}

class _AddLoanSheetState extends State<AddLoanSheet> {
  final _formKey = GlobalKey<FormState>();
  final _loanLenderController = TextEditingController();
  final _loanPrincipalController = TextEditingController();
  final _loanTenureController = TextEditingController();
  final _loanEmiController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<FinanceProvider>(context, listen: false);
      final principal = double.parse(_loanPrincipalController.text);
      final tenure = int.parse(_loanTenureController.text);
      final emi = double.parse(_loanEmiController.text);
      
      final total = emi * tenure;
      final interest = total - principal;
      
      // Calculate Exact Annual ROI (Reducing Balance)
      double roi = 0.0;
      if (total > principal && principal > 0 && tenure > 0) {
        double low = 0.0;
        double high = 1.0;
        double r = 0.0;
        for (int i = 0; i < 50; i++) {
          r = (low + high) / 2;
          double calcEmi = (principal * r * pow(1 + r, tenure)) / (pow(1 + r, tenure) - 1);
          if (calcEmi > emi) {
            high = r;
          } else {
            low = r;
          }
        }
        roi = r * 12 * 100; // Convert monthly rate to Annual Percentage
      }

      final endDate = DateTime(_selectedDate.year, _selectedDate.month + tenure, _selectedDate.day);

      provider.addLoan(Loan(
        lender: _loanLenderController.text,
        startDate: _selectedDate.toIso8601String(),
        endDate: endDate.toIso8601String(),
        tenure: tenure,
        roi: roi,
        principal: principal,
        interest: interest,
        total: total,
        paid: 0.0,
        balance: total,
        emi: emi,
        tenurePending: tenure,
        status: 'Active',
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
            const Text('Add New Loan', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Start Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}'),
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
            TextFormField(
              controller: _loanLenderController,
              decoration: const InputDecoration(labelText: 'Lender Name', border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _loanPrincipalController,
              decoration: const InputDecoration(labelText: 'Principal Amount', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: TextFormField(controller: _loanTenureController, decoration: const InputDecoration(labelText: 'Tenure (Months)', border: OutlineInputBorder()), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Required' : null)),
                const SizedBox(width: 10),
                Expanded(child: TextFormField(controller: _loanEmiController, decoration: const InputDecoration(labelText: 'EMI Amount', border: OutlineInputBorder()), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Required' : null)),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: _submit,
                child: const Text('Add Loan', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
