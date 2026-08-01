import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';

class DeletedRecordsScreen extends StatefulWidget {
  const DeletedRecordsScreen({super.key});

  @override
  State<DeletedRecordsScreen> createState() => _DeletedRecordsScreenState();
}

class _DeletedRecordsScreenState extends State<DeletedRecordsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _categories = [
    'Transactions',
    'Categories',
    'Loans',
    'Income Configs',
    'Lend / Borrow',
    'Repayments',
    'Investments',
    'OD Accounts',
    'OD Transactions',
    'Accounts',
    'Scheduled',
    'Goals',
    'Assets',
    'Split Bills',
    'Fuel Logs',
    'Car Trips',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleRecover(Future<void> Function() recoverFn, String message) async {
    final messenger = ScaffoldMessenger.of(context);
    await recoverFn();
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<FinanceProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Deleted Records'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _categories.map((cat) => Tab(text: cat)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTransactionsTab(provider, theme),
          _buildCategoriesTab(provider, theme),
          _buildLoansTab(provider, theme),
          _buildIncomeConfigsTab(provider, theme),
          _buildLendBorrowsTab(provider, theme),
          _buildRepaymentsTab(provider, theme),
          _buildInvestmentsTab(provider, theme),
          _buildOdAccountsTab(provider, theme),
          _buildOdTransactionsTab(provider, theme),
          _buildAccountsTab(provider, theme),
          _buildScheduledPaymentsTab(provider, theme),
          _buildGoalsTab(provider, theme),
          _buildAssetsTab(provider, theme),
          _buildSplitBillsTab(provider, theme),
          _buildFuelLogsTab(provider, theme),
          _buildCarTripsTab(provider, theme),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String name) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.delete_outline, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No deleted $name',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordItem({
    required String title,
    required String subtitle,
    required String trailing,
    required bool isDeleted,
    required VoidCallback onRecover,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Checkbox(
          value: isDeleted,
          onChanged: (bool? checked) {
            if (checked == false) {
              onRecover();
            }
          },
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailing.isNotEmpty)
              Text(
                trailing,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: onRecover,
              icon: const Icon(Icons.restore, size: 18),
              label: const Text('Recover'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsTab(FinanceProvider provider, ThemeData theme) {
    final list = provider.deletedTransactions;
    if (list.isEmpty) return _buildEmptyState('Transactions');

    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        return _buildRecordItem(
          title: item.itemService.isNotEmpty ? item.itemService : 'Transaction #${item.id}',
          subtitle: '${item.transactionType} • ${item.date}',
          trailing: '${provider.defaultCurrency}${item.cost.toStringAsFixed(2)}',
          isDeleted: item.deleted,
          onRecover: () => _handleRecover(
            () => provider.recoverTransaction(item.id!),
            'Transaction recovered successfully',
          ),
        );
      },
    );
  }

  Widget _buildCategoriesTab(FinanceProvider provider, ThemeData theme) {
    final list = provider.deletedCategories;
    if (list.isEmpty) return _buildEmptyState('Categories');

    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        return _buildRecordItem(
          title: item.name,
          subtitle: 'Planned: ${provider.defaultCurrency}${item.plannedAmount.toStringAsFixed(2)}',
          trailing: '',
          isDeleted: item.deleted,
          onRecover: () => _handleRecover(
            () => provider.recoverCategory(item.id!),
            'Category recovered successfully',
          ),
        );
      },
    );
  }

  Widget _buildLoansTab(FinanceProvider provider, ThemeData theme) {
    final list = provider.deletedLoans;
    if (list.isEmpty) return _buildEmptyState('Loans');

    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        return _buildRecordItem(
          title: item.lender,
          subtitle: 'Principal: ${provider.defaultCurrency}${item.principal.toStringAsFixed(2)} • EMI: ${provider.defaultCurrency}${item.emi.toStringAsFixed(2)}',
          trailing: item.status,
          isDeleted: item.deleted,
          onRecover: () => _handleRecover(
            () => provider.recoverLoan(item.id!),
            'Loan recovered successfully',
          ),
        );
      },
    );
  }

  Widget _buildIncomeConfigsTab(FinanceProvider provider, ThemeData theme) {
    final list = provider.deletedIncomeConfigs;
    if (list.isEmpty) return _buildEmptyState('Income Configs');

    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        return _buildRecordItem(
          title: 'Income Config (${item.month}/${item.year})',
          subtitle: item.isDefault ? 'Default Config' : 'Monthly Override',
          trailing: '${provider.defaultCurrency}${item.amount.toStringAsFixed(2)}',
          isDeleted: item.deleted,
          onRecover: () => _handleRecover(
            () => provider.recoverIncomeConfig(item.id!),
            'Income Config recovered successfully',
          ),
        );
      },
    );
  }

  Widget _buildLendBorrowsTab(FinanceProvider provider, ThemeData theme) {
    final list = provider.deletedLendBorrows;
    if (list.isEmpty) return _buildEmptyState('Lend/Borrow Records');

    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        return _buildRecordItem(
          title: '${item.name} (${item.type})',
          subtitle: 'Date: ${item.date} • Tenure: ${item.tenure}m',
          trailing: '${provider.defaultCurrency}${item.principal.toStringAsFixed(2)}',
          isDeleted: item.deleted,
          onRecover: () => _handleRecover(
            () => provider.recoverLendBorrow(item.id!),
            'Lend/Borrow record recovered successfully',
          ),
        );
      },
    );
  }

  Widget _buildRepaymentsTab(FinanceProvider provider, ThemeData theme) {
    final list = provider.deletedRepayments;
    if (list.isEmpty) return _buildEmptyState('Repayments');

    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        return _buildRecordItem(
          title: 'Repayment by ${item.name}',
          subtitle: 'Method: ${item.method} • Date: ${item.paymentDate}',
          trailing: '${provider.defaultCurrency}${item.amount.toStringAsFixed(2)}',
          isDeleted: item.deleted,
          onRecover: () => _handleRecover(
            () => provider.recoverRepayment(item.id!),
            'Repayment recovered successfully',
          ),
        );
      },
    );
  }

  Widget _buildInvestmentsTab(FinanceProvider provider, ThemeData theme) {
    final list = provider.deletedInvestments;
    if (list.isEmpty) return _buildEmptyState('Investments');

    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        return _buildRecordItem(
          title: item.name,
          subtitle: 'Type: ${item.type} • ROI: ${item.expectedRoi}%',
          trailing: '${provider.defaultCurrency}${item.amount.toStringAsFixed(2)}',
          isDeleted: item.deleted,
          onRecover: () => _handleRecover(
            () => provider.recoverInvestment(item.id!),
            'Investment recovered successfully',
          ),
        );
      },
    );
  }

  Widget _buildOdAccountsTab(FinanceProvider provider, ThemeData theme) {
    final list = provider.deletedOdAccounts;
    if (list.isEmpty) return _buildEmptyState('OD Accounts');

    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        return _buildRecordItem(
          title: item.name,
          subtitle: 'Limit: ${provider.defaultCurrency}${item.limit.toStringAsFixed(2)} • Rate: ${item.interestRate}%',
          trailing: 'Day ${item.billingDay}',
          isDeleted: item.deleted,
          onRecover: () => _handleRecover(
            () => provider.recoverOdAccount(item.id!),
            'OD Account recovered successfully',
          ),
        );
      },
    );
  }

  Widget _buildOdTransactionsTab(FinanceProvider provider, ThemeData theme) {
    final list = provider.deletedOdTransactions;
    if (list.isEmpty) return _buildEmptyState('OD Transactions');

    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        return _buildRecordItem(
          title: 'OD ${item.type}',
          subtitle: 'Date: ${item.date}',
          trailing: '${provider.defaultCurrency}${item.amount.toStringAsFixed(2)}',
          isDeleted: item.deleted,
          onRecover: () => _handleRecover(
            () => provider.recoverOdTransaction(item.id!),
            'OD Transaction recovered successfully',
          ),
        );
      },
    );
  }

  Widget _buildAccountsTab(FinanceProvider provider, ThemeData theme) {
    final list = provider.deletedAccounts;
    if (list.isEmpty) return _buildEmptyState('Accounts');

    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        return _buildRecordItem(
          title: item.name,
          subtitle: 'Type: ${item.type}',
          trailing: '${item.currencySymbol}${item.initialBalance.toStringAsFixed(2)}',
          isDeleted: item.deleted,
          onRecover: () => _handleRecover(
            () => provider.recoverWalletAccount(item.id!),
            'Account recovered successfully',
          ),
        );
      },
    );
  }

  Widget _buildScheduledPaymentsTab(FinanceProvider provider, ThemeData theme) {
    final list = provider.deletedScheduledPayments;
    if (list.isEmpty) return _buildEmptyState('Scheduled Payments');

    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        return _buildRecordItem(
          title: item.name,
          subtitle: '${item.frequency} • Due: ${item.nextDueDate}',
          trailing: '${provider.defaultCurrency}${item.amount.toStringAsFixed(2)}',
          isDeleted: item.deleted,
          onRecover: () => _handleRecover(
            () => provider.recoverScheduledPayment(item.id!),
            'Scheduled Payment recovered successfully',
          ),
        );
      },
    );
  }

  Widget _buildGoalsTab(FinanceProvider provider, ThemeData theme) {
    final list = provider.deletedGoals;
    if (list.isEmpty) return _buildEmptyState('Goals');

    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        return _buildRecordItem(
          title: item.name,
          subtitle: 'Target Date: ${item.targetDate}',
          trailing: '${provider.defaultCurrency}${item.targetAmount.toStringAsFixed(2)}',
          isDeleted: item.deleted,
          onRecover: () => _handleRecover(
            () => provider.recoverGoal(item.id!),
            'Goal recovered successfully',
          ),
        );
      },
    );
  }

  Widget _buildAssetsTab(FinanceProvider provider, ThemeData theme) {
    final list = provider.deletedAssets;
    if (list.isEmpty) return _buildEmptyState('Assets');

    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        return _buildRecordItem(
          title: item.name,
          subtitle: '${item.symbol} • Qty: ${item.quantity}',
          trailing: '${provider.defaultCurrency}${item.totalCurrentValue.toStringAsFixed(2)}',
          isDeleted: item.deleted,
          onRecover: () => _handleRecover(
            () => provider.recoverAsset(item.id!),
            'Asset recovered successfully',
          ),
        );
      },
    );
  }

  Widget _buildSplitBillsTab(FinanceProvider provider, ThemeData theme) {
    final list = provider.deletedSplitBills;
    if (list.isEmpty) return _buildEmptyState('Split Bills');

    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        return _buildRecordItem(
          title: item.title,
          subtitle: 'Paid by: ${item.paidBy} • Date: ${item.date}',
          trailing: '${provider.defaultCurrency}${item.totalAmount.toStringAsFixed(2)}',
          isDeleted: item.deleted,
          onRecover: () => _handleRecover(
            () => provider.recoverSplitBill(item.id!),
            'Split Bill recovered successfully',
          ),
        );
      },
    );
  }

  Widget _buildFuelLogsTab(FinanceProvider provider, ThemeData theme) {
    final list = provider.deletedFuelLogs;
    if (list.isEmpty) return _buildEmptyState('Fuel Logs');

    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        return _buildRecordItem(
          title: 'Fueling (${item.date})',
          subtitle: 'Odometer: ${item.odometer.toStringAsFixed(0)} km • ${item.fuelAmount} L',
          trailing: '${provider.defaultCurrency}${item.totalCost.toStringAsFixed(2)}',
          isDeleted: item.deleted,
          onRecover: () => _handleRecover(
            () => provider.recoverFuelLog(item.id!),
            'Fuel Log recovered successfully',
          ),
        );
      },
    );
  }

  Widget _buildCarTripsTab(FinanceProvider provider, ThemeData theme) {
    final list = provider.deletedCarTrips;
    if (list.isEmpty) return _buildEmptyState('Car Trips');

    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        return _buildRecordItem(
          title: 'Car Trip (${item.date})',
          subtitle: 'Distance: ${item.distanceTravelled.toStringAsFixed(2)} km',
          trailing: item.status,
          isDeleted: item.deleted,
          onRecover: () => _handleRecover(
            () => provider.recoverCarTrip(item.id!),
            'Car Trip recovered successfully',
          ),
        );
      },
    );
  }
}
