import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../models/wallet_account.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  void _showAccountModal(BuildContext context, {WalletAccount? account}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AccountSheet(account: account),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);
    final accounts = provider.accounts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet Accounts'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF080914), Color(0xFF0E111F)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: accounts.isEmpty
            ? const Center(
                child: Text('No accounts configured.', style: TextStyle(color: Colors.white54)),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: accounts.length,
                itemBuilder: (context, index) {
                  final acc = accounts[index];
                  final balance = provider.getAccountBalance(acc);
                  final isDefaultAcc = acc.id == 1 || acc.id == 2;
                  final Color cardColor = Color(int.parse(acc.color.replaceFirst('#', '0xFF')));

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        colors: [cardColor.withValues(alpha: 0.2), cardColor.withValues(alpha: 0.02)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(color: cardColor.withValues(alpha: 0.35), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: cardColor.withValues(alpha: 0.04),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(20),
                      onTap: () => _showAccountModal(context, account: acc),
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cardColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          acc.type == 'Cash'
                              ? Icons.money_rounded
                              : acc.type == 'Credit Card'
                                  ? Icons.credit_card_rounded
                                  : acc.type == 'Savings'
                                      ? Icons.savings_rounded
                                      : Icons.account_balance_rounded,
                          color: cardColor,
                          size: 28,
                        ),
                      ),
                      title: Text(
                        acc.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          acc.type.toUpperCase(),
                          style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.0),
                        ),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${acc.currencySymbol}${balance.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Colors.white, letterSpacing: -0.5),
                          ),
                          if (isDefaultAcc)
                            const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Text(
                                'SYSTEM DEFAULT',
                                style: TextStyle(color: Colors.white30, fontSize: 8, fontWeight: FontWeight.bold),
                              ),
                            )
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAccountModal(context),
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text('New Account', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF6366F1),
      ),
    );
  }
}

class AccountSheet extends StatefulWidget {
  final WalletAccount? account;
  const AccountSheet({super.key, this.account});

  @override
  State<AccountSheet> createState() => _AccountSheetState();
}

class _AccountSheetState extends State<AccountSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _initialBalanceController = TextEditingController();
  String _selectedType = 'Bank Account';
  String _selectedCurrency = '₹';
  String _selectedColor = '#6366F1';

  final List<String> _types = ['Cash', 'Bank Account', 'Credit Card', 'Savings', 'Other'];
  final List<String> _currencies = ['₹', '\$', '€', '£', '¥'];
  final List<String> _colors = ['#6366F1', '#10B981', '#F59E0B', '#EF4444', '#EC4899', '#06B6D4', '#8B5CF6'];

  @override
  void initState() {
    super.initState();
    if (widget.account != null) {
      _nameController.text = widget.account!.name;
      _initialBalanceController.text = widget.account!.initialBalance.toString();
      _selectedType = widget.account!.type;
      _selectedCurrency = widget.account!.currencySymbol;
      _selectedColor = widget.account!.color;
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<FinanceProvider>(context, listen: false);
      final acc = WalletAccount(
        id: widget.account?.id,
        name: _nameController.text,
        type: _selectedType,
        initialBalance: double.parse(_initialBalanceController.text),
        currencySymbol: _selectedCurrency,
        color: _selectedColor,
      );

      if (widget.account == null) {
        provider.addWalletAccount(acc);
      } else {
        provider.updateWalletAccount(acc);
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);
    final isEdit = widget.account != null;
    final isSystemDefault = widget.account != null && (widget.account!.id == 1 || widget.account!.id == 2);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF121422),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(top: BorderSide(color: Colors.white12, width: 1.5)),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEdit ? 'Edit Account' : 'New Wallet Account',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Account Name',
                  labelStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF6366F1)),
                ),
                validator: (val) => val!.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedType,
                      dropdownColor: const Color(0xFF121422),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Account Type',
                        labelStyle: const TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (val) => setState(() => _selectedType = val!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedCurrency,
                      dropdownColor: const Color(0xFF121422),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Currency',
                        labelStyle: const TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      items: _currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) => setState(() => _selectedCurrency = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _initialBalanceController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Initial Balance',
                  labelStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  prefixIcon: const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF6366F1)),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (double.tryParse(v) == null) return 'Invalid number';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              const Text('Account Styling Theme', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              SizedBox(
                height: 44,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _colors.length,
                  itemBuilder: (context, index) {
                    final colorHex = _colors[index];
                    final colorVal = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
                    final isSelected = _selectedColor == colorHex;

                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = colorHex),
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        width: 44,
                        decoration: BoxDecoration(
                          color: colorVal,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 3)
                              : Border.all(color: Colors.transparent),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 20)
                            : null,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  if (isEdit && !isSystemDefault) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: const Color(0xFF121422),
                              title: const Text('Delete Account?'),
                              content: const Text(
                                'This will delete this account. All transactions linked to this account will revert to the default Cash account.',
                                style: TextStyle(color: Colors.white70),
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                TextButton(
                                  onPressed: () {
                                    provider.deleteWalletAccount(widget.account!.id!);
                                    Navigator.pop(ctx);
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(Icons.delete),
                        label: const Text('Delete', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _submit,
                      child: Text(
                        isEdit ? 'Update' : 'Save Account',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
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
