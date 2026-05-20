import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/finance_provider.dart';
import '../models/lend_borrow.dart';

class LendBorrowScreen extends StatelessWidget {
  const LendBorrowScreen({super.key});

  void _showAddLendBorrowModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const AddLendBorrowSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Lend & Borrow'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'To Receive (Lend)'),
              Tab(text: 'To Pay (Borrow)'),
            ],
            indicatorColor: Colors.tealAccent,
          ),
        ),
        body: const TabBarView(
          children: [
            LendBorrowList(type: 'Lend'),
            LendBorrowList(type: 'Borrow'),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddLendBorrowModal(context),
          icon: const Icon(Icons.add),
          label: const Text('New Entry'),
        ),
      ),
    );
  }
}

class LendBorrowList extends StatelessWidget {
  final String type;
  const LendBorrowList({super.key, required this.type});

  void _showRepaymentsModal(BuildContext context, LendBorrow entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RepaymentsSheet(lendBorrow: entry),
    );
  }

  void _showAddLendBorrowModal(BuildContext context, {LendBorrow? lendBorrow}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddLendBorrowSheet(lendBorrow: lendBorrow),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);
    final entries = provider.lendBorrows.where((lb) => lb.type == type).toList();

    if (entries.isEmpty) {
      return const Center(child: Text('No records found.', style: TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 88),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final lb = entries[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            onTap: () => _showRepaymentsModal(context, lb),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(child: Text(lb.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18), overflow: TextOverflow.ellipsis)),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20, color: Colors.blueAccent),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => _showAddLendBorrowModal(context, lendBorrow: lb),
                          ),
                          const SizedBox(width: 8),
                          Chip(
                            label: Text(lb.status, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                            backgroundColor: lb.status == 'Active' ? Colors.blue : Colors.green,
                            side: BorderSide.none,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Principal: ₹${lb.principal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14)),
                  Text('Tenure: ${lb.tenure} months', style: const TextStyle(fontSize: 14)),
                  Text('Est. Interest (6% p.a.): ₹${((lb.principal * 0.06 * lb.tenure) / 12.0).toStringAsFixed(0)}', style: const TextStyle(color: Colors.orangeAccent)),
                  Text('Settled: ₹${lb.settled.toStringAsFixed(0)}', style: const TextStyle(color: Colors.greenAccent)),
                  Text('Pending Principal: ₹${lb.diff.toStringAsFixed(0)}', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  const Divider(height: 24, color: Colors.white24),
                  Row(
                    children: [
                      Expanded(child: Text('Start: ${DateFormat('MMM dd, yyyy').format(DateTime.parse(lb.date))}', style: const TextStyle(color: Colors.grey, fontSize: 12), overflow: TextOverflow.ellipsis)),
                      if (lb.returnDate.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Expanded(child: Text('Last Return: ${DateFormat('MMM dd, yyyy').format(DateTime.parse(lb.returnDate))}', textAlign: TextAlign.right, style: const TextStyle(color: Colors.grey, fontSize: 12), overflow: TextOverflow.ellipsis)),
                      ]
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class AddLendBorrowSheet extends StatefulWidget {
  final LendBorrow? lendBorrow;
  const AddLendBorrowSheet({super.key, this.lendBorrow});
  @override
  State<AddLendBorrowSheet> createState() => _AddLendBorrowSheetState();
}

class _AddLendBorrowSheetState extends State<AddLendBorrowSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _principalController = TextEditingController();
  String _selectedType = 'Lend';
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.lendBorrow != null) {
      _nameController.text = widget.lendBorrow!.name;
      _principalController.text = widget.lendBorrow!.principal.toStringAsFixed(0);
      _selectedType = widget.lendBorrow!.type;
      _selectedDate = DateTime.parse(widget.lendBorrow!.date);
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<FinanceProvider>(context, listen: false);
      final isEdit = widget.lendBorrow != null;
      final updated = LendBorrow(
        id: isEdit ? widget.lendBorrow!.id : null,
        name: _nameController.text,
        type: _selectedType,
        date: _selectedDate.toIso8601String(),
        tenure: isEdit ? widget.lendBorrow!.tenure : 0,
        principal: double.parse(_principalController.text),
        settled: isEdit ? widget.lendBorrow!.settled : 0.0,
        returnDate: isEdit ? widget.lendBorrow!.returnDate : '',
        status: isEdit ? widget.lendBorrow!.status : 'Active',
      );

      if (isEdit) {
        provider.updateLendBorrow(updated);
      } else {
        provider.addLendBorrow(updated);
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.lendBorrow != null;
    final provider = Provider.of<FinanceProvider>(context);

    return Container(
      decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.only(top: 24, left: 24, right: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isEdit ? 'Edit Entry' : 'New Entry', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
              items: ['Lend', 'Borrow'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => _selectedType = v!),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _principalController, 
              decoration: const InputDecoration(labelText: 'Principal Amount', border: OutlineInputBorder()), 
              keyboardType: TextInputType.number, 
              validator: (v) => v!.isEmpty ? 'Required' : null
            ),
            const SizedBox(height: 10),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}'),
              trailing: const Icon(Icons.calendar_today),
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
                            title: const Text('Delete Entry'),
                            content: const Text('Are you sure you want to delete this entry and all its repayments?'),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Cancel')),
                              TextButton(
                                onPressed: () {
                                  provider.deleteLendBorrow(widget.lendBorrow!.id!);
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
                      backgroundColor: Colors.tealAccent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _submit,
                    child: Text(isEdit ? 'Update' : 'Add Entry', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

class RepaymentsSheet extends StatefulWidget {
  final LendBorrow lendBorrow;
  const RepaymentsSheet({super.key, required this.lendBorrow});

  @override
  State<RepaymentsSheet> createState() => _RepaymentsSheetState();
}

class _RepaymentsSheetState extends State<RepaymentsSheet> {
  final _amountController = TextEditingController();
  String _selectedMethod = 'UPI';
  DateTime _selectedDate = DateTime.now();

  void _submitRepayment() {
    if (_amountController.text.isNotEmpty && widget.lendBorrow.id != null) {
      final provider = Provider.of<FinanceProvider>(context, listen: false);
      provider.addRepayment(Repayment(
        lendBorrowId: widget.lendBorrow.id!,
        name: widget.lendBorrow.name,
        paymentDate: _selectedDate.toIso8601String(),
        amount: double.parse(_amountController.text),
        method: _selectedMethod,
      ));
      _amountController.clear();
    }
  }

  void _confirmDeleteRepayment(BuildContext context, Repayment repayment) {
    final provider = Provider.of<FinanceProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Repayment'),
        content: const Text('Are you sure you want to delete this repayment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteRepayment(repayment.id!);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _showEditRepaymentDialog(BuildContext context, Repayment repayment) {
    final provider = Provider.of<FinanceProvider>(context, listen: false);
    final amountController = TextEditingController(text: repayment.amount.toStringAsFixed(0));
    String selectedMethod = repayment.method;
    DateTime selectedDate = DateTime.parse(repayment.paymentDate);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Repayment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(labelText: 'Amount (₹)', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedMethod,
                  decoration: const InputDecoration(labelText: 'Method', border: OutlineInputBorder()),
                  items: ['Cash', 'UPI', 'Bank Transfer'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (v) => setState(() => selectedMethod = v!),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}'),
                  trailing: const Icon(Icons.calendar_today, color: Colors.tealAccent),
                  onTap: () async {
                    final picked = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime(2000), lastDate: DateTime(2101));
                    if (picked != null) setState(() => selectedDate = picked);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (amountController.text.isNotEmpty) {
                  provider.updateRepayment(Repayment(
                    id: repayment.id,
                    lendBorrowId: repayment.lendBorrowId,
                    name: repayment.name,
                    paymentDate: selectedDate.toIso8601String(),
                    amount: double.parse(amountController.text),
                    method: selectedMethod,
                  ));
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Save', style: TextStyle(color: Colors.tealAccent)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);
    final history = provider.repayments.where((r) => r.lendBorrowId == widget.lendBorrow.id).toList();
    history.sort((a, b) => DateTime.parse(b.paymentDate).compareTo(DateTime.parse(a.paymentDate))); // newest first

    return Container(
      decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      height: MediaQuery.of(context).size.height * 0.85,
      padding: EdgeInsets.only(top: 24, left: 16, right: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        children: [
          Text('Repayments - ${widget.lendBorrow.name}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          // Add Repayment Form
          if (widget.lendBorrow.status == 'Active')
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _amountController,
                          decoration: const InputDecoration(labelText: 'Amount', border: OutlineInputBorder(), isDense: true),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: _selectedMethod,
                          decoration: const InputDecoration(labelText: 'Method', border: OutlineInputBorder(), isDense: true),
                          items: ['Cash', 'UPI', 'Bank Transfer'].map((m) => DropdownMenuItem(value: m, child: Text(m, overflow: TextOverflow.ellipsis))).toList(),
                          onChanged: (v) => setState(() => _selectedMethod = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: FittedBox(fit: BoxFit.scaleDown, child: Text(DateFormat('MMM dd, yyyy').format(_selectedDate))),
                          onPressed: () async {
                            final picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2000), lastDate: DateTime(2101));
                            if (picked != null) setState(() => _selectedDate = picked);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _submitRepayment,
                          child: const FittedBox(fit: BoxFit.scaleDown, child: Text('Add Repayment')),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          const Text('Payment History', style: TextStyle(fontWeight: FontWeight.bold)),
          const Divider(),
          // History List
          Expanded(
            child: history.isEmpty
                ? const Center(child: Text('No repayments yet.', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      final r = history[index];
                      return ListTile(
                        leading: CircleAvatar(backgroundColor: Colors.tealAccent.withOpacity(0.2), child: const Icon(Icons.check, color: Colors.tealAccent)),
                        title: Text('₹${r.amount.toStringAsFixed(0)} via ${r.method}'),
                        subtitle: Text(DateFormat('MMM dd, yyyy').format(DateTime.parse(r.paymentDate))),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20, color: Colors.blueAccent),
                              onPressed: () => _showEditRepaymentDialog(context, r),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20, color: Colors.redAccent),
                              onPressed: () => _confirmDeleteRepayment(context, r),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
