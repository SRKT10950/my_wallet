import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// OD Account View — Overdraft limit, utilized amount, interest counter.
class OdAccountView extends StatelessWidget {
  const OdAccountView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.primaryViolet.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('HDFC Overdraft Account', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: AppTheme.success.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                      child: const Text('ACTIVE', style: TextStyle(color: AppTheme.success, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Utilized: ₹ 1,20,000', style: TextStyle(color: AppTheme.error, fontSize: 26, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                const Text('Sanctioned Limit: ₹ 5,00,000', style: TextStyle(color: AppTheme.textHint, fontSize: 13)),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(value: 0.24, minHeight: 8, backgroundColor: AppTheme.card, valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.error)),
                ),
                const SizedBox(height: 12),
                const Text('Available OD Limit: ₹ 3,80,000', style: TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.w700, fontSize: 14)),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Interest Calculator Details', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
                SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Interest Rate (p.a.)', style: TextStyle(color: AppTheme.textSecondary)), Text('10.5%', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600))]),
                SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Accrued Interest (This Month)', style: TextStyle(color: AppTheme.textSecondary)), Text('₹ 1,050', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.w600))]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
