import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/layout/responsive_layout.dart';
import '../providers/finance_provider.dart';
import 'dashboard_screen.dart';
import 'daily_tracker_screen.dart';
import 'expense_tracker_screen.dart';
import 'more_screen.dart';
import 'receipt_scanner_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _requestNotificationPermission();
  }

  Future<void> _requestNotificationPermission() async {
    final status = await Permission.notification.status;
    if (!status.isGranted) {
      await Permission.notification.request();
    }
  }

  void _changeTab(int index) {
    // Pop any open pushed routes so tab switching always displays cleanly
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
    setState(() {
      _currentIndex = index;
    });
  }

  final List<NavigationItem> _navItems = const [
    NavigationItem(
      label: 'Overview',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
    ),
    NavigationItem(
      label: 'Tracker',
      icon: Icons.track_changes_outlined,
      selectedIcon: Icons.track_changes,
    ),
    NavigationItem(
      label: 'Receipt Scan',
      icon: Icons.document_scanner_outlined,
      selectedIcon: Icons.document_scanner_rounded,
    ),
    NavigationItem(
      label: 'Expenses',
      icon: Icons.pie_chart_outline,
      selectedIcon: Icons.pie_chart,
    ),
    NavigationItem(
      label: 'More',
      icon: Icons.more_horiz_outlined,
      selectedIcon: Icons.more_horiz,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);

    final List<Widget> screens = [
      DashboardScreen(onNavigateTab: _changeTab),
      const DailyTrackerScreen(),
      const ReceiptScannerScreen(),
      const ExpenseTrackerScreen(),
      const MoreScreen(),
    ];

    // Shortcuts for D-Pad / Smart TV and Keyboard arrow navigation
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.arrowLeft): const _PrevTabIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowRight): const _NextTabIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _PrevTabIntent: CallbackAction<_PrevTabIntent>(
            onInvoke: (intent) => _changeTab((_currentIndex - 1 + screens.length) % screens.length),
          ),
          _NextTabIntent: CallbackAction<_NextTabIntent>(
            onInvoke: (intent) => _changeTab((_currentIndex + 1) % screens.length),
          ),
        },
        child: Focus(
          autofocus: true,
          child: ResponsiveLayout(
            currentIndex: _currentIndex,
            onIndexChanged: _changeTab,
            items: _navItems,
            screens: screens,
            userName: provider.currentUserName ?? provider.currentUserId ?? 'User',
            onLogout: () => provider.logout(),
          ),
        ),
      ),
    );
  }
}

class _PrevTabIntent extends Intent {
  const _PrevTabIntent();
}

class _NextTabIntent extends Intent {
  const _NextTabIntent();
}
