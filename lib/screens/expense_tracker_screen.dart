import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';

class ExpenseTrackerScreen extends StatefulWidget {
  const ExpenseTrackerScreen({super.key});

  @override
  State<ExpenseTrackerScreen> createState() => _ExpenseTrackerScreenState();
}

class _ExpenseTrackerScreenState extends State<ExpenseTrackerScreen> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);

    final Map<int, double> actualExpenses = {};
    for (var tx in provider.transactions) {
      final date = DateTime.parse(tx.date);
      if (date.month == _selectedMonth && date.year == _selectedYear) {
        actualExpenses[tx.categoryId] = (actualExpenses[tx.categoryId] ?? 0) + tx.cost;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Expenses Overview')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildDropdown<int>(
                    _selectedMonth, 
                    List.generate(12, (i) => i + 1), 
                    (val) => setState(() => _selectedMonth = val!),
                    labelBuilder: (m) => ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][m - 1],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDropdown<int>(
                    _selectedYear, 
                    List.generate(10, (i) => DateTime.now().year - 5 + i), 
                    (val) => setState(() => _selectedYear = val!)
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: provider.categories.isEmpty
                  ? const Center(child: Text('No categories available.', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: provider.categories.length,
                      itemBuilder: (context, index) {
                        final cat = provider.categories[index];
                        final actual = actualExpenses[cat.id] ?? 0.0;
                        final variance = cat.plannedAmount - actual;
                        final isOverBudget = variance < 0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(child: Text(cat.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                                  const SizedBox(width: 8),
                                  Chip(
                                    label: Text(
                                      isOverBudget ? 'Over Budget' : 'Under Budget',
                                      style: TextStyle(color: isOverBudget ? Colors.redAccent : Colors.greenAccent, fontWeight: FontWeight.bold),
                                    ),
                                    backgroundColor: (isOverBudget ? Colors.redAccent : Colors.greenAccent).withValues(alpha: 0.1),
                                    side: BorderSide.none,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildStatColumn('Planned', cat.plannedAmount, Colors.white70, provider.defaultCurrency),
                                  _buildStatColumn('Actual', actual, Colors.white, provider.defaultCurrency),
                                  _buildStatColumn('Variance', variance.abs(), isOverBudget ? Colors.redAccent : Colors.greenAccent, provider.defaultCurrency),
                                ],
                              ),
                              const SizedBox(height: 16),
                              LinearProgressIndicator(
                                value: cat.plannedAmount > 0 ? (actual / cat.plannedAmount).clamp(0.0, 1.0) : 0,
                                backgroundColor: Colors.white12,
                                color: isOverBudget ? Colors.redAccent : Colors.tealAccent,
                                minHeight: 8,
                                borderRadius: BorderRadius.circular(4),
                              )
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, double amount, Color color, String symbol) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text('$symbol${amount.toStringAsFixed(0)}', style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildDropdown<T>(T value, List<T> items, void Function(T?) onChanged, {String Function(T)? labelBuilder}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: true,
          value: value,
          dropdownColor: const Color(0xFF1E1E2C),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.tealAccent),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(labelBuilder != null ? labelBuilder(e) : e.toString(), style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
