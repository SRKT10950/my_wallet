import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class QuickActionsBar extends StatelessWidget {
  final VoidCallback? onAddExpense;
  final VoidCallback? onAddIncome;
  final VoidCallback? onAddLoan;
  final VoidCallback? onAddCustomer;
  final VoidCallback? onTransfer;
  final VoidCallback? onExportData;

  const QuickActionsBar({
    super.key,
    this.onAddExpense,
    this.onAddIncome,
    this.onAddLoan,
    this.onAddCustomer,
    this.onTransfer,
    this.onExportData,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          _ActionPill(
            icon: Icons.add_rounded,
            label: 'Expense',
            color: AppColors.rose,
            gradient: const LinearGradient(colors: [Color(0xFFE11D48), Color(0xFFF43F5E)]),
            isDark: isDark,
            onTap: onAddExpense,
          ),
          const SizedBox(width: 10),
          _ActionPill(
            icon: Icons.arrow_downward_rounded,
            label: 'Income',
            color: AppColors.emerald,
            gradient: const LinearGradient(colors: [Color(0xFF059669), Color(0xFF10B981)]),
            isDark: isDark,
            onTap: onAddIncome,
          ),
          const SizedBox(width: 10),
          _ActionPill(
            icon: Icons.account_balance_outlined,
            label: 'Loan',
            color: AppColors.primary,
            gradient: const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF6366F1)]),
            isDark: isDark,
            onTap: onAddLoan,
          ),
          const SizedBox(width: 10),
          _ActionPill(
            icon: Icons.person_add_outlined,
            label: 'Customer',
            color: AppColors.secondary,
            gradient: const LinearGradient(colors: [Color(0xFF0891B2), Color(0xFF06B6D4)]),
            isDark: isDark,
            onTap: onAddCustomer,
          ),
          const SizedBox(width: 10),
          _ActionPill(
            icon: Icons.swap_horiz_rounded,
            label: 'Transfer',
            color: AppColors.amber,
            gradient: const LinearGradient(colors: [Color(0xFFD97706), Color(0xFFF59E0B)]),
            isDark: isDark,
            onTap: onTransfer,
          ),
          const SizedBox(width: 10),
          _ActionPill(
            icon: Icons.file_download_outlined,
            label: 'Export',
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF334155), const Color(0xFF475569)]
                  : [const Color(0xFF94A3B8), const Color(0xFFCBD5E1)],
            ),
            isDark: isDark,
            onTap: onExportData,
          ),
        ],
      ),
    );
  }
}

// ── Action Pill ────────────────────────────────────────────────────────────────
class _ActionPill extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final LinearGradient gradient;
  final bool isDark;
  final VoidCallback? onTap;

  const _ActionPill({
    required this.icon,
    required this.label,
    required this.color,
    required this.gradient,
    required this.isDark,
    this.onTap,
  });

  @override
  State<_ActionPill> createState() => _ActionPillState();
}

class _ActionPillState extends State<_ActionPill> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) {
          _controller.reverse();
          widget.onTap?.call();
        },
        onTapCancel: () => _controller.reverse(),
        child: ScaleTransition(
          scale: _scaleAnim,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              color: widget.isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _isHovered
                    ? widget.color.withValues(alpha: 0.5)
                    : (widget.isDark ? AppColors.darkBorder : AppColors.lightBorder),
                width: _isHovered ? 1.5 : 1.0,
              ),
              boxShadow: _isHovered
                  ? [BoxShadow(color: widget.color.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4))]
                  : [BoxShadow(
                      color: widget.isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Gradient icon badge
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: widget.gradient,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: _isHovered
                        ? [BoxShadow(color: widget.color.withValues(alpha: 0.4), blurRadius: 8)]
                        : [],
                  ),
                  child: Icon(widget.icon, color: Colors.white, size: 17),
                ),
                const SizedBox(width: 10),
                Text(
                  widget.label,
                  style: TextStyle(
                    color: widget.isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(width: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
