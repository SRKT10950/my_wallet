import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Default screen after login — Dashboard View.
class DashboardView extends StatefulWidget {
  final Function(int)? onNavigateTab;
  final VoidCallback? onOpenDrawer;

  const DashboardView({
    super.key,
    this.onNavigateTab,
    this.onOpenDrawer,
  });

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  bool _isBalanceVisible = true;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Net Worth Balance Card ─────────────────────────────────────
          _buildBalanceCard(context),

          const SizedBox(height: 24),

          // ── Quick Actions Bar ─────────────────────────────────────────
          _buildQuickActions(context),

          const SizedBox(height: 24),

          // ── Monthly Summary Graphs / Progress ────────────────────────
          _buildMonthlySummary(context),

          const SizedBox(height: 24),

          // ── Recent Activity List ─────────────────────────────────────
          _buildRecentActivity(context),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryViolet.withValues(alpha: 0.4),
            blurRadius: 30,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.account_balance_wallet_rounded,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Net Wallet Balance',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(
                  _isBalanceVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _isBalanceVisible = !_isBalanceVisible),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _isBalanceVisible ? '₹ 1,48,520.00' : '••••••••',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCardMetric('Income', '₹ 85,000', Icons.arrow_downward_rounded,
                    AppTheme.success),
                Container(
                    width: 1,
                    height: 30,
                    color: Colors.white.withValues(alpha: 0.2)),
                _buildCardMetric('Expenses', '₹ 36,480', Icons.arrow_upward_rounded,
                    AppTheme.error),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardMetric(
      String label, String amount, IconData icon, Color iconColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 12,
              ),
            ),
            Text(
              _isBalanceVisible ? amount : '••••',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      {'icon': Icons.add_circle_outline_rounded, 'label': 'Add Expense', 'tab': 3},
      {'icon': Icons.today_rounded, 'label': 'Daily Log', 'tab': 1},
      {'icon': Icons.handshake_outlined, 'label': 'Lend/Borrow', 'tab': 2},
      {'icon': Icons.qr_code_scanner_rounded, 'label': 'Scan Receipt', 'tab': -1},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: actions.map((act) {
            return Flexible(
              child: GestureDetector(
                onTap: () {
                  final tabIndex = act['tab'] as int;
                  if (tabIndex >= 0) {
                    widget.onNavigateTab?.call(tabIndex);
                  } else {
                    widget.onOpenDrawer?.call();
                  }
                },
                child: Column(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        act['icon'] as IconData,
                        color: AppTheme.primaryTeal,
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      act['label'] as String,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMonthlySummary(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'July Budget Overview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryViolet.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '43% Spent',
                  style: TextStyle(
                    color: AppTheme.primaryTeal,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: 0.43,
              minHeight: 10,
              backgroundColor: AppTheme.card,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppTheme.primaryViolet),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('₹ 36,480 spent',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              Text('Budget: ₹ 85,000',
                  style: TextStyle(color: AppTheme.textHint, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    final recent = [
      {
        'title': 'Grocery Shopping',
        'subtitle': 'Supermarket • Today',
        'amount': '-₹ 3,450',
        'isExpense': true,
        'icon': Icons.shopping_bag_outlined,
      },
      {
        'title': 'Salary Credit',
        'subtitle': 'Company HR • 28 Jul',
        'amount': '+₹ 85,000',
        'isExpense': false,
        'icon': Icons.account_balance_rounded,
      },
      {
        'title': 'Lent to Rahul',
        'subtitle': 'Friend • 25 Jul',
        'amount': '-₹ 5,000',
        'isExpense': true,
        'icon': Icons.handshake_outlined,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () => widget.onNavigateTab?.call(3),
              child: const Text('See All',
                  style: TextStyle(color: AppTheme.primaryTeal)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...recent.map((tx) {
          final isExp = tx['isExpense'] as bool;
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
                  decoration: BoxDecoration(
                    color: (isExp ? AppTheme.error : AppTheme.success)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    tx['icon'] as IconData,
                    color: isExp ? AppTheme.error : AppTheme.success,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx['title'] as String,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tx['subtitle'] as String,
                        style: const TextStyle(
                          color: AppTheme.textHint,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  tx['amount'] as String,
                  style: TextStyle(
                    color: isExp ? AppTheme.textPrimary : AppTheme.success,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
