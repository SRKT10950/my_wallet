import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/layout/responsive_layout.dart';
import '../providers/finance_provider.dart';
import '../widgets/dashboard/quick_actions_bar.dart';
import 'accounts_screen.dart';
import 'sms_parser_screen.dart';
import 'daily_tracker_screen.dart';
import 'contacts_screen.dart';
import 'loans_screen.dart';

class DashboardScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;
  const DashboardScreen({super.key, this.onNavigateTab});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}


class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  late AnimationController _shimmerController;
  late AnimationController _staggerController;
  late List<Animation<Offset>> _cardSlides;
  late List<Animation<double>> _cardFades;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat();
    _staggerController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));

    // 4 metric cards staggered slide-in
    _cardSlides = List.generate(4, (i) {
      final start = i * 0.15;
      return Tween<Offset>(begin: const Offset(0, 0.35), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval(start, (start + 0.5).clamp(0, 1), curve: Curves.easeOutCubic),
        ),
      );
    });
    _cardFades = List.generate(4, (i) {
      final start = i * 0.15;
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval(start, (start + 0.5).clamp(0, 1), curve: Curves.easeOut),
        ),
      );
    });
    _staggerController.forward();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final curSymbol = provider.defaultCurrency;
    final periodEnd = DateTime(_selectedYear, _selectedMonth + 1, 0, 23, 59, 59);

    final expenditure = provider.getMonthlyExpenditure(_selectedMonth, _selectedYear);
    final emi = provider.getTotalEMIForPeriod(_selectedMonth, _selectedYear);
    final netWalletBalance = provider.getTotalWalletBalance(upToDate: periodEnd);
    final activeLoans = provider.getActiveLoansForPeriod(_selectedMonth, _selectedYear);
    final pendingLoan = activeLoans.fold(0.0, (sum, l) => sum + l.balance);
    final netWorth = provider.getNetWorthForPeriod(_selectedMonth, _selectedYear);
    final totalInvestments = provider.getTotalCurrentInvestmentsForPeriod(_selectedMonth, _selectedYear);
    final portfolioValue = provider.getTotalPortfolioValue(upToDate: periodEnd);

    final upcomingBills = provider.scheduledPayments.where((b) {
      final due = DateTime.parse(b.nextDueDate);
      return b.active && (due.isBefore(DateTime.now().add(const Duration(days: 7))));
    }).toList();

    final recentTxList = provider.allTransactions.take(6).toList();

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Sticky header ──────────────────────────────────────
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyHeaderDelegate(
                selectedMonth: _selectedMonth,
                selectedYear: _selectedYear,
                isDark: isDark,
                onMonthChanged: (val) => setState(() => _selectedMonth = val),
                onYearChanged: (val) => setState(() => _selectedYear = val),
                provider: provider,
              ),
            ),

            // ── Body content ───────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 18),

                  // ── Aurora Hero Card ─────────────────────────────
                  _AuroraHeroCard(
                    shimmerController: _shimmerController,
                    curSymbol: curSymbol,
                    netWorth: netWorth,
                    netWalletBalance: netWalletBalance,
                    portfolioValue: portfolioValue,
                    pendingLoan: pendingLoan,
                  ),

                  const SizedBox(height: 20),

                  // ── Quick Actions ────────────────────────────────
                  QuickActionsBar(
                    onAddExpense: () {
                      if (widget.onNavigateTab != null) {
                        widget.onNavigateTab!(1);
                      } else {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyTrackerScreen()));
                      }
                    },
                    onAddIncome: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SmsParserScreen())),
                    onAddLoan: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoansScreen())),
                    onAddCustomer: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactsScreen())),
                    onTransfer: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountsScreen())),
                  ),


                  const SizedBox(height: 22),

                  // ── Section label ────────────────────────────────
                  _SectionLabel(label: 'FINANCIAL OVERVIEW'),
                  const SizedBox(height: 14),

                  // ── Staggered Metric Cards ───────────────────────
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: AppBreakpoints.getGridColumnCount(context),
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 1.55,
                    children: [
                      _AnimatedMetricCard(
                        slideAnim: _cardSlides[0],
                        fadeAnim: _cardFades[0],
                        title: 'Monthly Spending',
                        amount: '$curSymbol${expenditure.toStringAsFixed(0)}',
                        subtitle: 'Spent this period',
                        icon: Icons.shopping_bag_outlined,
                        color: AppColors.rose,
                        isDark: isDark,
                      ),
                      _AnimatedMetricCard(
                        slideAnim: _cardSlides[1],
                        fadeAnim: _cardFades[1],
                        title: 'Asset Portfolio',
                        amount: '$curSymbol${totalInvestments.toStringAsFixed(0)}',
                        subtitle: 'Growth portfolio',
                        icon: Icons.trending_up_rounded,
                        color: AppColors.emerald,
                        isDark: isDark,
                      ),
                      _AnimatedMetricCard(
                        slideAnim: _cardSlides[2],
                        fadeAnim: _cardFades[2],
                        title: 'Monthly EMIs',
                        amount: '$curSymbol${emi.toStringAsFixed(0)}',
                        subtitle: '${activeLoans.length} active loans',
                        icon: Icons.credit_card_outlined,
                        color: AppColors.primary,
                        isDark: isDark,
                      ),
                      _AnimatedMetricCard(
                        slideAnim: _cardSlides[3],
                        fadeAnim: _cardFades[3],
                        title: 'Scheduled Bills',
                        amount: '${upcomingBills.length} Due',
                        subtitle: 'Next 7 days',
                        icon: Icons.event_note_rounded,
                        color: AppColors.amber,
                        isDark: isDark,
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // ── Recent Transactions ──────────────────────────
                  _SectionLabel(label: 'RECENT ACTIVITY'),
                  const SizedBox(height: 14),
                  _RecentTransactionsFeed(
                    recentTxList: recentTxList,
                    curSymbol: curSymbol,
                    isDark: isDark,
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sticky Header ──────────────────────────────────────────────────────────────
class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final int selectedMonth;
  final int selectedYear;
  final bool isDark;
  final ValueChanged<int> onMonthChanged;
  final ValueChanged<int> onYearChanged;
  final FinanceProvider provider;

  const _StickyHeaderDelegate({
    required this.selectedMonth,
    required this.selectedYear,
    required this.isDark,
    required this.onMonthChanged,
    required this.onYearChanged,
    required this.provider,
  });

  @override
  double get minExtent => 72;
  @override
  double get maxExtent => 72;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final userName = provider.currentUserName ?? 'User';
    final firstName = userName.split(' ').first;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkBackground.withValues(alpha: 0.96)
            : AppColors.lightBackground.withValues(alpha: 0.96),
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder.withValues(alpha: 0.5) : AppColors.lightBorder,
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            // Greeting
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _greeting(),
                    style: TextStyle(
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    firstName,
                    style: TextStyle(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),

            // Month/Year pickers
            _PeriodPicker(
              selectedMonth: selectedMonth,
              selectedYear: selectedYear,
              isDark: isDark,
              onMonthChanged: onMonthChanged,
              onYearChanged: onYearChanged,
            ),

            const SizedBox(width: 12),

            // Avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning ☀️';
    if (hour < 17) return 'Good Afternoon 🌤️';
    return 'Good Evening 🌙';
  }

  @override
  bool shouldRebuild(_StickyHeaderDelegate old) =>
      old.selectedMonth != selectedMonth ||
      old.selectedYear != selectedYear ||
      old.isDark != isDark;
}

// ── Period Picker ──────────────────────────────────────────────────────────────
class _PeriodPicker extends StatelessWidget {
  final int selectedMonth;
  final int selectedYear;
  final bool isDark;
  final ValueChanged<int> onMonthChanged;
  final ValueChanged<int> onYearChanged;

  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  const _PeriodPicker({
    required this.selectedMonth,
    required this.selectedYear,
    required this.isDark,
    required this.onMonthChanged,
    required this.onYearChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _DropPill<int>(
          value: selectedMonth,
          isDark: isDark,
          items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text(_months[i]))),
          onChanged: (v) => onMonthChanged(v!),
        ),
        const SizedBox(width: 6),
        _DropPill<int>(
          value: selectedYear,
          isDark: isDark,
          items: List.generate(10, (i) {
            final y = DateTime.now().year - 5 + i;
            return DropdownMenuItem(value: y, child: Text('$y'));
          }),
          onChanged: (v) => onYearChanged(v!),
        ),
      ],
    );
  }
}

class _DropPill<T> extends StatelessWidget {
  final T value;
  final bool isDark;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _DropPill({required this.value, required this.isDark, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16),
          dropdownColor: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurface,
          items: items,
          onChanged: onChanged,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
      ),
    );
  }
}

// ── Aurora Hero Card ───────────────────────────────────────────────────────────
class _AuroraHeroCard extends StatelessWidget {
  final AnimationController shimmerController;
  final String curSymbol;
  final double netWorth;
  final double netWalletBalance;
  final double portfolioValue;
  final double pendingLoan;

  const _AuroraHeroCard({
    required this.shimmerController,
    required this.curSymbol,
    required this.netWorth,
    required this.netWalletBalance,
    required this.portfolioValue,
    required this.pendingLoan,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: shimmerController,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              colors: [Color(0xFF3730A3), Color(0xFF6366F1), Color(0xFF7C3AED)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withValues(alpha: 0.40),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Shimmer sweep
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Align(
                    alignment: Alignment(-1.5 + shimmerController.value * 3.5, 0),
                    child: Container(
                      width: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.0),
                            Colors.white.withValues(alpha: 0.07),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Background watermark icon
              Positioned(
                right: -20,
                bottom: -30,
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 160,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),

              // Content
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: const Text(
                          'TOTAL NET WORTH',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: const Icon(Icons.nfc_rounded, color: Colors.white70, size: 18),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  Text(
                    '$curSymbol${netWorth.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.5,
                      height: 1.0,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Stats row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _HeroStat(
                          label: 'Wallets',
                          value: '$curSymbol${netWalletBalance.toStringAsFixed(0)}',
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        _HeroDivider(),
                        const SizedBox(width: 4),
                        _HeroStat(
                          label: 'Assets',
                          value: '$curSymbol${portfolioValue.toStringAsFixed(0)}',
                          color: const Color(0xFF6EE7B7),
                        ),
                        if (pendingLoan > 0) ...[
                          const SizedBox(width: 4),
                          _HeroDivider(),
                          const SizedBox(width: 4),
                          _HeroStat(
                            label: 'Loans',
                            value: '$curSymbol${pendingLoan.toStringAsFixed(0)}',
                            color: const Color(0xFFFCA5A5),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _HeroStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 10, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _HeroDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: Colors.white.withValues(alpha: 0.2),
    );
  }
}

// ── Section Label ──────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}

// ── Animated Metric Card ───────────────────────────────────────────────────────
class _AnimatedMetricCard extends StatelessWidget {
  final Animation<Offset> slideAnim;
  final Animation<double> fadeAnim;
  final String title;
  final String amount;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _AnimatedMetricCard({
    required this.slideAnim,
    required this.fadeAnim,
    required this.title,
    required this.amount,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnim,
      child: SlideTransition(
        position: slideAnim,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        letterSpacing: 0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 16),
                  ),
                ],
              ),
              Text(
                amount,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.w700,
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

// ── Recent Transactions Feed ───────────────────────────────────────────────────
class _RecentTransactionsFeed extends StatelessWidget {
  final List recentTxList;
  final String curSymbol;
  final bool isDark;

  const _RecentTransactionsFeed({
    required this.recentTxList,
    required this.curSymbol,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Transactions',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              AppStatusBadge.paid(label: 'Live Sync'),
            ],
          ),
          const SizedBox(height: 16),
          if (recentTxList.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Icon(Icons.receipt_long_outlined,
                        size: 40, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                    const SizedBox(height: 10),
                    Text(
                      'No transactions this period',
                      style: TextStyle(
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...recentTxList.asMap().entries.map((entry) {
              final i = entry.key;
              final tx = entry.value;
              return _TxRow(tx: tx, curSymbol: curSymbol, isDark: isDark, isLast: i == recentTxList.length - 1);
            }),
        ],
      ),
    );
  }
}

class _TxRow extends StatelessWidget {
  final dynamic tx;
  final String curSymbol;
  final bool isDark;
  final bool isLast;

  const _TxRow({required this.tx, required this.curSymbol, required this.isDark, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.rose.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.rose.withValues(alpha: 0.2)),
                ),
                child: const Center(
                  child: Icon(Icons.arrow_upward_rounded, color: AppColors.rose, size: 18),
                ),
              ),
              const SizedBox(width: 14),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.itemService,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tx.merchantName.isNotEmpty ? tx.merchantName : tx.date,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
              // Amount + status
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '− $curSymbol${tx.cost.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: AppColors.rose,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AppStatusBadge.paid(label: tx.cleared ? 'Cleared' : 'Pending'),
                ],
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            color: isDark ? AppColors.darkBorder.withValues(alpha: 0.5) : AppColors.lightBorder,
          ),
      ],
    );
  }
}
