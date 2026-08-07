import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../providers/finance_provider.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/wallet_account.dart';
import '../models/contact.dart';
import '../models/product.dart';
import '../models/transaction_item.dart';
import '../utils/string_utils.dart';
import '../utils/messaging_utils.dart';
import '../utils/hinglish_translator.dart';
import 'category_manager_screen.dart';

class DailyTrackerScreen extends StatefulWidget {
  const DailyTrackerScreen({super.key});

  @override
  State<DailyTrackerScreen> createState() => _DailyTrackerScreenState();
}

class _DailyTrackerScreenState extends State<DailyTrackerScreen> {
  String _searchQuery = '';
  WalletAccount? _accountFilter;
  String _typeFilter = 'All'; // 'All', 'Expense', 'Income', 'Transfer'
  String? _tagFilter;
  bool _onlyDueFilter = false;

  void _showTransactionModal(BuildContext context, {DailyTransaction? transaction}) {
    final provider = Provider.of<FinanceProvider>(context, listen: false);
    if (provider.categories.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF121422),
          title: const Text('No Categories'),
          content: const Text('You need to create at least one category before adding transactions.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CategoryManagerScreen()),
                );
              },
              child: const Text('Manage Categories', style: TextStyle(color: Colors.tealAccent)),
            ),
          ],
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TransactionSheet(transaction: transaction),
    );
  }

  void _showShopLedgerModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const ShopLedgerSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);
    final curSymbol = provider.defaultCurrency;

    // Retrieve all unique tags from transactions
    final allTags = provider.transactions
        .expand((tx) => tx.tags)
        .map((t) => t.trim().toLowerCase())
        .where((t) => t.isNotEmpty && !t.startsWith('shop:'))
        .toSet()
        .toList();

    // Filter transactions
    var filteredTransactions = provider.transactions.reversed.where((tx) {
      // 1. Search filter
      final q = _searchQuery.trim().toLowerCase();
      final matchesSearch = q.isEmpty ||
          tx.itemService.toLowerCase().contains(q) ||
          tx.note.toLowerCase().contains(q) ||
          tx.merchantName.toLowerCase().contains(q) ||
          tx.tags.any((t) => t.toLowerCase().contains(q)) ||
          tx.items.any((i) => i.itemName.toLowerCase().contains(q) || i.localName.toLowerCase().contains(q)) ||
          provider.contacts.any((c) {
            final matchesContact = c.name.toLowerCase().contains(q) ||
                (c.businessName.isNotEmpty && c.businessName.toLowerCase().contains(q));
            if (!matchesContact) return false;
            final txMerchant = tx.merchantName.toLowerCase();
            final cName = c.name.toLowerCase();
            final bName = c.businessName.toLowerCase();
            return (cName.isNotEmpty && txMerchant.contains(cName)) ||
                (bName.isNotEmpty && txMerchant.contains(bName)) ||
                tx.tags.any((t) => t.toLowerCase() == 'shop:$cName' || (bName.isNotEmpty && t.toLowerCase() == 'shop:$bName'));
          });
      
      // 2. Account filter
      bool matchesAccount = true;
      if (_accountFilter != null) {
        if (tx.transactionType == 'Transfer') {
          matchesAccount = tx.accountId == _accountFilter!.id || tx.toAccountId == _accountFilter!.id;
        } else {
          final txAccId = tx.accountId ?? 1; // legacy defaults to Cash
          matchesAccount = txAccId == _accountFilter!.id;
        }
      }

      // 3. Type filter
      final matchesType = _typeFilter == 'All' || tx.transactionType == _typeFilter;

      // 4. Tag filter
      final matchesTag = _tagFilter == null || 
          tx.tags.map((t) => t.toLowerCase()).contains(_tagFilter!.toLowerCase());

      // 5. Due filter
      final matchesDue = !_onlyDueFilter || (tx.cost > tx.paidAmount);

      return matchesSearch && matchesAccount && matchesType && matchesTag && matchesDue;
    }).toList();

    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF080914), Color(0xFF0E111F)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        child: Column(
          children: [
            // Search Bar & Filter Strip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search items, notes, contact, or shop name...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFF121422),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Dropdown & Action filters row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Shop Bills Ledger Quick Button
                        ActionChip(
                          avatar: const Icon(Icons.receipt_long_rounded, size: 14, color: Colors.black),
                          label: const Text('Shop Bills Ledger', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black)),
                          backgroundColor: Colors.tealAccent,
                          onPressed: () => _showShopLedgerModal(context),
                        ),
                        const SizedBox(width: 8),
                        // Due Only Filter Chip
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            avatar: Icon(
                              Icons.warning_amber_rounded,
                              size: 14,
                              color: _onlyDueFilter ? Colors.black : Colors.redAccent,
                            ),
                            label: Text(
                              'Due Only',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _onlyDueFilter ? Colors.black : Colors.white,
                              ),
                            ),
                            selected: _onlyDueFilter,
                            selectedColor: Colors.redAccent,
                            backgroundColor: const Color(0xFF121422),
                            onSelected: (val) {
                              setState(() => _onlyDueFilter = val);
                            },
                          ),
                        ),
                        // Type Filter Chips
                        ...['All', 'Expense', 'Income', 'Transfer'].map((type) {
                          final isSelected = _typeFilter == type;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(type, style: TextStyle(fontSize: 12, color: isSelected ? Colors.black : Colors.white)),
                              selected: isSelected,
                              selectedColor: const Color(0xFF6366F1),
                              backgroundColor: const Color(0xFF121422),
                              onSelected: (val) {
                                if (val) setState(() => _typeFilter = type);
                              },
                            ),
                          );
                        }),
                        // Account Filter
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            label: Text(
                              _accountFilter == null ? 'All Accounts' : _accountFilter!.name,
                              style: TextStyle(fontSize: 12, color: _accountFilter != null ? Colors.black : Colors.white),
                            ),
                            selected: _accountFilter != null,
                            selectedColor: Colors.amberAccent,
                            backgroundColor: const Color(0xFF121422),
                            onSelected: (selected) {
                              if (!selected) {
                                setState(() => _accountFilter = null);
                              } else {
                                // Cycle accounts
                                final accs = provider.accounts;
                                if (accs.isEmpty) return;
                                final currIdx = accs.indexOf(_accountFilter ?? accs.first);
                                if (_accountFilter == null) {
                                  setState(() => _accountFilter = accs.first);
                                } else if (currIdx < accs.length - 1) {
                                  setState(() => _accountFilter = accs[currIdx + 1]);
                                } else {
                                  setState(() => _accountFilter = null);
                                }
                              }
                            },
                          ),
                        ),
                        // Tags Filter Dropdown
                        if (allTags.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: FilterChip(
                              label: Text(
                                _tagFilter == null ? 'Tags' : '#$_tagFilter',
                                style: TextStyle(fontSize: 12, color: _tagFilter != null ? Colors.black : Colors.white),
                              ),
                              selected: _tagFilter != null,
                              selectedColor: Colors.purpleAccent,
                              backgroundColor: const Color(0xFF121422),
                              onSelected: (selected) {
                                if (!selected) {
                                  setState(() => _tagFilter = null);
                                } else {
                                  // Cycle tags
                                  final currIdx = _tagFilter == null ? -1 : allTags.indexOf(_tagFilter!);
                                  if (currIdx < allTags.length - 1) {
                                    setState(() => _tagFilter = allTags[currIdx + 1]);
                                  } else {
                                    setState(() => _tagFilter = null);
                                  }
                                }
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Transactions List
            Expanded(
              child: filteredTransactions.isEmpty
                  ? const Center(
                      child: Text('No transactions found.', style: TextStyle(color: Colors.grey)),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 88),
                      itemCount: filteredTransactions.length,
                      itemBuilder: (context, index) {
                        final tx = filteredTransactions[index];
                        final cat = provider.categories.firstWhere(
                          (c) => c.id == tx.categoryId,
                          orElse: () => Category(id: 0, name: 'General', plannedAmount: 0),
                        );

                        final isExpense = tx.transactionType == 'Expense';
                        final isIncome = tx.transactionType == 'Income';
                        final isTransfer = tx.transactionType == 'Transfer';

                        final color = isExpense 
                            ? Colors.redAccent 
                            : isIncome 
                                ? Colors.greenAccent 
                                : Colors.blueAccent;

                        final sign = isExpense ? '-' : (isIncome ? '+' : '');

                        // Account labels
                        String accountLabel = '';
                        if (isTransfer) {
                          final fromAcc = provider.accounts.firstWhere((a) => a.id == tx.accountId, orElse: () => WalletAccount(id: 0, name: 'Cash', type: 'Cash', initialBalance: 0, currencySymbol: '₹', color: '#6366F1'));
                          final toAcc = provider.accounts.firstWhere((a) => a.id == tx.toAccountId, orElse: () => WalletAccount(id: 0, name: 'Account', type: 'Bank Account', initialBalance: 0, currencySymbol: '₹', color: '#6366F1'));
                          accountLabel = '${fromAcc.name} ➔ ${toAcc.name}';
                        } else {
                          final acc = provider.accounts.firstWhere((a) => a.id == (tx.accountId ?? 1), orElse: () => WalletAccount(id: 0, name: 'Cash', type: 'Cash', initialBalance: 0, currencySymbol: '₹', color: '#6366F1'));
                          accountLabel = acc.name;
                        }

                        // Extract Shop Name
                        String? shopName = tx.merchantName.isNotEmpty ? toTitleCase(tx.merchantName) : null;
                        if (shopName == null) {
                          for (var t in tx.tags) {
                            if (t.startsWith('shop:')) {
                              shopName = toTitleCase(t.substring(5).trim());
                              break;
                            }
                          }
                        }

                        final txDate = DateTime.tryParse(tx.date) ?? DateTime.now();

                        return Card(
                          color: const Color(0xFF121422),
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                          ),
                          child: InkWell(
                            onTap: () => _showTransactionModal(context, transaction: tx),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(14.0),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: color.withValues(alpha: 0.15),
                                    child: Icon(
                                      isExpense ? Icons.arrow_upward : (isIncome ? Icons.arrow_downward : Icons.swap_horiz),
                                      color: color,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                tx.itemService,
                                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (shopName != null) ...[
                                              const SizedBox(width: 6),
                                              Flexible(
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.tealAccent.withValues(alpha: 0.15),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    '🛒 $shopName',
                                                    style: const TextStyle(color: Colors.tealAccent, fontSize: 10, fontWeight: FontWeight.bold),
                                                    overflow: TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text(DateFormat('MMM dd, yyyy').format(txDate), style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                            const SizedBox(width: 8),
                                            Text('•  $accountLabel', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                                            if (!isTransfer) ...[
                                              const SizedBox(width: 8),
                                              Text('•  ${cat.name}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                                            ],
                                          ],
                                        ),
                                        if (tx.note.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(tx.note, style: const TextStyle(color: Colors.grey, fontSize: 11, fontStyle: FontStyle.italic), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '$sign$curSymbol${tx.cost.toStringAsFixed(0)}',
                                        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                      if (tx.remaining > 0 && !isTransfer) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          'Due: $curSymbol${tx.remaining.toStringAsFixed(0)}',
                                          style: const TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    ),
    floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTransactionModal(context),
        backgroundColor: const Color(0xFF6366F1),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Entry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class TransactionSheet extends StatefulWidget {
  final DailyTransaction? transaction;
  final String? ocrMerchant;
  final double? ocrAmount;
  final String? ocrDate;
  final List<String>? ocrItems;
  final String? ocrNote;
  final int? ocrCategoryId;
  final int? ocrAccountId;

  const TransactionSheet({
    super.key,
    this.transaction,
    this.ocrMerchant,
    this.ocrAmount,
    this.ocrDate,
    this.ocrItems,
    this.ocrNote,
    this.ocrCategoryId,
    this.ocrAccountId,
  });

  @override
  State<TransactionSheet> createState() => _TransactionSheetState();
}

class _TransactionSheetState extends State<TransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _itemController = TextEditingController();
  final _shopController = TextEditingController();
  final _costController = TextEditingController();
  final _paidController = TextEditingController();
  final _noteController = TextEditingController();
  final _tagsController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  Category? _selectedCategory;
  WalletAccount? _selectedAccount;
  WalletAccount? _selectedToAccount;
  bool _cleared = true;
  String _transactionType = 'Expense';
  bool _isCustomShopInput = false;
  List<TransactionItem> _stagedChildItems = [];

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      if (widget.transaction!.items.isNotEmpty) {
        _stagedChildItems = List.from(widget.transaction!.items);
      }
      _selectedDate = DateTime.tryParse(widget.transaction!.date) ?? DateTime.now();
      _itemController.text = widget.transaction!.itemService;
      _costController.text = widget.transaction!.cost.toStringAsFixed(0);
      _paidController.text = widget.transaction!.paidAmount.toStringAsFixed(0);
      _cleared = widget.transaction!.cleared;
      _transactionType = widget.transaction!.transactionType;
      _noteController.text = widget.transaction!.note;

      // Populate shop controller prioritizing merchantName
      if (widget.transaction!.merchantName.isNotEmpty) {
        _shopController.text = toTitleCase(widget.transaction!.merchantName);
      }

      // Separate shop: tags from regular tags
      final nonShopTags = <String>[];
      for (var t in widget.transaction!.tags) {
        if (t.startsWith('shop:')) {
          if (_shopController.text.isEmpty) {
            _shopController.text = toTitleCase(t.substring(5).trim());
          }
        } else {
          nonShopTags.add(t);
        }
      }
      _tagsController.text = nonShopTags.join(', ');
    } else if (widget.ocrMerchant != null) {
      _itemController.text = toTitleCase(widget.ocrMerchant ?? '');
      _shopController.text = toTitleCase(widget.ocrMerchant ?? '');
      final amount = widget.ocrAmount ?? 0.0;
      _costController.text = amount.toStringAsFixed(0);
      _paidController.text = amount.toStringAsFixed(0);
      _cleared = true;
      _transactionType = 'Expense';

      if (widget.ocrDate != null && widget.ocrDate!.isNotEmpty) {
        try {
          final raw = widget.ocrDate!.replaceAll('.', '/').replaceAll('-', '/');
          final parts = raw.split('/');
          if (parts.length == 3) {
            final a = int.tryParse(parts[0]) ?? 1;
            final b = int.tryParse(parts[1]) ?? 1;
            int c = int.tryParse(parts[2]) ?? DateTime.now().year;
            if (c < 100) c += 2000;
            if (parts[0].length == 4) {
              _selectedDate = DateTime(a, b, c);
            } else {
              _selectedDate = DateTime(c, b, a);
            }
          }
        } catch (_) {
          _selectedDate = DateTime.now();
        }
      }

      final itemsText = (widget.ocrItems != null && widget.ocrItems!.isNotEmpty) ? widget.ocrItems!.join('\n') : '';
      _noteController.text = [
        if (widget.ocrNote != null && widget.ocrNote!.isNotEmpty) widget.ocrNote!,
        if (itemsText.isNotEmpty) 'Items:\n$itemsText',
      ].join('\n\n');

      _tagsController.text = 'receipt-ocr';
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<FinanceProvider>(context, listen: false);

      final tags = _tagsController.text
          .split(',')
          .map((t) => t.trim().toLowerCase())
          .where((t) => t.isNotEmpty && !t.startsWith('shop:'))
          .toList();

      final shopFormatted = toTitleCase(_shopController.text.trim());
      if (shopFormatted.isNotEmpty) {
        tags.add('shop:${shopFormatted.toLowerCase()}');
      }

      final isTransfer = _transactionType == 'Transfer';
      int catId = 1;
      if (!isTransfer && _selectedCategory != null) {
        catId = _selectedCategory!.id!;
      }

      final tx = DailyTransaction(
        id: widget.transaction?.id,
        date: _selectedDate.toIso8601String(),
        categoryId: catId,
        itemService: _itemController.text.trim(),
        cost: double.parse(_costController.text.trim()),
        paidAmount: isTransfer ? double.parse(_costController.text.trim()) : double.parse(_paidController.text.trim()),
        cleared: isTransfer ? true : _cleared,
        accountId: _selectedAccount?.id ?? 1,
        toAccountId: isTransfer ? _selectedToAccount?.id : null,
        transactionType: _transactionType,
        tags: tags,
        note: _noteController.text.trim(),
        merchantName: shopFormatted,
        items: _stagedChildItems,
      );

      if (widget.transaction == null) {
        provider.addTransaction(tx);
      } else {
        provider.updateTransaction(tx);
      }
      Navigator.pop(context);

      if (shopFormatted.isNotEmpty) {
        Contact? matchedContact;
        try {
          matchedContact = provider.contacts.firstWhere(
            (c) => c.name.toLowerCase() == shopFormatted.toLowerCase() ||
                   (c.businessName.isNotEmpty && c.businessName.toLowerCase() == shopFormatted.toLowerCase()),
          );
        } catch (_) {}

        if (matchedContact != null && matchedContact.transactionNotification && matchedContact.mobile.isNotEmpty) {
          // Calculate total cumulative due till now for this contact / shop
          final shopTxs = provider.transactions.where((t) {
            if (t.merchantName.isNotEmpty && t.merchantName.toLowerCase() == shopFormatted.toLowerCase()) return true;
            for (var tag in t.tags) {
              if (tag.toLowerCase() == 'shop:${shopFormatted.toLowerCase()}') return true;
            }
            return false;
          });

          double cumulativeDue = 0.0;
          for (var t in shopTxs) {
            if (t.cost > t.paidAmount) {
              cumulativeDue += (t.cost - t.paidAmount);
            }
          }

          final isSms = matchedContact.notificationMethod == 'SMS';
          final msg = MessagingUtils.formatInvoiceMessage(
            contactName: matchedContact.name,
            businessName: matchedContact.businessName.isNotEmpty ? matchedContact.businessName : shopFormatted,
            itemService: tx.itemService,
            totalCost: tx.cost,
            paidAmount: tx.paidAmount,
            dateStr: DateFormat('MMM dd, yyyy').format(_selectedDate),
            totalDueTillNow: cumulativeDue > 0 ? cumulativeDue : null,
            isWhatsApp: !isSms,
          );

          if (isSms) {
            MessagingUtils.sendSms(phone: matchedContact.mobile, message: msg);
          } else {
            MessagingUtils.sendWhatsApp(phone: matchedContact.mobile, message: msg);
          }
        }
      }
    }
  }

  void _showContactPickerSheet(BuildContext context, FinanceProvider provider, Function(String) onSelect) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121422),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        final contacts = provider.activeContacts;
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Contact / Shop', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (contacts.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text('No active contacts in directory.', style: TextStyle(color: Colors.white54)),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: contacts.length,
                    itemBuilder: (context, i) {
                      final c = contacts[i];
                      final subText = [
                        if (c.businessName.isNotEmpty) c.businessName,
                        if (c.occupation.isNotEmpty) c.occupation,
                        if (c.place.isNotEmpty) c.place,
                        if (c.mobile.isNotEmpty) c.mobile,
                      ].join(' • ');

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.tealAccent.withValues(alpha: 0.15),
                          child: Text(c.name.isNotEmpty ? c.name[0].toUpperCase() : '?', style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold)),
                        ),
                        title: Text(c.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: subText.isNotEmpty ? Text(subText, style: const TextStyle(color: Colors.white54, fontSize: 11)) : null,
                        onTap: () {
                          onSelect(c.name);
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showProductScannerModal(BuildContext context, FinanceProvider provider, [Function(List<_SelectedItem>)? onCustomCallback]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ProductScannerSheet(
        provider: provider,
        onItemsScanned: (scanned) {
          if (scanned.isEmpty) return;
          if (onCustomCallback != null) {
            onCustomCallback(scanned);
            return;
          }

          double totalScannedCost = 0.0;
          final lines = <String>[];

          for (var item in scanned) {
            totalScannedCost += item.totalPrice;
            final nameToUse = item.product != null
                ? (item.product!.localName.trim().isNotEmpty ? item.product!.localName.trim() : item.product!.productName.trim())
                : item.customName;
            final unitStr = item.product != null ? ' (${_formatQuantity(item.quantity)} ${item.product!.unit})' : '';
            lines.add('• $nameToUse$unitStr');
          }

          final existingText = _itemController.text.trim();
          if (existingText.isEmpty) {
            _itemController.text = lines.join('\n');
          } else {
            _itemController.text = '$existingText\n${lines.join('\n')}';
          }

          if (totalScannedCost > 0) {
            final currentCost = double.tryParse(_costController.text.trim()) ?? 0.0;
            final newCost = currentCost + totalScannedCost;
            _costController.text = newCost.toStringAsFixed(0);
            if (_cleared) {
              _paidController.text = newCost.toStringAsFixed(0);
            }
          }
          setState(() {});
        },
      ),
    );
  }

  void _showProductSelectionModal(BuildContext context, FinanceProvider provider) {
    final activeProds = provider.activeProducts;
    final List<_SelectedItem> selectedItems = [];
    final TextEditingController searchCtrl = TextEditingController();
    String query = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121422),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        String selectedCategory = 'All';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final productCategories = ['All', ...activeProds.map((p) => p.category).toSet().toList()..sort()];

            final filteredProds = activeProds.where((p) {
              final matchesCat = selectedCategory == 'All' || p.category == selectedCategory;
              if (query.isEmpty) return matchesCat;
              final q = query.toLowerCase();
              return matchesCat && (p.productName.toLowerCase().contains(q) ||
                  p.localName.toLowerCase().contains(q) ||
                  p.category.toLowerCase().contains(q));
            }).toList();

            double totalCalcCost = selectedItems.fold(0.0, (sum, item) => sum + item.totalPrice);

            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Flexible(
                          child: Text('Select Products / Custom Entry', overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                        Row(
                          children: [
                            ActionChip(
                              avatar: const Icon(Icons.qr_code_scanner, size: 14, color: Colors.black),
                              label: const Text('Scan Product', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11)),
                              backgroundColor: Colors.tealAccent,
                              onPressed: () {
                                _showProductScannerModal(context, provider, (scanned) {
                                  setModalState(() {
                                    selectedItems.addAll(scanned);
                                  });
                                });
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.white54),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Live Search Bar
                    TextField(
                      controller: searchCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search product in English or Local language...',
                        hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                        prefixIcon: const Icon(Icons.search, color: Colors.tealAccent),
                        suffixIcon: query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Colors.white54),
                                onPressed: () {
                                  searchCtrl.clear();
                                  setModalState(() => query = '');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: const Color(0xFF16192E),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                      onChanged: (v) {
                        setModalState(() => query = v.trim());
                      },
                    ),
                    const SizedBox(height: 8),

                    // Category Filter Chips Row
                    SizedBox(
                      height: 36,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: productCategories.length,
                        itemBuilder: (context, idx) {
                          final cat = productCategories[idx];
                          final isSelected = selectedCategory == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(cat),
                              labelStyle: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.black : Colors.white,
                              ),
                              selected: isSelected,
                              selectedColor: Colors.tealAccent,
                              backgroundColor: const Color(0xFF16192E),
                              onSelected: (val) {
                                if (val) {
                                  setModalState(() => selectedCategory = cat);
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Matching Products & Custom Item Card List
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Custom Item Fallback Action Card if query is non-empty
                            if (query.isNotEmpty) ...[
                              Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.tealAccent.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.4)),
                                ),
                                child: Row(
                                  children: [
                                    const CircleAvatar(
                                      radius: 16,
                                      backgroundColor: Colors.tealAccent,
                                      child: Icon(Icons.edit_note, size: 18, color: Colors.black),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            filteredProds.isEmpty ? 'No matching product found in catalog.' : 'Or use exact typed text:',
                                            style: const TextStyle(color: Colors.white54, fontSize: 11),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '+ Use "$query" as Custom Item',
                                            style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.tealAccent,
                                        foregroundColor: Colors.black,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                      onPressed: () async {
                                        final localLang = HinglishTranslator.translateToHinglish(query);
                                        final customItem = _SelectedItem(
                                          customName: query,
                                          localName: localLang,
                                          quantity: 1.0,
                                          selectedUnit: 'Pcs',
                                        );
                                        final res = await _showEditItemQuantityAndUnitDialog(
                                          context,
                                          title: query,
                                          initialLocalName: localLang,
                                          initialUnit: 'Pcs',
                                          initialQty: 1.0,
                                          isCustom: true,
                                        );
                                        if (res != null && res.quantity > 0) {
                                          if (res.customName.isNotEmpty) customItem.customName = res.customName;
                                          customItem.localName = res.localName;
                                          customItem.quantity = res.quantity;
                                          customItem.selectedUnit = res.unit;

                                          final provider = Provider.of<FinanceProvider>(context, listen: false);
                                          final exists = provider.products.any((p) => p.productName.toLowerCase() == customItem.customName.toLowerCase());
                                          if (!exists && customItem.customName.isNotEmpty) {
                                            provider.addProduct(Product(
                                              productName: customItem.customName,
                                              localName: customItem.localName,
                                              unit: customItem.selectedUnit,
                                              quantity: customItem.quantity,
                                              category: selectedCategory == 'All' ? 'General' : selectedCategory,
                                            ));
                                          }

                                          setModalState(() {
                                            selectedItems.add(customItem);
                                            searchCtrl.clear();
                                            query = '';
                                          });
                                        }
                                      },
                                      child: const Text('+ Use Custom', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // Catalog Products List
                            if (filteredProds.isNotEmpty) ...[
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 6.0),
                                child: Text('MATCHING PRODUCTS MASTER', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                              ),
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: filteredProds.length,
                                separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white10),
                                itemBuilder: (context, idx) {
                                  final p = filteredProds[idx];
                                  final existingIdx = selectedItems.indexWhere((i) => i.product?.id == p.id);
                                  final isSelected = existingIdx != -1;

                                  return ListTile(
                                    dense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    leading: CircleAvatar(
                                      radius: 16,
                                      backgroundColor: Colors.tealAccent.withValues(alpha: 0.15),
                                      child: Text(p.productName.isNotEmpty ? p.productName[0].toUpperCase() : '?', style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                                    ),
                                    title: Row(
                                      children: [
                                        Text(p.productName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                        if (p.localName.isNotEmpty) ...[
                                          const SizedBox(width: 6),
                                          Text('(${p.localName})', style: const TextStyle(color: Colors.amberAccent, fontSize: 11)),
                                        ],
                                      ],
                                    ),
                                    subtitle: Text(
                                       '🏷️ ${p.category} • ${provider.defaultCurrency}${p.effectivePrice.toStringAsFixed(0)} / ${p.quantity.toStringAsFixed(p.quantity == p.quantity.roundToDouble() ? 0 : 1)} ${p.unit}'
                                       '${p.appName.isNotEmpty ? " • ${p.appName}" : ""}',
                                       style: const TextStyle(color: Colors.white54, fontSize: 11),
                                     ),
                                    trailing: isSelected
                                        ? Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                                                onPressed: () {
                                                  setModalState(() {
                                                    if (selectedItems[existingIdx].quantity > 1) {
                                                      selectedItems[existingIdx].quantity -= 1;
                                                    } else {
                                                      selectedItems.removeAt(existingIdx);
                                                    }
                                                  });
                                                },
                                              ),
                                              InkWell(
                                                onTap: () async {
                                                  final res = await _showEditItemQuantityAndUnitDialog(
                                                    context,
                                                    title: p.productName,
                                                    initialLocalName: p.localName,
                                                    initialUnit: selectedItems[existingIdx].selectedUnit,
                                                    initialQty: selectedItems[existingIdx].quantity,
                                                  );
                                                  if (res != null) {
                                                    setModalState(() {
                                                      if (res.quantity <= 0) {
                                                        selectedItems.removeAt(existingIdx);
                                                      } else {
                                                        selectedItems[existingIdx].quantity = res.quantity;
                                                        selectedItems[existingIdx].selectedUnit = res.unit;
                                                      }
                                                    });
                                                  }
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.tealAccent.withValues(alpha: 0.15),
                                                    borderRadius: BorderRadius.circular(8),
                                                    border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.4)),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        '${_formatQuantity(selectedItems[existingIdx].quantity)} ${selectedItems[existingIdx].selectedUnit}',
                                                        style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 12),
                                                      ),
                                                      const SizedBox(width: 3),
                                                      const Icon(Icons.edit, size: 11, color: Colors.tealAccent),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.add_circle_outline, color: Colors.tealAccent, size: 20),
                                                onPressed: () {
                                                  setModalState(() {
                                                    selectedItems[existingIdx].quantity += 1;
                                                  });
                                                },
                                              ),
                                            ],
                                          )
                                        : ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.white.withValues(alpha: 0.1),
                                              foregroundColor: Colors.tealAccent,
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            ),
                                            onPressed: () {
                                              setModalState(() {
                                                selectedItems.add(_SelectedItem(product: p, unitPrice: p.effectivePrice, quantity: 1.0, selectedUnit: p.unit));
                                              });
                                            },
                                            child: const Text('+ Add', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                          ),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // Selected Items Summary & Apply Button
                    if (selectedItems.isNotEmpty) ...[
                      const Divider(color: Colors.white24, height: 16),
                      const Text('SELECTED ITEMS SUMMARY (Tap to edit qty & unit)', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: selectedItems.map((item) {
                          final nameToUse = item.product != null
                              ? (item.product!.localName.trim().isNotEmpty ? item.product!.localName.trim() : item.product!.productName.trim())
                              : (item.localName.trim().isNotEmpty ? '${item.customName} (${item.localName})' : item.customName);
                          final label = '$nameToUse (${_formatQuantity(item.quantity)} ${item.selectedUnit}) ✏️';
                          return ActionChip(
                            backgroundColor: Colors.tealAccent.withValues(alpha: 0.2),
                            labelStyle: const TextStyle(color: Colors.tealAccent, fontSize: 11, fontWeight: FontWeight.bold),
                            label: Text(label),
                            onPressed: () async {
                              final res = await _showEditItemQuantityAndUnitDialog(
                                context,
                                title: item.product?.productName ?? item.customName,
                                initialLocalName: item.product?.localName ?? item.localName,
                                initialUnit: item.selectedUnit,
                                initialQty: item.quantity,
                                isCustom: item.product == null,
                              );
                              if (res != null) {
                                setModalState(() {
                                  if (res.quantity <= 0) {
                                    selectedItems.remove(item);
                                  } else {
                                    if (item.product == null && res.customName.isNotEmpty) {
                                      item.customName = res.customName;
                                    }
                                    item.localName = res.localName;
                                    item.quantity = res.quantity;
                                    item.selectedUnit = res.unit;
                                  }
                                });
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ],

                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.tealAccent,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          if (selectedItems.isNotEmpty) {
                            String newItemsStr = '';
                            if (selectedItems.length == 1) {
                              final single = selectedItems.first;
                              if (single.product != null) {
                                final nameToUse = single.product!.localName.trim().isNotEmpty ? single.product!.localName.trim() : single.product!.productName.trim();
                                newItemsStr = '$nameToUse (${_formatQuantity(single.quantity)} ${single.selectedUnit})';
                              } else {
                                final nameToUse = single.localName.trim().isNotEmpty ? '${single.customName} (${single.localName})' : single.customName;
                                newItemsStr = '$nameToUse (${_formatQuantity(single.quantity)} ${single.selectedUnit})';
                              }
                            } else {
                              newItemsStr = selectedItems.map((item) {
                                if (item.product != null) {
                                  final nameToUse = item.product!.localName.trim().isNotEmpty ? item.product!.localName.trim() : item.product!.productName.trim();
                                  return '• $nameToUse (${_formatQuantity(item.quantity)} ${item.selectedUnit})';
                                } else {
                                  final nameToUse = item.localName.trim().isNotEmpty ? '${item.customName} (${item.localName})' : item.customName;
                                  return '• $nameToUse (${_formatQuantity(item.quantity)} ${item.selectedUnit})';
                                }
                              }).join('\n');
                            }

                            final existingText = _itemController.text.trim();
                            if (existingText.isEmpty) {
                              _itemController.text = newItemsStr;
                            } else {
                              _itemController.text = '$existingText\n$newItemsStr';
                            }

                            if (totalCalcCost > 0) {
                              final existingCost = double.tryParse(_costController.text.trim()) ?? 0.0;
                              final newTotal = existingCost + totalCalcCost;
                              _costController.text = newTotal.toStringAsFixed(0);
                              if (_cleared) {
                                _paidController.text = newTotal.toStringAsFixed(0);
                              }
                            }

                            _stagedChildItems.addAll(selectedItems.map((item) {
                              return TransactionItem(
                                productId: item.product?.id,
                                itemName: item.product?.productName ?? item.customName,
                                localName: item.product?.localName ?? item.localName,
                                category: item.product?.category ?? 'General',
                                quantity: item.quantity,
                                unit: item.selectedUnit,
                                unitPrice: item.unitPrice,
                                totalPrice: item.totalPrice,
                              );
                            }));

                            setState(() {});
                          }
                          Navigator.pop(ctx);
                        },
                        child: Text(
                          selectedItems.isNotEmpty
                              ? 'Add ${selectedItems.length} Item(s) (${provider.defaultCurrency}${totalCalcCost.toStringAsFixed(0)})'
                              : 'Close',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildShopPicklistField(FinanceProvider provider) {
    final contacts = provider.activeContacts;
    final currentText = _shopController.text.trim();

    if (!_isCustomShopInput && contacts.isNotEmpty) {
      String? selectedValue;
      for (var c in contacts) {
        if (c.name.toLowerCase() == currentText.toLowerCase() || (c.businessName.isNotEmpty && c.businessName.toLowerCase() == currentText.toLowerCase())) {
          selectedValue = c.name;
          break;
        }
      }

      return DropdownButtonFormField<String>(
        value: selectedValue,
        dropdownColor: const Color(0xFF121422),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: 'Shop / Merchant / Contact Name (Picklist)',
          prefixIcon: const Icon(Icons.storefront, color: Colors.tealAccent),
          suffixIcon: IconButton(
            icon: const Icon(Icons.edit_note, color: Colors.tealAccent),
            tooltip: 'Type Custom Name',
            onPressed: () {
              setState(() {
                _isCustomShopInput = true;
              });
            },
          ),
          border: const OutlineInputBorder(),
        ),
        hint: const Text('Select contact/shop from picklist...', style: TextStyle(color: Colors.white54)),
        items: [
          const DropdownMenuItem<String>(
            value: '',
            child: Text('-- None / Clear --', style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic)),
          ),
          ...contacts.map((c) {
            final label = c.businessName.isNotEmpty ? '${c.name} (${c.businessName})' : c.name;
            return DropdownMenuItem<String>(
              value: c.name,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person, size: 14, color: Colors.tealAccent),
                  const SizedBox(width: 8),
                  Flexible(child: Text(label, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white))),
                  if (c.transactionNotification) ...[
                    const SizedBox(width: 6),
                    Icon(
                      c.notificationMethod == 'WhatsApp' ? Icons.chat_bubble : Icons.sms,
                      size: 12,
                      color: c.notificationMethod == 'WhatsApp' ? const Color(0xFF25D366) : Colors.blueAccent,
                    ),
                  ],
                ],
              ),
            );
          }),
          const DropdownMenuItem<String>(
            value: '__CUSTOM__',
            child: Text('✏️ + Type New Custom Shop Name', style: TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold)),
          ),
        ],
        onChanged: (val) {
          if (val == '__CUSTOM__') {
            setState(() {
              _isCustomShopInput = true;
              _shopController.clear();
            });
          } else {
            setState(() {
              _shopController.text = val ?? '';
            });
          }
        },
      );
    }

    return TextFormField(
      controller: _shopController,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Shop / Merchant / Contact Name (Optional)',
        hintText: 'Type shop name...',
        prefixIcon: const Icon(Icons.storefront, color: Colors.tealAccent),
        suffixIcon: contacts.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.arrow_drop_down_circle, color: Colors.tealAccent),
                tooltip: 'Select from Picklist Dropdown',
                onPressed: () {
                  setState(() {
                    _isCustomShopInput = false;
                  });
                },
              )
            : null,
        border: const OutlineInputBorder(),
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);
    final isEdit = widget.transaction != null;

    // Set selected category & accounts
    if (widget.transaction != null && _selectedCategory == null && _transactionType != 'Transfer') {
      try {
        _selectedCategory = provider.categories.firstWhere((c) => c.id == widget.transaction!.categoryId);
      } catch (e) {
        if (provider.categories.isNotEmpty) _selectedCategory = provider.categories.first;
      }
    } else if (_selectedCategory == null && provider.categories.isNotEmpty) {
      _selectedCategory = provider.categories.first;
    }

    if (_selectedAccount == null && provider.accounts.isNotEmpty) {
      _selectedAccount = provider.accounts.first;
    }

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
                isEdit ? 'Edit Transaction' : 'New Transaction Entry',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment<String>(value: 'Expense', label: Text('Expense')),
                  ButtonSegment<String>(value: 'Income', label: Text('Income')),
                  ButtonSegment<String>(value: 'Transfer', label: Text('Transfer')),
                ],
                selected: {_transactionType},
                onSelectionChanged: (val) => setState(() => _transactionType = val.first),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}', style: const TextStyle(color: Colors.white)),
                trailing: const Icon(Icons.calendar_today, color: Color(0xFF6366F1)),
                onTap: () async {
                  final picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2000), lastDate: DateTime(2101));
                  if (picked != null) setState(() => _selectedDate = picked);
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<WalletAccount>(
                initialValue: _selectedAccount,
                dropdownColor: const Color(0xFF121422),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Pay From Account', border: OutlineInputBorder()),
                items: provider.accounts.map((a) => DropdownMenuItem(value: a, child: Text(a.name))).toList(),
                onChanged: (val) => setState(() => _selectedAccount = val),
              ),
              const SizedBox(height: 12),
              if (_transactionType != 'Transfer') ...[
                DropdownButtonFormField<Category>(
                  initialValue: _selectedCategory,
                  dropdownColor: const Color(0xFF121422),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                  items: provider.categories.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                  onChanged: (val) => setState(() => _selectedCategory = val),
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _itemController,
                style: const TextStyle(color: Colors.white),
                maxLines: null,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  labelText: 'Item / Service Name',
                  hintText: 'Select from Catalog or Scan Product...',
                  prefixIcon: const Icon(Icons.shopping_bag, color: Colors.tealAccent),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.qr_code_scanner, color: Colors.tealAccent, size: 24),
                        tooltip: 'Scan Product Barcode / Label',
                        onPressed: () => _showProductScannerModal(context, provider),
                      ),
                      IconButton(
                        icon: const Icon(Icons.manage_search, color: Colors.tealAccent, size: 24),
                        tooltip: 'Select Product from Catalog',
                        onPressed: () => _showProductSelectionModal(context, provider),
                      ),
                    ],
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: (val) => val!.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              SearchablePicklistField(
                controller: _shopController,
                labelText: 'Shop / Merchant / Contact Name (Optional)',
                hintText: 'Type to search or select contact...',
                prefixIcon: Icons.storefront,
                provider: provider,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _costController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Total Cost (₹)', border: OutlineInputBorder()),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (v) {
                        if (_cleared) _paidController.text = v;
                      },
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _paidController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Paid Amount (₹)', border: OutlineInputBorder()),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tagsController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Tags (comma separated)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),
              if (isEdit)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () async {
                          if (widget.transaction?.id != null) {
                            await provider.deleteTransaction(widget.transaction!.id!);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Transaction moved to Deleted Records')),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Delete', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _submit,
                        child: const Text('Update Transaction', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                )
              else
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _submit,
                  child: const Text('Save Transaction', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// SHOP / MERCHANT MONTHLY BILL LEDGER SHEET
// -------------------------------------------------------------
bool _isPaymentSettlementTx(DailyTransaction tx) {
  if (tx.tags.contains('due-settlement') || tx.tags.contains('due_payment')) return true;
  final itemLower = tx.itemService.toLowerCase();
  if (itemLower.startsWith('payment for') && itemLower.contains('due')) return true;
  if (tx.note.toLowerCase().contains('settlement of') || tx.note.toLowerCase().contains('due-settlement')) return true;
  return false;
}

class ShopLedgerSheet extends StatefulWidget {
  const ShopLedgerSheet({super.key});

  @override
  State<ShopLedgerSheet> createState() => _ShopLedgerSheetState();
}

class _ShopLedgerSheetState extends State<ShopLedgerSheet> {
  int? _selectedMonth = DateTime.now().month; // null = All months
  int _selectedYear = DateTime.now().year;
  String _selectedShop = 'All'; // 'All' or specific shop name
  bool _onlyDueFilter = false;

  void _shareShopInvoice(BuildContext context, String shopName, double totalCost, double totalPaid, double totalDue, List<DailyTransaction> shopTxs) {
    final monthText = _selectedMonth != null
        ? DateFormat('MMMM yyyy').format(DateTime(_selectedYear, _selectedMonth!))
        : 'Year $_selectedYear';

    // EXCLUDE payment settlement transactions from purchase items list
    final purchaseTxs = shopTxs.where((tx) => !_isPaymentSettlementTx(tx)).toList();
    final itemsList = purchaseTxs.map((tx) {
      final dt = DateTime.tryParse(tx.date) ?? DateTime.now();
      final dateStr = DateFormat('MMM dd').format(dt);
      return {
        'date': dateStr,
        'desc': tx.itemService,
        'cost': tx.cost,
        'paid': tx.paidAmount,
      };
    }).toList();

    final provider = Provider.of<FinanceProvider>(context, listen: false);

    // Calculate shop-specific purchase-only Total Billed
    final double purchaseBilled = purchaseTxs.fold(0.0, (s, t) => s + t.cost);

    // All-time pending due across all history for this shop
    final allTimeShopTxs = provider.transactions.where((t) {
      final matchesName = t.merchantName.toLowerCase() == shopName.toLowerCase();
      final matchesTag = t.tags.contains('shop:${shopName.toLowerCase()}');
      return matchesName || matchesTag;
    }).toList();
    final allTimePurchaseTxs = allTimeShopTxs.where((t) => !_isPaymentSettlementTx(t)).toList();
    final double allTimeBilled = allTimePurchaseTxs.fold(0.0, (s, t) => s + t.cost);
    final double allTimePaid = allTimeShopTxs.fold(0.0, (s, t) => s + t.paidAmount);
    final double allTimePendingDue = (allTimeBilled - allTimePaid) > 0 ? (allTimeBilled - allTimePaid) : 0.0;

    Contact? matchedContact;
    try {
      matchedContact = provider.contacts.firstWhere(
        (c) => c.name.toLowerCase() == shopName.toLowerCase() ||
               (c.businessName.isNotEmpty && c.businessName.toLowerCase() == shopName.toLowerCase()),
      );
    } catch (_) {}

    final String displayContactName = matchedContact?.name ?? shopName;
    final String displayBusinessName = matchedContact != null && matchedContact.businessName.isNotEmpty
        ? matchedContact.businessName
        : (matchedContact != null ? '' : (shopName != displayContactName ? shopName : ''));

    final msg = MessagingUtils.formatMonthlyStatementMessage(
      contactName: displayContactName,
      businessName: displayBusinessName,
      monthYearStr: monthText,
      items: itemsList,
      totalCost: purchaseBilled,
      totalPaid: totalPaid,
      monthPendingDue: totalDue,
      allTimePendingDue: allTimePendingDue,
      isWhatsApp: true,
    );

    MessagingUtils.showShareOptionsModal(
      context,
      title: 'Share Monthly Bill Statement',
      message: msg,
      contactName: displayContactName,
      mobileNumber: matchedContact?.mobile,
    );
  }

  void _settleShopDues(BuildContext context, List<DailyTransaction> dueTxs, [String shopName = 'Shop', double totalDue = 0.0]) {
    final provider = Provider.of<FinanceProvider>(context, listen: false);
    final calcDue = totalDue > 0 ? totalDue : dueTxs.fold(0.0, (s, t) => s + (t.cost - t.paidAmount));
    final amountCtrl = TextEditingController(text: calcDue.toStringAsFixed(0));
    DateTime paymentDate = DateTime.now();
    WalletAccount? selectedAccount = provider.accounts.isNotEmpty ? provider.accounts.first : null;
    bool recordTransaction = true;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final accounts = provider.accounts;
            return AlertDialog(
              backgroundColor: const Color(0xFF1E2238),
              title: Row(
                children: [
                  const Icon(Icons.payment, color: Colors.tealAccent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Pay Dues ($shopName)', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Pending Due:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                          Text('${provider.defaultCurrency}${calcDue.toStringAsFixed(0)}', style: const TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    const Text('Payment Amount (Partial or Full):', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.tealAccent, fontSize: 18, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        prefixText: '${provider.defaultCurrency} ',
                        prefixStyle: const TextStyle(color: Colors.tealAccent, fontSize: 18, fontWeight: FontWeight.bold),
                        border: const OutlineInputBorder(),
                        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.tealAccent, width: 2)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Date Picker
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Payment Date:', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                        TextButton.icon(
                          icon: const Icon(Icons.calendar_today, size: 14, color: Colors.tealAccent),
                          label: Text(DateFormat('dd MMM yyyy').format(paymentDate), style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold)),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: paymentDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setDialogState(() {
                                paymentDate = picked;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Account Dropdown
                    if (accounts.isNotEmpty) ...[
                      const Text('Payment Account:', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<WalletAccount>(
                        value: selectedAccount ?? accounts.first,
                        dropdownColor: const Color(0xFF1E2238),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        items: accounts.map((acc) {
                          return DropdownMenuItem<WalletAccount>(
                            value: acc,
                            child: Text('${acc.name} (Bal: ${provider.defaultCurrency}${acc.initialBalance.toStringAsFixed(0)})'),
                          );
                        }).toList(),
                        onChanged: (acc) {
                          if (acc != null) setDialogState(() => selectedAccount = acc);
                        },
                      ),
                      const SizedBox(height: 12),
                    ],

                    Row(
                      children: [
                        Checkbox(
                          value: recordTransaction,
                          activeColor: Colors.tealAccent,
                          checkColor: Colors.black,
                          onChanged: (val) {
                            setDialogState(() => recordTransaction = val ?? true);
                          },
                        ),
                        const Expanded(
                          child: Text('Record expense transaction with date', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.tealAccent,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () {
                    final payAmt = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                    if (payAmt <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid payment amount.')),
                      );
                      return;
                    }

                    double paymentLeft = payAmt;
                    for (var tx in dueTxs) {
                      if (paymentLeft <= 0) break;
                      double remainingDue = tx.cost - tx.paidAmount;
                      if (remainingDue > 0) {
                        double payForThis = paymentLeft >= remainingDue ? remainingDue : paymentLeft;
                        double newPaid = tx.paidAmount + payForThis;
                        paymentLeft -= payForThis;

                        final updated = DailyTransaction(
                          id: tx.id,
                          date: tx.date,
                          categoryId: tx.categoryId,
                          itemService: tx.itemService,
                          cost: tx.cost,
                          paidAmount: newPaid,
                          cleared: newPaid >= tx.cost,
                          accountId: tx.accountId,
                          toAccountId: tx.toAccountId,
                          transactionType: tx.transactionType,
                          tags: tx.tags,
                          note: tx.note,
                          merchantName: tx.merchantName,
                        );
                        provider.updateTransaction(updated);
                      }
                    }

                    if (recordTransaction) {
                      final paymentTx = DailyTransaction(
                        date: paymentDate.toIso8601String(),
                        categoryId: dueTxs.isNotEmpty ? dueTxs.first.categoryId : 1,
                        itemService: 'Payment for $shopName Dues',
                        cost: payAmt,
                        paidAmount: payAmt,
                        cleared: true,
                        accountId: selectedAccount?.id ?? 1,
                        transactionType: 'Expense',
                        tags: ['shop:${shopName.toLowerCase()}', 'due-settlement'],
                        note: 'Payment of ${provider.defaultCurrency}${payAmt.toStringAsFixed(0)} for $shopName',
                        merchantName: shopName,
                      );
                      provider.addTransaction(paymentTx);
                    }

                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✅ Paid ${provider.defaultCurrency}${payAmt.toStringAsFixed(0)} for $shopName on ${DateFormat('dd MMM yyyy').format(paymentDate)}.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  child: const Text('Record Payment', style: TextStyle(fontWeight: FontWeight.bold)),
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

    // Extract all transactions that have a merchant name or shop tag
    final allShopTxs = provider.transactions.where((tx) {
      return tx.merchantName.isNotEmpty || tx.tags.any((t) => t.startsWith('shop:'));
    }).toList();

    // Extract unique shop names
    final Set<String> shopsSet = {};
    for (var tx in allShopTxs) {
      if (tx.merchantName.isNotEmpty) {
        shopsSet.add(toTitleCase(tx.merchantName.trim()));
      }
      for (var t in tx.tags) {
        if (t.startsWith('shop:')) {
          shopsSet.add(toTitleCase(t.substring(5).trim()));
        }
      }
    }
    final sortedShops = shopsSet.where((s) => s.isNotEmpty).toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    final shopsList = ['All', ...sortedShops];

    // Filter transactions by Month, Year, and Shop
    final filteredTxs = allShopTxs.where((tx) {
      final dt = DateTime.tryParse(tx.date) ?? DateTime.now();
      if (dt.year != _selectedYear) return false;
      if (_selectedMonth != null && dt.month != _selectedMonth) return false;
      if (_selectedShop != 'All') {
        final matchesName = tx.merchantName.toLowerCase() == _selectedShop.toLowerCase();
        final matchesTag = tx.tags.contains('shop:${_selectedShop.toLowerCase()}');
        if (!matchesName && !matchesTag) return false;
      }
      if (_onlyDueFilter && tx.cost <= tx.paidAmount) return false;
      return true;
    }).toList();

    // Cumulative Calculations (Purchase bills only for Total Billed)
    final purchaseTxs = filteredTxs.where((tx) => !_isPaymentSettlementTx(tx)).toList();
    final double totalBilled = purchaseTxs.fold(0.0, (sum, tx) => sum + tx.cost);
    final double totalPaid = filteredTxs.fold(0.0, (sum, tx) => sum + tx.paidAmount);
    final double monthPendingDue = (totalBilled - totalPaid) > 0 ? (totalBilled - totalPaid) : 0.0;

    // All-time pending dues across all history for selected shop(s)
    final allTimeShopTxs = allShopTxs.where((tx) {
      if (_selectedShop != 'All') {
        final matchesName = tx.merchantName.toLowerCase() == _selectedShop.toLowerCase();
        final matchesTag = tx.tags.contains('shop:${_selectedShop.toLowerCase()}');
        return matchesName || matchesTag;
      }
      return true;
    }).toList();
    final allTimePurchaseTxs = allTimeShopTxs.where((tx) => !_isPaymentSettlementTx(tx)).toList();
    final double allTimeBilled = allTimePurchaseTxs.fold(0.0, (sum, tx) => sum + tx.cost);
    final double allTimePaid = allTimeShopTxs.fold(0.0, (sum, tx) => sum + tx.paidAmount);
    final double allTimePendingDue = (allTimeBilled - allTimePaid) > 0 ? (allTimeBilled - allTimePaid) : 0.0;

    // Group filtered transactions by shop name
    final Map<String, List<DailyTransaction>> shopGroups = {};
    for (var tx in filteredTxs) {
      String sName = tx.merchantName.isNotEmpty ? toTitleCase(tx.merchantName) : 'Other Merchants';
      if (tx.merchantName.isEmpty) {
        for (var t in tx.tags) {
          if (t.startsWith('shop:')) {
            sName = toTitleCase(t.substring(5).trim());
            break;
          }
        }
      }
      shopGroups.putIfAbsent(sName, () => []).add(tx);
    }

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF080914),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      height: MediaQuery.of(context).size.height * 0.9,
      padding: EdgeInsets.only(
        top: 12,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Shop Bills & Monthly Ledgers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              Row(
                children: [
                  FilterChip(
                    avatar: Icon(Icons.warning_amber_rounded, size: 12, color: _onlyDueFilter ? Colors.black : Colors.redAccent),
                    label: Text('Due Only', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _onlyDueFilter ? Colors.black : Colors.white)),
                    selected: _onlyDueFilter,
                    selectedColor: Colors.redAccent,
                    backgroundColor: const Color(0xFF121422),
                    onSelected: (v) => setState(() => _onlyDueFilter = v),
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text('${filteredTxs.length} Entries', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 11)),
                    backgroundColor: Colors.tealAccent,
                    side: BorderSide.none,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Filters Row: Month, Year, Shop
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int?>(
                  initialValue: _selectedMonth,
                  dropdownColor: const Color(0xFF121422),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: const InputDecoration(labelText: 'Month', isDense: true, border: OutlineInputBorder()),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('All Months')),
                    ...List.generate(12, (i) => i + 1).map((m) => DropdownMenuItem<int?>(
                          value: m,
                          child: Text(['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][m - 1]),
                        )),
                  ],
                  onChanged: (v) => setState(() => _selectedMonth = v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _selectedYear,
                  dropdownColor: const Color(0xFF121422),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: const InputDecoration(labelText: 'Year', isDense: true, border: OutlineInputBorder()),
                  items: List.generate(5, (i) => DateTime.now().year - 2 + i).map((y) => DropdownMenuItem(value: y, child: Text(y.toString()))).toList(),
                  onChanged: (v) => setState(() => _selectedYear = v!),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedShop,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF121422),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: const InputDecoration(labelText: 'Shop', isDense: true, border: OutlineInputBorder()),
                  items: shopsList.map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (v) => setState(() => _selectedShop = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Monthly & All-Time Metrics Summary Card
          Card(
            color: const Color(0xFF121422),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Billed', style: TextStyle(color: Colors.grey, fontSize: 10)),
                          const SizedBox(height: 4),
                          Text('₹${totalBilled.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Paid', style: TextStyle(color: Colors.grey, fontSize: 10)),
                          const SizedBox(height: 4),
                          Text('₹${totalPaid.toStringAsFixed(0)}', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Month Due', style: TextStyle(color: Colors.grey, fontSize: 10)),
                          const SizedBox(height: 4),
                          Text('₹${monthPendingDue.toStringAsFixed(0)}', style: TextStyle(color: monthPendingDue > 0 ? Colors.amberAccent : Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('All Pending Due', style: TextStyle(color: Colors.grey, fontSize: 10)),
                          const SizedBox(height: 4),
                          Text('₹${allTimePendingDue.toStringAsFixed(0)}', style: TextStyle(color: allTimePendingDue > 0 ? Colors.redAccent : Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Shop Grouped Ledgers List
          Expanded(
            child: shopGroups.isEmpty
                ? const Center(child: Text('No shop entries recorded for this period.', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    itemCount: shopGroups.keys.length,
                    itemBuilder: (context, idx) {
                      final shopName = shopGroups.keys.elementAt(idx);
                      final txs = shopGroups[shopName]!;
                      final shopPurchaseTxs = txs.where((t) => !_isPaymentSettlementTx(t)).toList();
                      final shopTotalCost = shopPurchaseTxs.fold(0.0, (s, t) => s + t.cost); // Purchase bills only
                      final shopTotalPaid = txs.fold(0.0, (s, t) => s + t.paidAmount);
                      final shopTotalDue = (shopTotalCost - shopTotalPaid) > 0 ? (shopTotalCost - shopTotalPaid) : 0.0;
                      final dueTxs = txs.where((t) => t.cost > t.paidAmount).toList();

                      return Card(
                        color: const Color(0xFF121422),
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text('🛒 $shopName', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white), overflow: TextOverflow.ellipsis),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.share, color: Colors.tealAccent, size: 18),
                                    tooltip: 'Share Shop Invoice Summary',
                                    onPressed: () => _shareShopInvoice(context, shopName, shopTotalCost, shopTotalPaid, shopTotalDue, txs),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Billed: ₹${shopTotalCost.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                  Text('Paid: ₹${shopTotalPaid.toStringAsFixed(0)}', style: const TextStyle(color: Colors.greenAccent, fontSize: 12)),
                                  Text('Due: ₹${shopTotalDue.toStringAsFixed(0)}', style: TextStyle(color: shopTotalDue > 0 ? Colors.redAccent : Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                                ],
                              ),
                              if (dueTxs.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.check_circle_outline, size: 16),
                                    label: Text('Pay Pending Dues (₹${shopTotalDue.toStringAsFixed(0)})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.tealAccent,
                                      foregroundColor: Colors.black,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: () => _settleShopDues(context, dueTxs, shopName, shopTotalDue),
                                  ),
                                ),
                              ],
                              const Divider(height: 16, color: Colors.white12),
                              ...txs.map((tx) {
                                final dt = DateTime.tryParse(tx.date) ?? DateTime.now();
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${DateFormat('MMM dd').format(dt)} - ${tx.itemService}',
                                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        '₹${tx.cost.toStringAsFixed(0)} ${tx.cost > tx.paidAmount ? "(Due: ₹${(tx.cost - tx.paidAmount).toStringAsFixed(0)})" : ""}',
                                        style: TextStyle(color: tx.cost > tx.paidAmount ? Colors.redAccent : Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
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

class SearchablePicklistField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final IconData prefixIcon;
  final FinanceProvider provider;
  final FormFieldValidator<String>? validator;

  const SearchablePicklistField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.hintText,
    required this.prefixIcon,
    required this.provider,
    this.validator,
  });

  @override
  State<SearchablePicklistField> createState() => _SearchablePicklistFieldState();
}

class _SearchablePicklistFieldState extends State<SearchablePicklistField> {
  bool _isOpen = false;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _hideOverlay();
    super.dispose();
  }

  void _showOverlay() {
    if (_isOpen) return;
    final contacts = widget.provider.activeContacts;

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          width: size.width,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(0, size.height + 4),
            child: Material(
              elevation: 8,
              color: const Color(0xFF1E2238),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.tealAccent.withValues(alpha: 0.3)),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: widget.controller,
                  builder: (context, value, _) {
                    final query = value.text.trim().toLowerCase();
                    final filtered = contacts.where((c) {
                      if (query.isEmpty) return true;
                      return c.name.toLowerCase().contains(query) ||
                          c.businessName.toLowerCase().contains(query) ||
                          c.occupation.toLowerCase().contains(query) ||
                          c.place.toLowerCase().contains(query) ||
                          c.mobile.contains(query);
                    }).toList();

                    if (filtered.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          query.isEmpty ? 'No active contacts in directory' : 'No match for "$query" (will save as custom name)',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white10),
                      itemBuilder: (context, index) {
                        final c = filtered[index];
                        final subText = [
                          if (c.businessName.isNotEmpty) c.businessName,
                          if (c.occupation.isNotEmpty) c.occupation,
                          if (c.place.isNotEmpty) c.place,
                        ].join(' • ');

                        return ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          leading: CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.tealAccent.withValues(alpha: 0.15),
                            child: Text(
                              c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                              style: const TextStyle(color: Colors.tealAccent, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(c.name, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                          subtitle: subText.isNotEmpty ? Text(subText, style: const TextStyle(color: Colors.white54, fontSize: 10)) : null,
                          trailing: c.transactionNotification
                              ? Icon(
                                  c.notificationMethod == 'WhatsApp' ? Icons.chat_bubble : Icons.sms,
                                  size: 14,
                                  color: c.notificationMethod == 'WhatsApp' ? const Color(0xFF25D366) : Colors.blueAccent,
                                )
                              : null,
                          onTap: () {
                            widget.controller.text = c.name;
                            _hideOverlay();
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _isOpen = true;
    });
  }

  void _hideOverlay() {
    if (!_isOpen) return;
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) {
      setState(() {
        _isOpen = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        controller: widget.controller,
        style: const TextStyle(color: Colors.white),
        validator: widget.validator,
        decoration: InputDecoration(
          labelText: widget.labelText,
          hintText: widget.hintText,
          prefixIcon: Icon(widget.prefixIcon, color: Colors.tealAccent),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.controller.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear, size: 18, color: Colors.white54),
                  onPressed: () {
                    widget.controller.clear();
                    setState(() {});
                  },
                ),
              IconButton(
                icon: Icon(_isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down, color: Colors.tealAccent),
                onPressed: () {
                  if (_isOpen) {
                    _hideOverlay();
                  } else {
                    _showOverlay();
                  }
                },
              ),
            ],
          ),
          border: const OutlineInputBorder(),
        ),
        onTap: () {
          if (!_isOpen) {
            _showOverlay();
          }
        },
        onChanged: (_) {
          if (!_isOpen) {
            _showOverlay();
          }
        },
      ),
    );
  }
}

class _SelectedItem {
  final Product? product;
  String customName;
  String localName;
  double quantity;
  double unitPrice;
  String selectedUnit;

  _SelectedItem({
    this.product,
    this.customName = '',
    this.localName = '',
    this.quantity = 1.0,
    this.unitPrice = 0.0,
    String? selectedUnit,
  }) : selectedUnit = selectedUnit ?? (product?.unit ?? 'Pcs');

  double get totalPrice => unitPrice * quantity;
}

String _formatQuantity(double q) {
  if (q == q.roundToDouble()) {
    return q.toInt().toString();
  }
  return q.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
}

class _ItemQtyUnitResult {
  final String customName;
  final String localName;
  final double quantity;
  final String unit;
  _ItemQtyUnitResult({
    this.customName = '',
    this.localName = '',
    required this.quantity,
    required this.unit,
  });
}

Future<_ItemQtyUnitResult?> _showEditItemQuantityAndUnitDialog(
  BuildContext context, {
  required String title,
  String initialLocalName = '',
  required String initialUnit,
  required double initialQty,
  bool isCustom = false,
}) {
  final nameCtrl = TextEditingController(text: title);
  final localNameCtrl = TextEditingController(
    text: initialLocalName.isNotEmpty
        ? initialLocalName
        : (isCustom ? HinglishTranslator.translateToHinglish(title) : ''),
  );
  final qtyCtrl = TextEditingController(text: _formatQuantity(initialQty));
  String currentUnit = initialUnit;
  final List<String> availableUnits = [
    'Pcs', 'Kg', 'Gram', 'Ltr', 'Ml', 'Pack', 'Box', 'Dozen', 'Bottle', 'Strip', 'Gm', 'Meter'
  ];
  if (!availableUnits.contains(currentUnit)) {
    availableUnits.insert(0, currentUnit);
  }

  return showDialog<_ItemQtyUnitResult>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E2238),
            title: Text(
              isCustom ? 'Custom Item Details' : 'Set Quantity & Unit ($title)',
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isCustom) ...[
                    const Text('Item Name (English / Primary):', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: nameCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      onChanged: (val) {
                        if (val.trim().isNotEmpty) {
                          setDialogState(() {
                            localNameCtrl.text = HinglishTranslator.translateToHinglish(val.trim());
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Text('Local Language Name:', style: TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 18),
                          tooltip: 'Auto Translate',
                          onPressed: () async {
                            final dynamicTranslated = await HinglishTranslator.translateDynamic(nameCtrl.text);
                            setDialogState(() {
                              localNameCtrl.text = dynamicTranslated;
                            });
                          },
                        ),
                      ],
                    ),
                    TextField(
                      controller: localNameCtrl,
                      style: const TextStyle(color: Colors.amberAccent, fontSize: 14, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        hintText: 'e.g. आलू (Aloo)',
                        hintStyle: TextStyle(color: Colors.white30),
                        border: OutlineInputBorder(),
                        isDense: true,
                        prefixIcon: Icon(Icons.translate, color: Colors.amberAccent, size: 18),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  const Text('Select Unit Type:', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: availableUnits.map((u) {
                      final isSel = u == currentUnit;
                      return ChoiceChip(
                        label: Text(u, style: TextStyle(color: isSel ? Colors.black : Colors.tealAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                        selected: isSel,
                        selectedColor: Colors.tealAccent,
                        backgroundColor: Colors.white10,
                        onSelected: (selected) {
                          if (selected) {
                            setDialogState(() {
                              currentUnit = u;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  Text('Enter quantity in $currentUnit:', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: qtyCtrl,
                    style: const TextStyle(color: Colors.tealAccent, fontSize: 20, fontWeight: FontWeight.bold),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      suffixText: currentUnit,
                      suffixStyle: const TextStyle(color: Colors.white54, fontSize: 14),
                      border: const OutlineInputBorder(),
                      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.tealAccent, width: 2)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Quick Presets:', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [0.25, 0.5, 0.75, 1.0, 1.5, 2.0, 2.5, 5.0, 10.0].map((preset) {
                      return ActionChip(
                        label: Text('${_formatQuantity(preset)} $currentUnit'),
                        backgroundColor: Colors.white10,
                        labelStyle: const TextStyle(color: Colors.tealAccent, fontSize: 11, fontWeight: FontWeight.bold),
                        onPressed: () {
                          qtyCtrl.text = _formatQuantity(preset);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                onPressed: () => Navigator.pop(ctx, null),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.tealAccent,
                  foregroundColor: Colors.black,
                ),
                child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  final val = double.tryParse(qtyCtrl.text.trim());
                  if (val != null) {
                    Navigator.pop(
                      ctx,
                      _ItemQtyUnitResult(
                        customName: nameCtrl.text.trim(),
                        localName: localNameCtrl.text.trim(),
                        quantity: val,
                        unit: currentUnit,
                      ),
                    );
                  } else {
                    Navigator.pop(ctx, null);
                  }
                },
              ),
            ],
          );
        },
      );
    },
  );
}

class ProductScannerSheet extends StatefulWidget {
  final FinanceProvider provider;
  final Function(List<_SelectedItem>) onItemsScanned;

  const ProductScannerSheet({
    super.key,
    required this.provider,
    required this.onItemsScanned,
  });

  @override
  State<ProductScannerSheet> createState() => _ProductScannerSheetState();
}

class _ProductScannerSheetState extends State<ProductScannerSheet> {
  MobileScannerController? _scannerController;
  final ImagePicker _picker = ImagePicker();
  final List<_SelectedItem> _scannedItems = [];
  String _lastScannedCode = '';
  List<Product> _matchedProducts = [];
  bool _isProcessingImage = false;
  int _activeTab = 0; // 0 = Live Camera Barcode, 1 = Photo OCR

  @override
  void initState() {
    super.initState();
    _initScanner();
  }

  void _initScanner() {
    try {
      _scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
        torchEnabled: false,
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
  }

  void _processScannedCode(String rawCode) {
    final clean = rawCode.trim();
    if (clean.isEmpty || clean == _lastScannedCode) return;

    setState(() {
      _lastScannedCode = clean;
      final query = clean.toLowerCase();
      _matchedProducts = widget.provider.activeProducts.where((p) {
        return (p.barcode.isNotEmpty && p.barcode.toLowerCase() == query) ||
            (p.qrCode.isNotEmpty && p.qrCode.toLowerCase() == query) ||
            p.barcode.toLowerCase().contains(query) ||
            p.qrCode.toLowerCase().contains(query) ||
            p.productName.toLowerCase().contains(query) ||
            p.localName.toLowerCase().contains(query) ||
            p.category.toLowerCase().contains(query) ||
            p.id.toString() == query;
      }).toList();

      // If exact barcode or QR match found, auto add product with local name
      final exactMatch = widget.provider.activeProducts.firstWhere(
        (p) => (p.barcode.isNotEmpty && p.barcode.toLowerCase() == query) ||
               (p.qrCode.isNotEmpty && p.qrCode.toLowerCase() == query),
        orElse: () => Product(productName: '', priceDate: ''),
      );

      if (exactMatch.productName.isNotEmpty) {
        _addScannedProduct(exactMatch);
      }
    });
  }

  Future<void> _pickAndScanImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (image == null) return;

      setState(() {
        _isProcessingImage = true;
      });

      final isMobile = !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);
      List<String> detectedLines = [];

      if (isMobile) {
        final inputImage = InputImage.fromFilePath(image.path);
        final textRecognizer = TextRecognizer();
        final recognizedText = await textRecognizer.processImage(inputImage);
        await textRecognizer.close();

        for (var block in recognizedText.blocks) {
          for (var line in block.lines) {
            final t = line.text.trim();
            if (t.isNotEmpty && t.length > 2) {
              detectedLines.add(t);
            }
          }
        }
      } else {
        detectedLines = ['Scanned Label Item'];
      }

      if (!mounted) return;

      final List<Product> matched = [];
      for (var line in detectedLines) {
        final q = line.toLowerCase();
        for (var p in widget.provider.activeProducts) {
          if (q.contains(p.productName.toLowerCase()) || (p.localName.isNotEmpty && q.contains(p.localName.toLowerCase()))) {
            if (!matched.contains(p)) matched.add(p);
          }
        }
      }

      setState(() {
        _isProcessingImage = false;
        _matchedProducts = matched;
      });

      if (detectedLines.isNotEmpty && matched.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recognized ${detectedLines.length} text lines from image.'),
            backgroundColor: Colors.teal,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image scanning error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _addScannedProduct(Product product) {
    setState(() {
      final existingIdx = _scannedItems.indexWhere((item) => item.product?.id == product.id);
      if (existingIdx != -1) {
        _scannedItems[existingIdx].quantity += 1.0;
      } else {
        _scannedItems.add(_SelectedItem(
          product: product,
          unitPrice: product.effectivePrice,
          quantity: 1.0,
        ));
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added "${product.localName.isNotEmpty ? product.localName : product.productName}"'),
        duration: const Duration(seconds: 1),
        backgroundColor: Colors.tealAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _addCustomScannedItem(String text) {
    if (text.trim().isEmpty) return;
    final localLang = HinglishTranslator.translateToHinglish(text.trim());
    final customItem = _SelectedItem(
      customName: text.trim(),
      localName: localLang,
    );

    // Save custom item to catalog if not present
    final provider = widget.provider;
    final exists = provider.products.any((p) => p.productName.toLowerCase() == customItem.customName.toLowerCase());
    if (!exists && customItem.customName.isNotEmpty) {
      provider.addProduct(Product(
        productName: customItem.customName,
        localName: customItem.localName,
        unit: customItem.selectedUnit,
        quantity: customItem.quantity,
      ));
    }

    setState(() {
      _scannedItems.add(customItem);
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalCost = _scannedItems.fold(0.0, (sum, item) => sum + item.totalPrice);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF121422),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.qr_code_scanner, color: Colors.tealAccent),
                    SizedBox(width: 8),
                    Text(
                      'Scan Product',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Tabs: Camera Barcode Scanner vs Photo OCR
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt, size: 16),
                        SizedBox(width: 6),
                        Text('Live Barcode / QR'),
                      ],
                    ),
                    selected: _activeTab == 0,
                    selectedColor: Colors.tealAccent,
                    labelStyle: TextStyle(
                      color: _activeTab == 0 ? Colors.black : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    backgroundColor: const Color(0xFF1A1D36),
                    onSelected: (val) {
                      if (val) setState(() => _activeTab = 0);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ChoiceChip(
                    label: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.document_scanner, size: 16),
                        SizedBox(width: 6),
                        Text('Photo / Label OCR'),
                      ],
                    ),
                    selected: _activeTab == 1,
                    selectedColor: Colors.tealAccent,
                    labelStyle: TextStyle(
                      color: _activeTab == 1 ? Colors.black : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    backgroundColor: const Color(0xFF1A1D36),
                    onSelected: (val) {
                      if (val) setState(() => _activeTab = 1);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Main View: Live Camera or Photo OCR
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  if (_activeTab == 0) ...[
                    // Live Camera View
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.5)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: _scannerController != null
                            ? MobileScanner(
                                controller: _scannerController!,
                                onDetect: (capture) {
                                  final barcode = capture.barcodes.firstOrNull;
                                  if (barcode?.rawValue != null) {
                                    _processScannedCode(barcode!.rawValue!);
                                  }
                                },
                              )
                            : const Center(
                                child: Text('Camera initializing...', style: TextStyle(color: Colors.white54)),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_lastScannedCode.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1D36),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.qr_code, color: Colors.tealAccent, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Last Scanned: $_lastScannedCode',
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ] else ...[
                    // Photo OCR View
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1D36),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.center_focus_weak_rounded, size: 48, color: Colors.tealAccent),
                          const SizedBox(height: 8),
                          const Text(
                            'Scan Product Label / Price Tag / Receipt',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Snap a photo or choose from gallery to detect products automatically.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white54, fontSize: 11),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.tealAccent,
                                  foregroundColor: Colors.black,
                                ),
                                icon: const Icon(Icons.camera_alt, size: 16),
                                label: const Text('Take Photo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                onPressed: () => _pickAndScanImage(ImageSource.camera),
                              ),
                              const SizedBox(width: 10),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.tealAccent,
                                  side: const BorderSide(color: Colors.tealAccent),
                                ),
                                icon: const Icon(Icons.photo_library, size: 16),
                                label: const Text('Gallery', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                onPressed: () => _pickAndScanImage(ImageSource.gallery),
                              ),
                            ],
                          ),
                          if (_isProcessingImage) ...[
                            const SizedBox(height: 12),
                            const LinearProgressIndicator(color: Colors.tealAccent, backgroundColor: Colors.white10),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Matched Products from Catalog
                  if (_matchedProducts.isNotEmpty) ...[
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'MATCHED PRODUCTS IN CATALOG',
                        style: TextStyle(color: Colors.tealAccent, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                    ),
                    const SizedBox(height: 6),
                    ..._matchedProducts.map((p) {
                      final displayName = p.localName.trim().isNotEmpty ? p.localName.trim() : p.productName.trim();
                      return Card(
                        color: const Color(0xFF1A1D36),
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          title: Text(displayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text(
                            'English: ${p.productName} • ${widget.provider.defaultCurrency}${p.effectivePrice.toStringAsFixed(0)} / ${p.unit}',
                            style: const TextStyle(color: Colors.white54, fontSize: 11),
                          ),
                          trailing: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.tealAccent,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            ),
                            onPressed: () => _addScannedProduct(p),
                            child: const Text('+ Add', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      );
                    }),
                  ] else if (_lastScannedCode.isNotEmpty && _activeTab == 0) ...[
                    // Custom fallback for scanned barcode
                    Card(
                      color: Colors.tealAccent.withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.tealAccent.withValues(alpha: 0.3)),
                      ),
                      child: ListTile(
                        title: Text('Use "$_lastScannedCode" as Custom Item', style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: const Text('No exact catalog match found.', style: TextStyle(color: Colors.white54, fontSize: 11)),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.tealAccent, foregroundColor: Colors.black),
                          onPressed: () {
                            _addCustomScannedItem(_lastScannedCode);
                            setState(() => _lastScannedCode = '');
                          },
                          child: const Text('+ Add Custom', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ],

                  // Scanned Items List Summary
                  if (_scannedItems.isNotEmpty) ...[
                    const Divider(color: Colors.white24, height: 20),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'SCANNED ITEMS LIST (${_scannedItems.length})',
                        style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                    ),
                    const SizedBox(height: 6),
                    ..._scannedItems.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final item = entry.value;
                      final name = item.product != null
                          ? (item.product!.localName.trim().isNotEmpty ? item.product!.localName.trim() : item.product!.productName.trim())
                          : (item.localName.trim().isNotEmpty ? '${item.customName} (${item.localName})' : item.customName);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16192E),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                  if (item.product != null)
                                    Text(
                                      '${_formatQuantity(item.quantity)} ${item.product!.unit} • ${widget.provider.defaultCurrency}${item.totalPrice.toStringAsFixed(0)}',
                                      style: const TextStyle(color: Colors.tealAccent, fontSize: 11),
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                              onPressed: () {
                                setState(() {
                                  if (_scannedItems[idx].quantity > 1) {
                                    _scannedItems[idx].quantity -= 1;
                                  } else {
                                    _scannedItems.removeAt(idx);
                                  }
                                });
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, color: Colors.tealAccent, size: 20),
                              onPressed: () {
                                setState(() {
                                  _scannedItems[idx].quantity += 1;
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),

          // Bottom Action Button
          Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.tealAccent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  if (_scannedItems.isNotEmpty) {
                    widget.onItemsScanned(_scannedItems);
                  }
                  Navigator.pop(context);
                },
                child: Text(
                  _scannedItems.isNotEmpty
                      ? 'Add ${_scannedItems.length} Scanned Item(s) (${widget.provider.defaultCurrency}${totalCost.toStringAsFixed(0)})'
                      : 'Done / Close',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
