import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Lend & Borrow View — track receivables, payables, settlements, due dates.
class LendBorrowView extends StatefulWidget {
  const LendBorrowView({super.key});

  @override
  State<LendBorrowView> createState() => _LendBorrowViewState();
}

class _LendBorrowViewState extends State<LendBorrowView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _lentList = [
    {
      'name': 'Rahul Sharma',
      'amount': '₹ 5,000',
      'dueDate': '15 Aug 2026',
      'remarks': 'Trip expense split',
      'avatar': 'RS',
    },
    {
      'name': 'Amit Verma',
      'amount': '₹ 12,500',
      'dueDate': '20 Aug 2026',
      'remarks': 'Emergency loan',
      'avatar': 'AV',
    },
  ];

  final List<Map<String, dynamic>> _borrowedList = [
    {
      'name': 'Priya Patel',
      'amount': '₹ 2,000',
      'dueDate': '05 Aug 2026',
      'remarks': 'Dinner bill',
      'avatar': 'PP',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab Bar
        Container(
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: AppTheme.textSecondary,
            tabs: const [
              Tab(text: 'Lent (Receivable)'),
              Tab(text: 'Borrowed (Payable)'),
            ],
          ),
        ),

        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildList(_lentList, isLent: true),
              _buildList(_borrowedList, isLent: false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildList(List<Map<String, dynamic>> list, {required bool isLent}) {
    final total = isLent ? '₹ 17,500' : '₹ 2,000';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Total Summary Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: (isLent ? AppTheme.success : AppTheme.error)
                    .withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isLent ? 'Total Money Lent' : 'Total Money Borrowed',
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      total,
                      style: TextStyle(
                        color: isLent ? AppTheme.success : AppTheme.error,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                Icon(
                  isLent
                      ? Icons.arrow_circle_down_rounded
                      : Icons.arrow_circle_up_rounded,
                  color: isLent ? AppTheme.success : AppTheme.error,
                  size: 40,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          ...list.map((item) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.primaryViolet.withValues(alpha: 0.2),
                    child: Text(
                      item['avatar'] as String,
                      style: const TextStyle(
                          color: AppTheme.primaryTeal,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['name'] as String,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${item['remarks']} • Due ${item['dueDate']}',
                          style: const TextStyle(
                            color: AppTheme.textHint,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        item['amount'] as String,
                        style: TextStyle(
                          color: isLent ? AppTheme.success : AppTheme.error,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryViolet.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isLent ? 'Settle' : 'Pay Now',
                          style: const TextStyle(
                              color: AppTheme.primaryTeal, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
