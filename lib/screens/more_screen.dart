import 'package:flutter/material.dart';
import 'loans_screen.dart';
import 'investments_screen.dart';
import 'lend_borrow_screen.dart';
import 'settings_screen.dart';
import 'od_accounts_screen.dart';
import 'accounts_screen.dart';
import 'scheduled_payments_screen.dart';
import 'goals_screen.dart';
import 'assets_screen.dart';
import 'sms_parser_screen.dart';
import 'splitwise_screen.dart';
import 'calculators_screen.dart';
import 'receipt_scanner_screen.dart';
import 'fuel_log_screen.dart';
import 'car_dashboard_screen.dart';
import 'deleted_records_screen.dart';
import 'contacts_screen.dart';
import 'products_screen.dart';
import '../providers/finance_provider.dart';
import 'package:provider/provider.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);
    final curSymbol = provider.defaultCurrency;
    final double screenWidth = MediaQuery.of(context).size.width;
    final int crossAxisCount = screenWidth >= 1024 ? 4 : (screenWidth >= 600 ? 3 : 2);
    final double childAspectRatio = screenWidth >= 1024 ? 1.4 : (screenWidth >= 600 ? 1.3 : 1.25);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Menu & Controls',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, letterSpacing: -0.5),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF080914), Color(0xFF0E111F)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [

                    // Financial Management Section
                    const Padding(
                      padding: EdgeInsets.only(left: 8.0, bottom: 12, top: 12),
                      child: Text(
                        'FINANCIAL MANAGEMENT',
                        style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                      ),
                    ),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: childAspectRatio,
                      children: [
                        _buildMenuCard(
                          context: context,
                          title: 'Loans',
                          sub: '${provider.loans.where((l) => l.status == 'Active').length} Active',
                          icon: Icons.account_balance,
                          color: Colors.orangeAccent,
                          destination: const LoansScreen(),
                        ),
                        _buildMenuCard(
                          context: context,
                          title: 'Investments',
                          sub: 'Value: $curSymbol${provider.totalCurrentInvestments.toStringAsFixed(0)}',
                          icon: Icons.trending_up,
                          color: Colors.greenAccent,
                          destination: const InvestmentsScreen(),
                        ),
                        _buildMenuCard(
                          context: context,
                          title: 'Lend & Borrow',
                          sub: 'Dues Tracker',
                          icon: Icons.compare_arrows,
                          color: Colors.blueAccent,
                          destination: const LendBorrowScreen(),
                        ),
                        _buildMenuCard(
                          context: context,
                          title: 'OD Accounts',
                          sub: '${provider.odAccounts.length} Accounts',
                          icon: Icons.account_balance_wallet,
                          color: Colors.cyanAccent,
                          destination: const OdAccountsScreen(),
                        ),
                        _buildMenuCard(
                          context: context,
                          title: 'Contacts Directory',
                          sub: '${provider.contacts.where((c) => c.active).length} Active Contacts',
                          icon: Icons.contacts,
                          color: Colors.tealAccent,
                          destination: const ContactsScreen(),
                        ),
                        _buildMenuCard(
                          context: context,
                          title: 'Product Catalog',
                          sub: '${provider.products.where((p) => p.active).length} Active Items',
                          icon: Icons.inventory_2,
                          color: Colors.amberAccent,
                          destination: const ProductsScreen(),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),

                    // Accounts & Goals Section
                    const Padding(
                      padding: EdgeInsets.only(left: 8.0, bottom: 12),
                      child: Text(
                        'ACCOUNTS & PLANNING',
                        style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                      ),
                    ),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: childAspectRatio,
                      children: [
                        _buildMenuCard(
                          context: context,
                          title: 'Wallet Accounts',
                          sub: '${provider.accounts.length} Wallets',
                          icon: Icons.wallet_rounded,
                          color: const Color(0xFF6366F1),
                          destination: const AccountsScreen(),
                        ),
                        _buildMenuCard(
                          context: context,
                          title: 'Savings Goals',
                          sub: '${provider.goals.length} active goals',
                          icon: Icons.track_changes_rounded,
                          color: const Color(0xFF8B5CF6),
                          destination: const GoalsScreen(),
                        ),
                        _buildMenuCard(
                          context: context,
                          title: 'Scheduled Bills',
                          sub: '${provider.scheduledPayments.length} scheduled',
                          icon: Icons.event_note_rounded,
                          color: Colors.tealAccent,
                          destination: const ScheduledPaymentsScreen(),
                        ),
                        _buildMenuCard(
                          context: context,
                          title: 'Deleted Records',
                          sub: 'Trash & Recovery',
                          icon: Icons.delete_sweep_rounded,
                          color: Colors.redAccent,
                          destination: const DeletedRecordsScreen(),
                        ),
                        _buildMenuCard(
                          context: context,
                          title: 'System Settings',
                          sub: 'Configuration',
                          icon: Icons.settings,
                          color: Colors.grey,
                          destination: const SettingsScreen(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Premium Tools Section
                    const Padding(
                      padding: EdgeInsets.only(left: 8.0, bottom: 12),
                      child: Text(
                        'PREMIUM TOOLS & PORTFOLIO',
                        style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                      ),
                    ),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: childAspectRatio,
                      children: [
                        _buildMenuCard(
                          context: context,
                          title: 'Asset Portfolio',
                          sub: '${provider.assets.length} Assets',
                          icon: Icons.pie_chart_rounded,
                          color: const Color(0xFF10B981),
                          destination: const AssetsScreen(),
                        ),
                        _buildMenuCard(
                          context: context,
                          title: 'Group Splits',
                          sub: '${provider.splitBills.length} Bills Split',
                          icon: Icons.people_alt_rounded,
                          color: const Color(0xFFF59E0B),
                          destination: const SplitwiseScreen(),
                        ),
                        _buildMenuCard(
                          context: context,
                          title: 'Planning Tools',
                          sub: 'FIRE & EMI',
                          icon: Icons.calculate_rounded,
                          color: const Color(0xFF3B82F6),
                          destination: const CalculatorsScreen(),
                        ),
                         _buildMenuCard(
                          context: context,
                          title: 'SMS Inbox Parser',
                          sub: 'Auto-parse bank SMS',
                          icon: Icons.document_scanner_rounded,
                          color: const Color(0xFFEC4899),
                          destination: const SmsParserScreen(),
                        ),
                         _buildMenuCard(
                          context: context,
                          title: 'Receipt Scanner',
                          sub: 'ML Kit OCR',
                          icon: Icons.receipt_long_rounded,
                          color: Colors.cyanAccent,
                          destination: const ReceiptScannerScreen(),
                        ),
                        _buildMenuCard(
                          context: context,
                          title: 'Petrol Log',
                          sub: 'Mileage & Expenses',
                          icon: Icons.local_gas_station_rounded,
                          color: Colors.orangeAccent,
                          destination: const FuelLogScreen(),
                        ),
                        _buildMenuCard(
                          context: context,
                          title: 'Car Sync GPS',
                          sub: 'Odometer & GPS Trips',
                          icon: Icons.directions_car_rounded,
                          color: const Color(0xFF10B981),
                          destination: const CarDashboardScreen(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const UserProfileWidget(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required BuildContext context,
    required String title,
    required String sub,
    required IconData icon,
    required Color color,
    required Widget destination,
  }) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => destination)),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: const Color(0xFF121422),
          border: Border.all(color: color.withValues(alpha: 0.18), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 24, color: color),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    style: const TextStyle(fontSize: 10, color: Colors.white54, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
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

class UserProfileWidget extends StatelessWidget {
  const UserProfileWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121422),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.35)),
            ),
            child: const Icon(Icons.person, color: Color(0xFF6366F1), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.currentUserName ?? 'User',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  provider.currentUserId ?? 'Local User',
                  style: const TextStyle(color: Colors.white30, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.withValues(alpha: 0.15),
              foregroundColor: Colors.redAccent,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.logout, size: 16),
            label: const Text('LOGOUT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFF121422),
                  title: const Text('Logout?'),
                  content: const Text(
                    'This will clear local storage and log you out. Please make sure you have pushed your sync data.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () {
                        provider.logout();
                        Navigator.pop(context);
                      },
                      child: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

