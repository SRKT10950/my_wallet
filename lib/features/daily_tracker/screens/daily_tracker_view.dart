import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Daily Tracker View — daily log, streak counter, and daily budget status.
class DailyTrackerView extends StatefulWidget {
  const DailyTrackerView({super.key});

  @override
  State<DailyTrackerView> createState() => _DailyTrackerViewState();
}

class _DailyTrackerViewState extends State<DailyTrackerView> {
  final List<Map<String, dynamic>> _dailyEntries = [
    {
      'time': '09:30 AM',
      'title': 'Morning Coffee & Snack',
      'category': 'Food & Drinks',
      'amount': '₹ 180',
      'type': 'expense',
    },
    {
      'time': '01:15 PM',
      'title': 'Team Lunch',
      'category': 'Food & Drinks',
      'amount': '₹ 450',
      'type': 'expense',
    },
    {
      'time': '05:00 PM',
      'title': 'Freelance Payment Received',
      'category': 'Income',
      'amount': '₹ 5,000',
      'type': 'income',
    },
  ];

  void _showAddEntryDialog() {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String selectedType = 'expense';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: AppTheme.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Add Daily Log Entry',
              style: TextStyle(color: AppTheme.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Title / Description',
                  hintText: 'e.g. Bus fare',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Amount (₹)',
                  hintText: 'e.g. 250',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Expense')),
                      selected: selectedType == 'expense',
                      selectedColor: AppTheme.error.withValues(alpha: 0.3),
                      onSelected: (_) =>
                          setDlgState(() => selectedType = 'expense'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Income')),
                      selected: selectedType == 'income',
                      selectedColor: AppTheme.success.withValues(alpha: 0.3),
                      onSelected: (_) =>
                          setDlgState(() => selectedType = 'income'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: AppTheme.textHint)),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleCtrl.text.isNotEmpty && amountCtrl.text.isNotEmpty) {
                  setState(() {
                    _dailyEntries.insert(0, {
                      'time': 'Just now',
                      'title': titleCtrl.text.trim(),
                      'category': selectedType == 'income' ? 'Income' : 'General',
                      'amount': '${selectedType == 'income' ? '+' : '-'}₹ ${amountCtrl.text.trim()}',
                      'type': selectedType,
                    });
                  });
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Add Log'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddEntryDialog,
        backgroundColor: AppTheme.primaryViolet,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Entry',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Streak & Daily Target Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.card, AppTheme.cardLight],
                ),
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGold.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.local_fire_department_rounded,
                        color: AppTheme.accentGold, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          '7 Day Tracking Streak! 🔥',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Daily target: Max ₹ 1,000 / day',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              "Today's Log",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 14),

            ..._dailyEntries.map((entry) {
              final isInc = entry['type'] == 'income';
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (isInc ? AppTheme.success : AppTheme.error)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isInc
                            ? Icons.arrow_downward_rounded
                            : Icons.arrow_upward_rounded,
                        color: isInc ? AppTheme.success : AppTheme.error,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry['title'] as String,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${entry['category']} • ${entry['time']}',
                            style: const TextStyle(
                              color: AppTheme.textHint,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      entry['amount'] as String,
                      style: TextStyle(
                        color: isInc ? AppTheme.success : AppTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
