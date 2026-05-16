import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);

    final income = provider.getMonthlyIncome(_selectedMonth, _selectedYear);
    final expenditure = provider.getMonthlyExpenditure(_selectedMonth, _selectedYear);
    final emi = provider.getTotalEMI();
    
    final currentBalance = income - expenditure - emi;
    final pendingLoan = provider.loans.where((l) => l.status == 'Active').fold(0.0, (sum, l) => sum + l.balance);
    
    final toReceive = provider.lendBorrows.where((lb) => lb.type == 'Lend' && lb.status == 'Active').fold(0.0, (sum, lb) => sum + lb.diff);
    final toPay = provider.lendBorrows.where((lb) => lb.type == 'Borrow' && lb.status == 'Active').fold(0.0, (sum, lb) => sum + lb.diff);

    // Budget Calculations
    final plannedSaving = income * 0.6;
    final plannedExpense = income * 0.4;
    final houseMaintenanceExpense = plannedExpense * 0.7;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Overview', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E1E2C), Color(0xFF121212)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdown<int>(
                          _selectedMonth, 
                          List.generate(12, (i) => i + 1), 
                          (val) => setState(() => _selectedMonth = val!),
                          labelBuilder: (m) => ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][m - 1],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDropdown<int>(
                          _selectedYear, 
                          List.generate(10, (i) => DateTime.now().year - 5 + i), 
                          (val) => setState(() => _selectedYear = val!)
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 20),
                
                // Hero Balance Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(colors: [Colors.cyanAccent, Colors.blueAccent], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    boxShadow: [BoxShadow(color: Colors.cyanAccent.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Balance', style: TextStyle(color: Colors.black54, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('₹${currentBalance.toStringAsFixed(0)}', style: const TextStyle(color: Colors.black, fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: -1)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Combined Lend & Borrow Box
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white12, width: 1.5),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Lend & Borrow', style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSplitStat('To Receive', toReceive, Icons.arrow_downward, Colors.greenAccent),
                          ),
                          Container(width: 1, height: 40, color: Colors.white12),
                          Expanded(
                            child: _buildSplitStat('To Pay', toPay, Icons.arrow_upward, Colors.redAccent),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Combined Loans Box
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white12, width: 1.5),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Loans', style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSplitStat('Active EMI', emi, Icons.calendar_today, Colors.orangeAccent),
                          ),
                          Container(width: 1, height: 40, color: Colors.white12),
                          Expanded(
                            child: _buildSplitStat('Pending Loan', pendingLoan, Icons.account_balance, Colors.deepOrangeAccent),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.05,
                  children: [
                    _buildModernCard('Expenditure', expenditure, Icons.account_balance_wallet, Colors.pinkAccent),
                    _buildModernCard('Investments', provider.totalCurrentInvestments, Icons.trending_up, Colors.purpleAccent),
                  ],
                ),

                const SizedBox(height: 32),
                const Text('Budget Analysis', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 16),

                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(Colors.black12),
                        columns: const [
                          DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Savings', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Expense', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: [
                          DataRow(
                            color: WidgetStateProperty.all(Colors.blueAccent.withOpacity(0.15)),
                            cells: [
                              const DataCell(Text('Monthly Income', style: TextStyle(color: Colors.lightBlueAccent, fontWeight: FontWeight.bold))),
                              DataCell(Text('₹${plannedSaving.toStringAsFixed(0)}')),
                              DataCell(Text('₹${plannedExpense.toStringAsFixed(0)}')),
                            ],
                          ),
                          DataRow(
                            cells: [
                              const DataCell(Text('Current Status', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataCell(Text('₹${provider.currentMonthlySavings.toStringAsFixed(0)}')),
                              DataCell(Text('₹${houseMaintenanceExpense.toStringAsFixed(0)}')),
                            ],
                          ),
                          DataRow(
                            cells: [
                              const DataCell(Text('House mentenance')),
                              const DataCell(Text('')),
                              DataCell(Text('₹${houseMaintenanceExpense.toStringAsFixed(0)}')),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>(T value, List<T> items, void Function(T?) onChanged, {String Function(T)? labelBuilder}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: true,
          value: value,
          dropdownColor: const Color(0xFF1E1E2C),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.tealAccent),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(labelBuilder != null ? labelBuilder(e) : e.toString(), style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildSplitStat(String title, double amount, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text('₹${amount.toStringAsFixed(0)}', style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildModernCard(String title, double amount, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.2), width: 1.0),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.05), blurRadius: 20, spreadRadius: 2),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -10,
            child: Icon(icon, size: 80, color: color.withOpacity(0.05)),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '₹${amount.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
