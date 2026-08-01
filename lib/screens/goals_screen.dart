import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/finance_provider.dart';
import '../models/goal.dart';
import '../models/wallet_account.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  void _showGoalModal(BuildContext context, {Goal? goal}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GoalSheet(goal: goal),
    );
  }

  void _showDepositDialog(BuildContext context, Goal goal) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF121422),
          title: Text('Add Savings to "${goal.name}"', style: const TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Amount to add',
              labelStyle: TextStyle(color: Colors.grey),
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                final amt = double.tryParse(controller.text);
                if (amt != null && amt > 0) {
                  final provider = Provider.of<FinanceProvider>(context, listen: false);
                  final updated = Goal(
                    id: goal.id,
                    name: goal.name,
                    targetAmount: goal.targetAmount,
                    savedAmount: goal.savedAmount + amt,
                    targetDate: goal.targetDate,
                    accountId: goal.accountId,
                    color: goal.color,
                  );
                  provider.updateGoal(updated);
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Add Savings', style: TextStyle(color: Colors.tealAccent)),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);
    final goals = provider.goals;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings Goals'),
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
        child: goals.isEmpty
            ? const Center(
                child: Text('No savings goals set. Start planning your future!', style: TextStyle(color: Colors.white54)),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: goals.length,
                itemBuilder: (context, index) {
                  final goal = goals[index];
                  final Color accentColor = Color(int.parse(goal.color.replaceFirst('#', '0xFF')));
                  final progress = goal.targetAmount > 0 ? (goal.savedAmount / goal.targetAmount).clamp(0.0, 1.0) : 0.0;
                  final linkedAcc = goal.accountId != null
                      ? provider.accounts.firstWhere((a) => a.id == goal.accountId, orElse: () => WalletAccount(name: 'None', type: 'Cash', initialBalance: 0, currencySymbol: '₹', color: ''))
                      : null;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF121422),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: accentColor.withValues(alpha: 0.2), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    goal.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                                  ),
                                  if (linkedAcc != null) ...[
                                    const SizedBox(height: 2),
                                    Text('Linked: ${linkedAcc.name}', style: const TextStyle(color: Colors.white30, fontSize: 11)),
                                  ]
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.white54, size: 20),
                                onPressed: () => _showGoalModal(context, goal: goal),
                              )
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${provider.defaultCurrency}${goal.savedAmount.toStringAsFixed(0)} Saved',
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: accentColor),
                              ),
                              Text(
                                'Target: ${provider.defaultCurrency}${goal.targetAmount.toStringAsFixed(0)}',
                                style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.white10,
                            color: accentColor,
                            minHeight: 10,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${(progress * 100).toStringAsFixed(0)}% Completed',
                                style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: accentColor.withValues(alpha: 0.15),
                                  foregroundColor: accentColor,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('DEPOSIT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                                onPressed: () => _showDepositDialog(context, goal),
                              ),
                            ],
                          ),
                          if (goal.targetDate != null) ...[
                            const Divider(height: 24, color: Colors.white10),
                            Row(
                              children: [
                                const Icon(Icons.event_outlined, color: Colors.white30, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  'Target Date: ${DateFormat('MMM dd, yyyy').format(DateTime.parse(goal.targetDate!))}',
                                  style: const TextStyle(color: Colors.white30, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            )
                          ]
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showGoalModal(context),
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text('Add Goal', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF8B5CF6),
      ),
    );
  }
}

class GoalSheet extends StatefulWidget {
  final Goal? goal;
  const GoalSheet({super.key, this.goal});

  @override
  State<GoalSheet> createState() => _GoalSheetState();
}

class _GoalSheetState extends State<GoalSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetController = TextEditingController();
  final _savedController = TextEditingController();
  WalletAccount? _selectedAccount;
  DateTime? _selectedDate;
  String _selectedColor = '#8B5CF6';

  final List<String> _colors = ['#8B5CF6', '#3B82F6', '#EF4444', '#10B981', '#F59E0B', '#EC4899', '#06B6D4'];

  @override
  void initState() {
    super.initState();
    if (widget.goal != null) {
      _nameController.text = widget.goal!.name;
      _targetController.text = widget.goal!.targetAmount.toString();
      _savedController.text = widget.goal!.savedAmount.toString();
      _selectedColor = widget.goal!.color;
      if (widget.goal!.targetDate != null) {
        _selectedDate = DateTime.parse(widget.goal!.targetDate!);
      }
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<FinanceProvider>(context, listen: false);
      final goal = Goal(
        id: widget.goal?.id,
        name: _nameController.text,
        targetAmount: double.parse(_targetController.text),
        savedAmount: double.parse(_savedController.text.isEmpty ? '0' : _savedController.text),
        targetDate: _selectedDate?.toIso8601String(),
        accountId: _selectedAccount?.id,
        color: _selectedColor,
      );

      if (widget.goal == null) {
        provider.addGoal(goal);
      } else {
        provider.updateGoal(goal);
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);
    final isEdit = widget.goal != null;

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
                isEdit ? 'Edit Savings Goal' : 'Create Savings Goal',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Goal Name (e.g., Save for Car, Laptop)',
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
                      controller: _targetController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Target Amount',
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
                    child: TextFormField(
                      controller: _savedController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Already Saved',
                        labelStyle: const TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<WalletAccount>(
                initialValue: _selectedAccount,
                dropdownColor: const Color(0xFF121422),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Link to Wallet Account (Optional)',
                  labelStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                items: provider.accounts.map((a) => DropdownMenuItem(value: a, child: Text(a.name))).toList(),
                onChanged: (val) => setState(() => _selectedAccount = val),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _selectedDate == null ? 'Target Date: None' : 'Target Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate!)}',
                  style: const TextStyle(color: Colors.white),
                ),
                trailing: const Icon(Icons.calendar_today, color: Color(0xFF8B5CF6)),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 365)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2101),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
              ),
              const SizedBox(height: 16),
              const Text('Goal Theme Color', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              SizedBox(
                height: 44,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _colors.length,
                  itemBuilder: (context, index) {
                    final colorHex = _colors[index];
                    final colorVal = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
                    final isSelected = _selectedColor == colorHex;

                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = colorHex),
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        width: 44,
                        decoration: BoxDecoration(
                          color: colorVal,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 3)
                              : Border.all(color: Colors.transparent),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 20)
                            : null,
                      ),
                    );
                  },
                ),
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
                              title: const Text('Delete Goal?'),
                              content: const Text('Are you sure you want to delete this savings goal?', style: TextStyle(color: Colors.white70)),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                TextButton(
                                  onPressed: () {
                                    provider.deleteGoal(widget.goal!.id!);
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
                        backgroundColor: const Color(0xFF8B5CF6),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _submit,
                      child: Text(
                        isEdit ? 'Update Goal' : 'Save Goal',
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
