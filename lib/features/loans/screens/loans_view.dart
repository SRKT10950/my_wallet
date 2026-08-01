import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Loans View — active loans, EMI due dates, EMI calculator.
class LoansView extends StatelessWidget {
  const LoansView({super.key});

  @override
  Widget build(BuildContext context) {
    final loans = [
      {
        'title': 'HDFC Home Loan',
        'principal': '₹ 35,00,000',
        'emi': '₹ 28,450 / mo',
        'dueDate': '05 Aug 2026',
        'progress': 0.35,
        'paid': '₹ 12.25 L',
      },
      {
        'title': 'ICICI Car Loan',
        'principal': '₹ 8,00,000',
        'emi': '₹ 14,200 / mo',
        'dueDate': '10 Aug 2026',
        'progress': 0.60,
        'paid': '₹ 4.80 L',
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Active Loan Summary
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.card, AppTheme.surface],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Total Outstanding Loan Principal',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                SizedBox(height: 6),
                Text('₹ 43,00,000',
                    style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 30,
                        fontWeight: FontWeight.w800)),
                SizedBox(height: 12),
                Text('Total Monthly EMI: ₹ 42,650 / mo',
                    style: TextStyle(color: AppTheme.primaryTeal, fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const Text('Active Loan Accounts',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 14),

          ...loans.map((loan) {
            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(loan['title'] as String,
                          style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryViolet.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('Due ${loan['dueDate']}',
                            style: const TextStyle(color: AppTheme.primaryTeal, fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Principal: ${loan['principal']}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                      Text('EMI: ${loan['emi']}', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: loan['progress'] as double,
                      minHeight: 8,
                      backgroundColor: AppTheme.card,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryViolet),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Paid: ${loan['paid']}', style: const TextStyle(color: AppTheme.textHint, fontSize: 12)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
