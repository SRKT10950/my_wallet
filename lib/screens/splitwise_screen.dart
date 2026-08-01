import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../models/split_bill.dart';

class SplitwiseScreen extends StatefulWidget {
  const SplitwiseScreen({super.key});

  @override
  State<SplitwiseScreen> createState() => _SplitwiseScreenState();
}

class _SplitwiseScreenState extends State<SplitwiseScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Group Expense Splitter',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: -0.5),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF6366F1),
          labelColor: const Color(0xFF6366F1),
          unselectedLabelColor: Colors.white38,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Balances', icon: Icon(Icons.account_balance_wallet_outlined, size: 20)),
            Tab(text: 'Bills History', icon: Icon(Icons.receipt_long_outlined, size: 20)),
            Tab(text: 'Friends List', icon: Icon(Icons.people_outline, size: 20)),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF080914), Color(0xFF0E111F)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            const NetDuesTab(),
            const GroupBillsTab(),
            const FriendsTab(),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// BALANCES TAB
// -------------------------------------------------------------
class NetDuesTab extends StatelessWidget {
  const NetDuesTab({super.key});

  void _showSettleDialog(BuildContext context, String friend, double amount) {
    final provider = Provider.of<FinanceProvider>(context, listen: false);
    if (provider.accounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please create a wallet account first in menu!'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    int selectedAccountId = provider.accounts.first.id!;
    final absoluteAmount = amount.abs();
    final isIncome = amount > 0;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF121422),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
              title: Text(
                isIncome ? 'Settle Dues from $friend' : 'Settle Dues to $friend',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'This will record a transaction of ${provider.defaultCurrency}${absoluteAmount.toStringAsFixed(2)} and reset split balances with $friend.',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'CHOOSE TRANSACTION WALLET',
                    style: TextStyle(color: Colors.white30, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: selectedAccountId,
                        dropdownColor: const Color(0xFF121422),
                        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54, size: 18),
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        isExpanded: true,
                        items: provider.accounts.map((acc) {
                          return DropdownMenuItem<int>(
                            value: acc.id,
                            child: Text(acc.name),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => selectedAccountId = val);
                        },
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await provider.settleFriendDues(friend, amount, selectedAccountId);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Settled with $friend successfully!'),
                          backgroundColor: Colors.greenAccent,
                        ),
                      );
                    }
                  },
                  child: const Text('Confirm Settle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);
    final balances = provider.friendsNetBalances;
    final curSymbol = provider.defaultCurrency;

    double totalOwedToYou = 0.0;
    double totalYouOwe = 0.0;

    balances.forEach((friend, bal) {
      if (bal > 0) {
        totalOwedToYou += bal;
      } else if (bal < 0) {
        totalYouOwe += bal.abs();
      }
    });

    final activeBalances = balances.entries.where((e) => e.value != 0.0).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Summary Cards
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF121422),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.12)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.arrow_downward_rounded, color: Colors.greenAccent, size: 16),
                          SizedBox(width: 4),
                          Text('Owed to You', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$curSymbol${totalOwedToYou.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.greenAccent, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF121422),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.12)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.arrow_upward_rounded, color: Colors.redAccent, size: 16),
                          SizedBox(width: 4),
                          Text('You Owe', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$curSymbol${totalYouOwe.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.redAccent, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Balance List Header
          const Text(
            'SPLIT BALANCE STATUS',
            style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5),
          ),
          const SizedBox(height: 10),

          // Balance List
          Expanded(
            child: activeBalances.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.done_all_rounded, size: 48, color: Colors.white.withValues(alpha: 0.12)),
                        const SizedBox(height: 12),
                        Text('All Settled Up!', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('No outstanding dues with any friends.', style: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 11)),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: activeBalances.length,
                    itemBuilder: (context, idx) {
                      final item = activeBalances[idx];
                      final friend = item.key;
                      final bal = item.value;
                      final isOwed = bal > 0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF121422),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: isOwed ? Colors.greenAccent.withValues(alpha: 0.1) : Colors.redAccent.withValues(alpha: 0.1),
                                  child: Text(
                                    friend[0].toUpperCase(),
                                    style: TextStyle(
                                      color: isOwed ? Colors.greenAccent : Colors.redAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(friend, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                    const SizedBox(height: 2),
                                    Text(
                                      isOwed ? 'owes you' : 'you owe them',
                                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Text(
                                  '$curSymbol${bal.abs().toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: isOwed ? Colors.greenAccent : Colors.redAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isOwed 
                                      ? Colors.greenAccent.withValues(alpha: 0.15) 
                                      : Colors.redAccent.withValues(alpha: 0.15),
                                    foregroundColor: isOwed ? Colors.greenAccent : Colors.redAccent,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: () => _showSettleDialog(context, friend, bal),
                                  child: const Text('SETTLE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// BILLS HISTORY TAB
// -------------------------------------------------------------
class GroupBillsTab extends StatelessWidget {
  const GroupBillsTab({super.key});

  void _showAddBillDialog(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context, listen: false);
    if (provider.friends.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add some friends first in Friends tab!'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    final List<String> allParticipants = ['You', ...provider.friends.where((f) => f != 'You')];
    
    // Dialog state variables
    String title = '';
    double totalAmount = 0.0;
    String paidBy = 'You';
    List<String> selectedParticipants = List<String>.from(allParticipants);
    String splitMethod = 'Equal'; // 'Equal' or 'Custom'
    Map<String, double> shares = {};

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Helper to auto-calculate equal shares
            void recalculateShares() {
              shares.clear();
              if (selectedParticipants.isEmpty || totalAmount <= 0) return;
              
              if (splitMethod == 'Equal') {
                final shareVal = totalAmount / selectedParticipants.length;
                for (var p in selectedParticipants) {
                  shares[p] = shareVal;
                }
              }
            }

            return AlertDialog(
              backgroundColor: const Color(0xFF121422),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
              title: const Text('Add Group Split Bill', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Title Textfield
                      TextField(
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Bill Description / Title',
                          labelStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF6366F1))),
                        ),
                        onChanged: (val) {
                          title = val;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Amount Textfield
                      TextField(
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Total Amount Paid (${provider.defaultCurrency})',
                          labelStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF6366F1))),
                        ),
                        onChanged: (val) {
                          totalAmount = double.tryParse(val) ?? 0.0;
                          recalculateShares();
                        },
                      ),
                      const SizedBox(height: 16),

                      // Paid By Dropdown
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Paid By:', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: DropdownButton<String>(
                              value: paidBy,
                              dropdownColor: const Color(0xFF121422),
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              underline: const SizedBox(),
                              items: allParticipants.map((friend) {
                                return DropdownMenuItem<String>(
                                  value: friend,
                                  child: Text(friend),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    paidBy = val;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Participants Selection
                      const Text(
                        'SPLIT BETWEEN PARTICIPANTS',
                        style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: allParticipants.map((person) {
                          final isSelected = selectedParticipants.contains(person);
                          return FilterChip(
                            selected: isSelected,
                            backgroundColor: Colors.white.withValues(alpha: 0.03),
                            selectedColor: const Color(0xFF6366F1).withValues(alpha: 0.18),
                            checkmarkColor: const Color(0xFF6366F1),
                            side: BorderSide(color: isSelected ? const Color(0xFF6366F1) : Colors.white12),
                            label: Text(person, style: TextStyle(color: isSelected ? Colors.white : Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                            onSelected: (val) {
                              setState(() {
                                if (val) {
                                  selectedParticipants.add(person);
                                } else {
                                  selectedParticipants.remove(person);
                                }
                                recalculateShares();
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Split Method Switcher
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Split Method:', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                          ToggleButtons(
                            borderRadius: BorderRadius.circular(10),
                            isSelected: [splitMethod == 'Equal', splitMethod == 'Custom'],
                            fillColor: const Color(0xFF6366F1).withValues(alpha: 0.2),
                            selectedBorderColor: const Color(0xFF6366F1),
                            selectedColor: Colors.white,
                            color: Colors.white38,
                            constraints: const BoxConstraints(minWidth: 60, minHeight: 30),
                            children: const [
                              Text('EQUAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
                              Text('CUSTOM', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
                            ],
                            onPressed: (index) {
                              setState(() {
                                splitMethod = index == 0 ? 'Equal' : 'Custom';
                                recalculateShares();
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Share Input Fields
                      if (selectedParticipants.isNotEmpty) ...[
                        const Text(
                          'SHARES ALLOCATION',
                          style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                        ),
                        const SizedBox(height: 8),
                        ...selectedParticipants.map((person) {
                          if (splitMethod == 'Equal') {
                            final equalShare = shares[person] ?? 0.0;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(person, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                  Text('${provider.defaultCurrency}${equalShare.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                ],
                              ),
                            );
                          } else {
                            // Custom Split inputs
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Expanded(flex: 3, child: Text(person, style: const TextStyle(color: Colors.white70, fontSize: 12))),
                                  Expanded(
                                    flex: 2,
                                    child: SizedBox(
                                      height: 32,
                                      child: TextField(
                                        keyboardType: TextInputType.number,
                                        style: const TextStyle(color: Colors.white, fontSize: 12),
                                        decoration: InputDecoration(
                                          isDense: true,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)), borderRadius: BorderRadius.circular(8)),
                                          focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFF6366F1)), borderRadius: BorderRadius.circular(8)),
                                        ),
                                        onChanged: (val) {
                                          final valDouble = double.tryParse(val) ?? 0.0;
                                          shares[person] = valDouble;
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                        }),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    if (title.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a title')));
                      return;
                    }
                    if (totalAmount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter total amount')));
                      return;
                    }
                    if (selectedParticipants.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select at least one participant')));
                      return;
                    }

                    // For Custom Split, let's verify totals match totalAmount
                    if (splitMethod == 'Custom') {
                      final sum = shares.values.fold(0.0, (s, e) => s + e);
                      if ((sum - totalAmount).abs() > 0.1) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Sum of custom shares (${provider.defaultCurrency}${sum.toStringAsFixed(2)}) does not match Total Amount (${provider.defaultCurrency}${totalAmount.toStringAsFixed(2)})')),
                        );
                        return;
                      }
                    }

                    Navigator.pop(ctx);
                    final bill = SplitBill(
                      title: title,
                      totalAmount: totalAmount,
                      paidBy: paidBy,
                      participants: selectedParticipants,
                      shares: shares,
                      date: DateTime.now().toIso8601String(),
                    );
                    await provider.addSplitBill(bill);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Split bill added!'), backgroundColor: Colors.greenAccent),
                      );
                    }
                  },
                  child: const Text('Add Bill', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);
    final bills = provider.splitBills;
    final curSymbol = provider.defaultCurrency;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'GROUP BILLS RECORD',
                style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('ADD BILL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
                onPressed: () => _showAddBillDialog(context),
              )
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: bills.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_outlined, size: 48, color: Colors.white.withValues(alpha: 0.12)),
                        const SizedBox(height: 12),
                        Text('No Bills Logged', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Click "Add Bill" to log group expenses.', style: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 11)),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: bills.length,
                    itemBuilder: (context, idx) {
                      final bill = bills[bills.length - 1 - idx]; // display latest first

                      return Dismissible(
                        key: ValueKey(bill.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) {
                          provider.deleteSplitBill(bill.id!);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Split bill deleted')),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF121422),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      bill.title,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '$curSymbol${bill.totalAmount.toStringAsFixed(2)}',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
                                  )
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Paid by: ${bill.paidBy}',
                                    style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold, fontSize: 11),
                                  ),
                                  Text(
                                    bill.date.substring(0, 10),
                                    style: const TextStyle(color: Colors.white30, fontSize: 11),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 12,
                                runSpacing: 6,
                                children: bill.shares.entries.map((share) {
                                  return Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: Colors.cyanAccent,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        '${share.key}: $curSymbol${share.value.toStringAsFixed(1)}',
                                        style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          )
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// FRIENDS TAB
// -------------------------------------------------------------
class FriendsTab extends StatelessWidget {
  const FriendsTab({super.key});

  void _showAddFriendDialog(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context, listen: false);
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF121422),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
          title: const Text('Add Friend Name', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          content: TextField(
            controller: textController,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Enter name (e.g. Vikram)',
              hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
              focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF6366F1))),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final name = textController.text.trim();
                if (name.isNotEmpty) {
                  await provider.addFriend(name);
                  if (context.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Added friend: $name'), backgroundColor: Colors.greenAccent),
                    );
                  }
                }
              },
              child: const Text('Save Friend', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);
    final friends = provider.friends.where((f) => f != 'You').toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'MANAGE FRIENDS',
                style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('ADD FRIEND', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
                onPressed: () => _showAddFriendDialog(context),
              )
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: friends.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline_rounded, size: 48, color: Colors.white.withValues(alpha: 0.12)),
                        const SizedBox(height: 12),
                        Text('No Friends Yet', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Click "Add Friend" to build your split circle.', style: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 11)),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: friends.length,
                    itemBuilder: (context, idx) {
                      final friend = friends[idx];

                      return Dismissible(
                        key: ValueKey(friend),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) {
                          provider.deleteFriend(friend);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Removed $friend and deleted associated bills.')),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF121422),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.1),
                                    child: Text(
                                      friend[0].toUpperCase(),
                                      style: const TextStyle(
                                        color: Color(0xFF6366F1),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Text(
                                    friend,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ],
                              ),
                              const Icon(Icons.swipe_left_outlined, color: Colors.white24, size: 18),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          )
        ],
      ),
    );
  }
}
