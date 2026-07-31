import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/services/auth_service.dart';
import '../../catalog/screens/catalog_view.dart';
import '../../contacts/screens/contacts_view.dart';
import '../../daily_tracker/screens/daily_tracker_view.dart';
import '../../dashboard/screens/dashboard_view.dart';
import '../../expenses/screens/expenses_view.dart';
import '../../investment/screens/investment_view.dart';
import '../../lend_borrow/screens/lend_borrow_view.dart';
import '../../loans/screens/loans_view.dart';
import '../../od_account/screens/od_account_view.dart';
import '../../receipt_scan/screens/receipt_scan_view.dart';
import '../../settings/screens/settings_view.dart';

/// Main Application Layout Screen — Responsive Navigation Shell.
///
/// Default tab is 0 (Dashboard).
/// Supports Bottom Navigation Bar for Mobile and Navigation Drawer for all 11 modules.
class MainLayoutScreen extends StatefulWidget {
  final int initialTabIndex;

  const MainLayoutScreen({super.key, this.initialTabIndex = 0});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late int _activeTabIndex;

  @override
  void initState() {
    super.initState();
    _activeTabIndex = widget.initialTabIndex;
  }

  void _onSelectTab(int index) {
    setState(() {
      _activeTabIndex = index;
    });
  }

  String get _activeTitle {
    switch (_activeTabIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Daily Tracker';
      case 2:
        return 'Lend & Borrow';
      case 3:
        return 'Expenses';
      case 4:
        return 'Loans';
      case 5:
        return 'Investment Portfolio';
      case 6:
        return 'OD Account';
      case 7:
        return 'Contact Directory';
      case 8:
        return 'Product Catalog';
      case 9:
        return 'Receipt Scan';
      case 10:
        return 'System Settings';
      default:
        return AppConstants.appName;
    }
  }

  Widget _buildActiveBody() {
    switch (_activeTabIndex) {
      case 0:
        return DashboardView(
          onNavigateTab: (idx) => _onSelectTab(idx),
          onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
        );
      case 1:
        return const DailyTrackerView();
      case 2:
        return const LendBorrowView();
      case 3:
        return const ExpensesView();
      case 4:
        return const LoansView();
      case 5:
        return const InvestmentView();
      case 6:
        return const OdAccountView();
      case 7:
        return const ContactsView();
      case 8:
        return const CatalogView();
      case 9:
        return const ReceiptScanView();
      case 10:
        return const SettingsView();
      default:
        return DashboardView(
          onNavigateTab: (idx) => _onSelectTab(idx),
          onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: Text(_activeTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notifications',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No new notifications')),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),

      // ── Side Navigation Drawer ──────────────────────────────────────
      drawer: _buildNavigationDrawer(context),

      // ── Active Body ────────────────────────────────────────────────
      body: SafeArea(child: _buildActiveBody()),

      // ── Bottom Navigation Bar ──────────────────────────────────────
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _activeTabIndex > 3 ? 4 : _activeTabIndex,
          onTap: (index) {
            if (index == 4) {
              _scaffoldKey.currentState?.openDrawer();
            } else {
              _onSelectTab(index);
            }
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppTheme.primaryTeal,
          unselectedItemColor: AppTheme.textHint,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.today_rounded),
              label: 'Daily Tracker',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.handshake_outlined),
              label: 'Lend & Borrow',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_rounded),
              label: 'Expenses',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_rounded),
              label: 'More',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationDrawer(BuildContext context) {
    final modules = [
      {'index': 0, 'title': 'Dashboard', 'icon': Icons.grid_view_rounded, 'badge': 'Default'},
      {'index': 1, 'title': 'Daily Tracker', 'icon': Icons.today_rounded, 'badge': 'Nav'},
      {'index': 2, 'title': 'Lend & Borrow', 'icon': Icons.handshake_outlined, 'badge': 'Nav'},
      {'index': 3, 'title': 'Expenses', 'icon': Icons.receipt_long_rounded, 'badge': 'Nav'},
      {'index': 4, 'title': 'Loans', 'icon': Icons.account_balance_rounded},
      {'index': 5, 'title': 'Investment Portfolio', 'icon': Icons.show_chart_rounded},
      {'index': 6, 'title': 'OD Account', 'icon': Icons.credit_score_rounded},
      {'index': 7, 'title': 'Contact Directory', 'icon': Icons.contacts_rounded},
      {'index': 8, 'title': 'Product Catalog', 'icon': Icons.inventory_2_rounded},
      {'index': 9, 'title': 'Receipt Scan', 'icon': Icons.qr_code_scanner_rounded},
      {'index': 10, 'title': 'System Settings', 'icon': Icons.settings_rounded},
    ];

    return Drawer(
      backgroundColor: AppTheme.surface,
      child: Column(
        children: [
          // Drawer Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        AppConstants.appName,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        'Financial Management',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Drawer List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: modules.map((m) {
                final idx = m['index'] as int;
                final isSelected = _activeTabIndex == idx;
                final badge = m['badge'] as String?;

                return ListTile(
                  leading: Icon(
                    m['icon'] as IconData,
                    color: isSelected ? AppTheme.primaryTeal : AppTheme.textHint,
                    size: 22,
                  ),
                  title: Text(
                    m['title'] as String,
                    style: TextStyle(
                      color: isSelected ? AppTheme.primaryTeal : AppTheme.textPrimary,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  trailing: badge != null
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryViolet.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              color: AppTheme.primaryTeal,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      : null,
                  selected: isSelected,
                  selectedTileColor: AppTheme.primaryViolet.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  onTap: () {
                    Navigator.of(context).pop(); // Close drawer
                    _onSelectTab(idx);
                  },
                );
              }).toList(),
            ),
          ),

          const Divider(color: Colors.white10),

          // Logout Button
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppTheme.error, size: 22),
            title: const Text('Sign Out', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.w600, fontSize: 14)),
            onTap: () async {
              await AuthService.instance.logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed(AppConstants.routeLogin);
              }
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
