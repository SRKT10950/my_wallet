import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Expenses View — expense categorization, budget limits, spending breakdown.
class ExpensesView extends StatelessWidget {
  const ExpensesView({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = [
      {'name': 'Food & Dining', 'amount': '₹ 14,200', 'pct': 0.39, 'color': Colors.orangeAccent, 'icon': Icons.restaurant_rounded},
      {'name': 'Bills & Utilities', 'amount': '₹ 11,500', 'pct': 0.31, 'color': AppTheme.primaryViolet, 'icon': Icons.receipt_long_rounded},
      {'name': 'Shopping', 'amount': '₹ 6,800', 'pct': 0.18, 'color': AppTheme.primaryTeal, 'icon': Icons.shopping_bag_rounded},
      {'name': 'Travel & Fuel', 'amount': '₹ 3,980', 'pct': 0.12, 'color': Colors.pinkAccent, 'icon': Icons.directions_car_rounded},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total Monthly Spend Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.surface, AppTheme.card],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'July Total Expenses',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 6),
                const Text(
                  '₹ 36,480.00',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: const [
                    Icon(Icons.trending_down_rounded, color: AppTheme.success, size: 18),
                    SizedBox(width: 6),
                    Text(
                      '8.5% lower than last month',
                      style: TextStyle(color: AppTheme.success, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'Spending by Category',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 14),

          ...categories.map((cat) {
            final color = cat['color'] as Color;
            final pct = cat['pct'] as double;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(cat['icon'] as IconData, color: color, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          cat['name'] as String,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Text(
                        cat['amount'] as String,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 6,
                      backgroundColor: AppTheme.card,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
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
