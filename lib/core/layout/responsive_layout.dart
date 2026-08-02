import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import '../../widgets/search_modal.dart';

enum DeviceType {
  miniMobile, // < 360px
  mobile,     // 360 - 600px
  tablet,     // 600 - 900px
  laptop,     // 900 - 1400px
  tv,         // > 1400px (Smart TV / Ultra-wide Desktop)
}

class AppBreakpoints {
  static DeviceType getDeviceType(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    if (width < 360) return DeviceType.miniMobile;
    if (width < 600) return DeviceType.mobile;
    if (width < 900) return DeviceType.tablet;
    if (width < 1400) return DeviceType.laptop;
    return DeviceType.tv;
  }

  static int getGridColumnCount(BuildContext context) {
    switch (getDeviceType(context)) {
      case DeviceType.miniMobile:
      case DeviceType.mobile:
        return 1;
      case DeviceType.tablet:
        return 2;
      case DeviceType.laptop:
        return 3;
      case DeviceType.tv:
        return 4;
    }
  }
}

class NavigationItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String group;

  const NavigationItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    this.group = 'MAIN',
  });
}

class ResponsiveLayout extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;
  final List<NavigationItem> items;
  final List<Widget> screens;
  final String? userName;
  final VoidCallback? onLogout;

  const ResponsiveLayout({
    super.key,
    required this.currentIndex,
    required this.onIndexChanged,
    required this.items,
    required this.screens,
    this.userName,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final deviceType = AppBreakpoints.getDeviceType(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Top Header Widget
    Widget headerBar = Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          // Breadcrumb Path
          Row(
            children: [
              const Icon(Icons.grid_view_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                items[currentIndex < items.length ? currentIndex : 0].label,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const Spacer(),
          // Global Search Cmd+K Button
          GestureDetector(
            onTap: () => GlobalSearchModal.show(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Search anything...',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white12 : Colors.black12,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '⌘K',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Theme Switcher Button
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode ? Icons.wb_sunny_outlined : Icons.dark_mode_outlined,
              color: AppColors.primary,
            ),
            tooltip: 'Toggle Light/Dark Theme',
            onPressed: () => themeProvider.toggleTheme(),
          ),
          // Notification Bell
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {},
              ),
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.rose,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (deviceType == DeviceType.miniMobile || deviceType == DeviceType.mobile) {
      return Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              headerBar,
              Expanded(
                child: IndexedStack(
                  index: currentIndex < screens.length ? currentIndex : 0,
                  children: screens,
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _MobileBottomNavTray(
          currentIndex: currentIndex,
          items: items,
          onIndexChanged: onIndexChanged,
        ),
      );
    }

    if (deviceType == DeviceType.tablet) {
      return Scaffold(
        body: Column(
          children: [
            headerBar,
            Expanded(
              child: Row(
                children: [
                  NavigationRail(
                    selectedIndex: currentIndex,
                    onDestinationSelected: onIndexChanged,
                    backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    indicatorColor: AppColors.primary.withValues(alpha: 0.2),
                    selectedIconTheme: const IconThemeData(color: AppColors.primary, size: 24),
                    unselectedIconTheme: IconThemeData(
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      size: 22,
                    ),
                    labelType: NavigationRailLabelType.selected,
                    destinations: items
                        .map((item) => NavigationRailDestination(
                              icon: Icon(item.icon),
                              selectedIcon: Icon(item.selectedIcon),
                              label: Text(item.label, style: const TextStyle(fontWeight: FontWeight.bold)),
                            ))
                        .toList(),
                  ),
                  const VerticalDivider(width: 1, thickness: 1),
                  Expanded(
  child: IndexedStack(
    index: currentIndex < screens.length ? currentIndex : 0,
    children: screens,
  ),
),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Laptop, Desktop, and Smart TV layout
    return Scaffold(
      body: Column(
        children: [
          headerBar,
          Expanded(
            child: Row(
              children: [
                // Grouped Sidebar
                Container(
                  width: deviceType == DeviceType.tv ? 300 : 250,
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      // Workspace Branding Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.wallet, color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'mWallet',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  deviceType == DeviceType.tv ? 'Smart TV Edition' : 'Enterprise Edition',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 18.0),
                        child: Text(
                          'FINANCIAL SUITE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: AppColors.darkTextMuted,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Navigation List
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          itemCount: items.length,
                          itemBuilder: (context, idx) {
                            final item = items[idx];
                            final isSelected = idx == currentIndex;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3.0),
                              child: Material(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () => onIndexChanged(idx),
                                  hoverColor: AppColors.primary.withValues(alpha: 0.1),
                                  focusColor: AppColors.primary.withValues(alpha: 0.25),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.primary.withValues(alpha: 0.16)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                      border: isSelected
                                          ? Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1)
                                          : null,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isSelected ? item.selectedIcon : item.icon,
                                          color: isSelected
                                              ? AppColors.primary
                                              : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          item.label,
                                          style: TextStyle(
                                            color: isSelected
                                                ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
                                                : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                            fontSize: 13.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      // User Footer Profile
                      if (userName != null)
                        Container(
                          margin: const EdgeInsets.all(12),
                          padding: const EdgeInsets.all(10),
                          decoration: AppGlassDecoration.card(
                            context,
                            color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: AppColors.primary,
                                child: Text(
                                  userName!.isNotEmpty ? userName![0].toUpperCase() : 'U',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      userName!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                    const Text(
                                      'Enterprise Sync Active',
                                      style: TextStyle(fontSize: 9.5, color: AppColors.emerald, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              if (onLogout != null)
                                IconButton(
                                  icon: const Icon(Icons.logout, size: 16, color: AppColors.darkTextMuted),
                                  onPressed: onLogout,
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(
  child: IndexedStack(
    index: currentIndex < screens.length ? currentIndex : 0,
    children: screens,
  ),
),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileBottomNavTray extends StatelessWidget {
  final int currentIndex;
  final List<NavigationItem> items;
  final ValueChanged<int> onIndexChanged;

  const _MobileBottomNavTray({
    required this.currentIndex,
    required this.items,
    required this.onIndexChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    // On iPhone, bottomInset is typically ~34px for home bar indicator.
    final double safeBottomPadding = math.max(bottomInset, 20.0);

    return Container(
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: 6,
        bottom: safeBottomPadding,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0E111F).withValues(alpha: 0.96) : Colors.white.withValues(alpha: 0.96),
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.asMap().entries.map((entry) {
          final int idx = entry.key;
          final item = entry.value;
          final bool isSelected = idx == currentIndex;

          return Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onIndexChanged(idx),
                borderRadius: BorderRadius.circular(16),
                splashColor: AppColors.primary.withValues(alpha: 0.15),
                highlightColor: AppColors.primary.withValues(alpha: 0.08),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.18)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          isSelected ? item.selectedIcon : item.icon,
                          size: 22,
                          color: isSelected
                              ? AppColors.primary
                              : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? AppColors.primary
                              : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

