import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Investment View — portfolio overview, stocks, mutual funds, returns.
class InvestmentView extends StatelessWidget {
  const InvestmentView({super.key});

  @override
  Widget build(BuildContext context) {
    final portfolio = [
      {'type': 'Mutual Funds', 'value': '₹ 3,45,000', 'returns': '+14.2%', 'icon': Icons.show_chart_rounded, 'color': AppTheme.success},
      {'type': 'Indian Stocks', 'value': '₹ 2,10,000', 'returns': '+18.5%', 'icon': Icons.candlestick_chart_rounded, 'color': AppTheme.primaryTeal},
      {'type': 'Fixed Deposit (FD)', 'value': '₹ 1,50,000', 'returns': '+7.1%', 'icon': Icons.lock_clock_rounded, 'color': AppTheme.primaryViolet},
      {'type': 'Digital Gold', 'value': '₹ 65,000', 'returns': '+9.8%', 'icon': Icons.monetization_on_rounded, 'color': AppTheme.accentGold},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Portfolio Total
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Total Investment Portfolio', style: TextStyle(color: Colors.white70, fontSize: 13)),
                SizedBox(height: 6),
                Text('₹ 7,70,000.00', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800)),
                SizedBox(height: 12),
                Text('Overall Returns: +₹ 1,02,400 (+15.3%)', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const Text('Asset Class Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 14),

          ...portfolio.map((item) {
            final color = item['color'] as Color;
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
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
                    child: Icon(item['icon'] as IconData, color: color, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['type'] as String, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
                        const SizedBox(height: 2),
                        Text('Current Value: ${item['value']}', style: const TextStyle(color: AppTheme.textHint, fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppTheme.success.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                    child: Text(item['returns'] as String, style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.w700, fontSize: 13)),
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
