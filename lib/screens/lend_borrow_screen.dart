import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/finance_provider.dart';
import '../models/lend_borrow.dart';
import '../models/contact.dart';
import '../utils/string_utils.dart';
import '../utils/messaging_utils.dart';

class GroupedLendBorrow {
  final String name;
  final String type;
  final double principal;
  final double settled;
  final double diff;
  final String status;
  final List<LendBorrow> entries;

  GroupedLendBorrow({
    required this.name,
    required this.type,
    required this.principal,
    required this.settled,
    required this.diff,
    required this.status,
    required this.entries,
  });
}

class LendBorrowScreen extends StatelessWidget {
  const LendBorrowScreen({super.key});

  void _showAddLendBorrowModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const AddLendBorrowSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Lend & Borrow'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'To Receive (Lend)'),
              Tab(text: 'To Pay (Borrow)'),
            ],
            indicatorColor: Colors.tealAccent,
          ),
        ),
        body: const TabBarView(
          children: [
            LendBorrowList(type: 'Lend'),
            LendBorrowList(type: 'Borrow'),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddLendBorrowModal(context),
          icon: const Icon(Icons.add),
          label: const Text('New Entry'),
        ),
      ),
    );
  }
}

class LendBorrowList extends StatefulWidget {
  final String type;
  const LendBorrowList({super.key, required this.type});

  @override
  State<LendBorrowList> createState() => _LendBorrowListState();
}

class _LendBorrowListState extends State<LendBorrowList> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatusFilter = 'All'; // 'All', 'Active', 'Overdue', 'Settled'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showContactLedgerModal(BuildContext context, String contactName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ContactDetailSheet(name: contactName, type: widget.type),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Overdue':
        return Colors.redAccent;
      case 'Due Soon':
        return Colors.orangeAccent;
      case 'Partially Paid':
        return Colors.teal;
      case 'Settled':
        return Colors.green;
      case 'Active':
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);
    final rawEntries = provider.lendBorrows.where((lb) => lb.type == widget.type).toList();
    final isLend = widget.type == 'Lend';

    final principalLabel = isLend ? 'Total Amount Lent' : 'Total Amount Borrowed';
    final settledLabel = isLend ? 'Amount Recovered' : 'Amount Repaid';
    final pendingLabel = isLend ? 'Pending (To Collect)' : 'Pending (To Pay)';

    // Group entries by contact name
    final Map<String, List<LendBorrow>> groups = {};
    for (var entry in rawEntries) {
      groups.putIfAbsent(entry.name, () => []).add(entry);
    }

    final List<GroupedLendBorrow> entries = [];
    groups.forEach((name, list) {
      double totalPrincipal = 0.0;
      double totalSettled = 0.0;
      double totalDiff = 0.0;
      bool hasActive = false;
      bool hasOverdue = false;

      for (var lb in list) {
        totalPrincipal += lb.principal;
        totalSettled += lb.settled;
        totalDiff += lb.diff;
        if (lb.status == 'Active') {
          hasActive = true;
        }
        if (lb.isOverdue) {
          hasOverdue = true;
        }
      }

      String overallStatus = 'Settled';
      if (hasOverdue) {
        overallStatus = 'Overdue';
      } else if (hasActive) {
        overallStatus = 'Active';
      }

      entries.add(GroupedLendBorrow(
        name: name,
        type: list.first.type,
        principal: totalPrincipal,
        settled: totalSettled,
        diff: totalDiff,
        status: overallStatus,
        entries: list,
      ));
    });

    // Apply Search & Status Filter
    final query = _searchController.text.trim().toLowerCase();
    var filtered = entries.where((e) {
      final matchesSearch = query.isEmpty || e.name.toLowerCase().contains(query);
      if (!matchesSearch) return false;

      if (_selectedStatusFilter == 'Active') {
        return e.status == 'Active' || e.status == 'Overdue';
      } else if (_selectedStatusFilter == 'Overdue') {
        return e.status == 'Overdue';
      } else if (_selectedStatusFilter == 'Settled') {
        return e.status == 'Settled';
      }
      return true;
    }).toList();

    // Sort entries: Overdue first, Active second, Settled last, then alphabetically
    filtered.sort((a, b) {
      int getRank(String s) {
        if (s == 'Overdue') return 0;
        if (s == 'Active') return 1;
        return 2;
      }
      final rankA = getRank(a.status);
      final rankB = getRank(b.status);
      if (rankA != rankB) return rankA.compareTo(rankB);
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return Column(
      children: [
        // Search & Filter Bar
        Padding(
          padding: const EdgeInsets.only(top: 12, left: 16, right: 16, bottom: 4),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search contact by name...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['All', 'Active', 'Overdue', 'Settled'].map((f) {
                    final isSelected = _selectedStatusFilter == f;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        label: Text(f, style: TextStyle(fontSize: 12, color: isSelected ? Colors.black : Colors.white)),
                        selected: isSelected,
                        selectedColor: Colors.tealAccent,
                        onSelected: (selected) {
                          setState(() {
                            _selectedStatusFilter = f;
                          });
                        },
                        visualDensity: VisualDensity.compact,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('No records found.', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 8, left: 16, right: 16, bottom: 88),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final grouped = filtered[index];
                    final activeCount = grouped.entries.where((e) => e.status == 'Active').length;
                    final totalCount = grouped.entries.length;

                    DateTime lastActivity;
                    try {
                      lastActivity = grouped.entries
                          .map((e) => DateTime.tryParse(e.date) ?? DateTime(2000))
                          .reduce((a, b) => a.isAfter(b) ? a : b);
                    } catch (e) {
                      lastActivity = DateTime.now();
                    }

                    final statusColor = _getStatusColor(grouped.status);

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: InkWell(
                        onTap: () => _showContactLedgerModal(context, grouped.name),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      grouped.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Chip(
                                    label: Text(
                                      grouped.status,
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 11),
                                    ),
                                    backgroundColor: statusColor,
                                    side: BorderSide.none,
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(principalLabel, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                      const SizedBox(height: 4),
                                      Text('₹${grouped.principal.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(settledLabel, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                      const SizedBox(height: 4),
                                      Text('₹${grouped.settled.toStringAsFixed(0)}', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.w600, fontSize: 14)),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(pendingLabel, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                      const SizedBox(height: 4),
                                      Text(
                                        '₹${grouped.diff.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          color: grouped.status == 'Settled' ? Colors.greenAccent : (isLend ? Colors.greenAccent : Colors.redAccent),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const Divider(height: 24, color: Colors.white24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '$totalCount loan${totalCount > 1 ? "s" : ""} ($activeCount active)',
                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                  Text(
                                    'Last activity: ${DateFormat('MMM dd, yyyy').format(lastActivity)}',
                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
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
    );
  }
}

class AddLendBorrowSheet extends StatefulWidget {
  final LendBorrow? lendBorrow;
  const AddLendBorrowSheet({super.key, this.lendBorrow});
  @override
  State<AddLendBorrowSheet> createState() => _AddLendBorrowSheetState();
}

class _AddLendBorrowSheetState extends State<AddLendBorrowSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _principalController = TextEditingController();
  String _selectedType = 'Lend';
  DateTime _selectedDate = DateTime.now();
  DateTime? _selectedDueDate;
  bool _isCustomNameInput = false;

  @override
  void initState() {
    super.initState();
    if (widget.lendBorrow != null) {
      _nameController.text = widget.lendBorrow!.name;
      _principalController.text = widget.lendBorrow!.principal.toStringAsFixed(0);
      _selectedType = widget.lendBorrow!.type;
      _selectedDate = DateTime.tryParse(widget.lendBorrow!.date) ?? DateTime.now();
      if (widget.lendBorrow!.returnDate.isNotEmpty) {
        _selectedDueDate = DateTime.tryParse(widget.lendBorrow!.returnDate);
      }
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<FinanceProvider>(context, listen: false);
      final isEdit = widget.lendBorrow != null;
      final updated = LendBorrow(
        id: isEdit ? widget.lendBorrow!.id : null,
        name: toTitleCase(_nameController.text.trim()),
        type: _selectedType,
        date: _selectedDate.toIso8601String(),
        tenure: isEdit ? widget.lendBorrow!.tenure : 0,
        principal: double.parse(_principalController.text.trim()),
        settled: isEdit ? widget.lendBorrow!.settled : 0.0,
        returnDate: _selectedDueDate != null ? _selectedDueDate!.toIso8601String() : (isEdit ? widget.lendBorrow!.returnDate : ''),
        status: isEdit ? widget.lendBorrow!.status : 'Active',
      );

      if (isEdit) {
        provider.updateLendBorrow(updated);
      } else {
        provider.addLendBorrow(updated);
      }
      Navigator.pop(context);

      final personName = updated.name;
      Contact? matchedContact;
      try {
        matchedContact = provider.contacts.firstWhere(
          (c) => c.name.toLowerCase() == personName.toLowerCase(),
        );
      } catch (_) {}

      if (matchedContact != null && matchedContact.transactionNotification && matchedContact.mobile.isNotEmpty) {
        final isSms = matchedContact.notificationMethod == 'SMS';
        final dueDateFormatted = updated.returnDate.isNotEmpty
            ? DateFormat('MMM dd, yyyy').format(DateTime.parse(updated.returnDate))
            : null;

        final msg = MessagingUtils.formatLendBorrowMessage(
          contactName: matchedContact.name,
          type: updated.type,
          principal: updated.principal,
          dateStr: DateFormat('MMM dd, yyyy').format(DateTime.parse(updated.date)),
          dueDateStr: dueDateFormatted,
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
              const Text('Select Contact Person', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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

  Widget _buildContactPicklistField(FinanceProvider provider) {
    final contacts = provider.activeContacts;
    final currentText = _nameController.text.trim();

    if (!_isCustomNameInput && contacts.isNotEmpty) {
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
          labelText: 'Contact Person / Name (Picklist)',
          prefixIcon: const Icon(Icons.person_search, color: Colors.tealAccent),
          suffixIcon: IconButton(
            icon: const Icon(Icons.edit_note, color: Colors.tealAccent),
            tooltip: 'Type Custom Name',
            onPressed: () {
              setState(() {
                _isCustomNameInput = true;
              });
            },
          ),
          border: const OutlineInputBorder(),
        ),
        validator: (val) {
          if (_nameController.text.trim().isEmpty) return 'Required';
          return null;
        },
        hint: const Text('Select contact from picklist...', style: TextStyle(color: Colors.white54)),
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
            child: Text('✏️ + Type New Contact Name', style: TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold)),
          ),
        ],
        onChanged: (val) {
          if (val == '__CUSTOM__') {
            setState(() {
              _isCustomNameInput = true;
              _nameController.clear();
            });
          } else {
            setState(() {
              _nameController.text = val ?? '';
            });
          }
        },
      );
    }

    return TextFormField(
      controller: _nameController,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Contact Person / Name',
        hintText: 'Type contact name...',
        prefixIcon: const Icon(Icons.person_search, color: Colors.tealAccent),
        suffixIcon: contacts.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.arrow_drop_down_circle, color: Colors.tealAccent),
                tooltip: 'Select from Picklist Dropdown',
                onPressed: () {
                  setState(() {
                    _isCustomNameInput = false;
                  });
                },
              )
            : null,
        border: const OutlineInputBorder(),
      ),
      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
      onChanged: (_) => setState(() {}),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.lendBorrow != null;
    final provider = Provider.of<FinanceProvider>(context);
    final existingContacts = provider.lendBorrows
        .map((lb) => toTitleCase(lb.name.trim()))
        .where((n) => n.isNotEmpty)
        .toSet()
        .toList();
    existingContacts.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return Container(
      decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.only(top: 24, left: 24, right: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(isEdit ? 'Edit Transaction Entry' : 'New Transaction Entry', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedType,
                decoration: const InputDecoration(labelText: 'Transaction Type', border: OutlineInputBorder()),
                items: [
                  const DropdownMenuItem(value: 'Lend', child: Text('Lend (Money Given Out)')),
                  const DropdownMenuItem(value: 'Borrow', child: Text('Borrow (Money Taken In)')),
                ],
                onChanged: (v) => setState(() => _selectedType = v!),
              ),
              const SizedBox(height: 12),
              SearchablePicklistField(
                controller: _nameController,
                labelText: 'Contact Person / Name',
                hintText: 'Type to search or select contact...',
                prefixIcon: Icons.person_search,
                provider: provider,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _principalController,
                decoration: const InputDecoration(
                  labelText: 'Principal Amount (₹)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  final amt = double.tryParse(v);
                  if (amt == null) return 'Must be a valid number';
                  if (amt <= 0) return 'Must be greater than 0';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Issue Date', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      subtitle: Text(DateFormat('MMM dd, yyyy').format(_selectedDate), style: const TextStyle(fontWeight: FontWeight.bold)),
                      trailing: const Icon(Icons.calendar_today, size: 18),
                      onTap: () async {
                        final picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2000), lastDate: DateTime(2101));
                        if (picked != null) setState(() => _selectedDate = picked);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Promised Due Date', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      subtitle: Text(_selectedDueDate != null ? DateFormat('MMM dd, yyyy').format(_selectedDueDate!) : 'None (Optional)', style: const TextStyle(fontWeight: FontWeight.bold)),
                      trailing: _selectedDueDate != null
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18, color: Colors.redAccent),
                              onPressed: () => setState(() => _selectedDueDate = null),
                            )
                          : const Icon(Icons.event_available, size: 18),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDueDate ?? DateTime.now().add(const Duration(days: 30)),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2101),
                        );
                        if (picked != null) setState(() => _selectedDueDate = picked);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  if (isEdit) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete Entry'),
                              content: const Text('Are you sure you want to delete this entry and all its repayments?'),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Cancel')),
                                TextButton(
                                  onPressed: () {
                                    provider.deleteLendBorrow(widget.lendBorrow!.id!);
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
                        backgroundColor: Colors.tealAccent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _submit,
                      child: Text(isEdit ? 'Update Entry' : 'Add Entry', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

class ContactDetailSheet extends StatefulWidget {
  final String name;
  final String type;
  const ContactDetailSheet({super.key, required this.name, required this.type});

  @override
  State<ContactDetailSheet> createState() => _ContactDetailSheetState();
}

class _ContactDetailSheetState extends State<ContactDetailSheet> {
  final _amountController = TextEditingController();
  String _selectedMethod = 'UPI';
  DateTime _selectedDate = DateTime.now();

  void _shareLedgerSummary(BuildContext context, String contactName, String type, double totalPrincipal, double totalSettled, double totalDiff) {
    final isLend = type == 'Lend';
    final role = isLend ? 'Lending Ledger' : 'Borrowing Ledger';
    final summaryText = '''
📋 $role for $contactName
• Total ${isLend ? "Lent" : "Borrowed"}: ₹${totalPrincipal.toStringAsFixed(0)}
• Total ${isLend ? "Recovered" : "Repaid"}: ₹${totalSettled.toStringAsFixed(0)}
• Net Pending: ₹${totalDiff.toStringAsFixed(0)}

Generated via My Wallet App
'''.trim();

    Clipboard.setData(ClipboardData(text: summaryText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ledger summary copied to clipboard! Ready to share via WhatsApp/SMS.'),
        backgroundColor: Colors.teal,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _submitRepayment() {
    if (_amountController.text.isNotEmpty) {
      final amt = double.tryParse(_amountController.text);
      if (amt == null || amt <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid amount'), backgroundColor: Colors.redAccent)
        );
        return;
      }
      final provider = Provider.of<FinanceProvider>(context, listen: false);
      provider.addContactRepayment(
        name: widget.name,
        type: widget.type,
        amount: amt,
        method: _selectedMethod,
        date: _selectedDate.toIso8601String(),
      );
      _amountController.clear();
      setState(() {
        _selectedDate = DateTime.now();
      });
    }
  }

  void _confirmDeleteRepayment(BuildContext context, Repayment repayment) {
    final provider = Provider.of<FinanceProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Repayment'),
        content: const Text('Are you sure you want to delete this repayment record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteRepayment(repayment.id!);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _showEditRepaymentDialog(BuildContext context, Repayment repayment) {
    final provider = Provider.of<FinanceProvider>(context, listen: false);
    final amountController = TextEditingController(text: repayment.amount.toStringAsFixed(0));
    String selectedMethod = repayment.method;
    DateTime selectedDate = DateTime.tryParse(repayment.paymentDate) ?? DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Repayment Record'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(labelText: 'Amount (₹)', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedMethod,
                  decoration: const InputDecoration(labelText: 'Payment Method', border: OutlineInputBorder()),
                  items: ['Cash', 'UPI', 'Bank Transfer'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (v) => setState(() => selectedMethod = v!),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}'),
                  trailing: const Icon(Icons.calendar_today, color: Colors.tealAccent),
                  onTap: () async {
                    final picked = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime(2000), lastDate: DateTime(2101));
                    if (picked != null) setState(() => selectedDate = picked);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (amountController.text.isNotEmpty) {
                  final amt = double.tryParse(amountController.text);
                  if (amt == null || amt <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a valid amount'), backgroundColor: Colors.redAccent)
                    );
                    return;
                  }
                  provider.updateRepayment(Repayment(
                    id: repayment.id,
                    lendBorrowId: repayment.lendBorrowId,
                    name: repayment.name,
                    paymentDate: selectedDate.toIso8601String(),
                    amount: amt,
                    method: selectedMethod,
                  ));
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Save', style: TextStyle(color: Colors.tealAccent)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddLendBorrowModal(BuildContext context, LendBorrow entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddLendBorrowSheet(lendBorrow: entry),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Overdue':
        return Colors.redAccent;
      case 'Due Soon':
        return Colors.orangeAccent;
      case 'Partially Paid':
        return Colors.teal;
      case 'Settled':
        return Colors.green;
      case 'Active':
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);
    final allEntries = provider.lendBorrows.where((lb) => lb.name == widget.name && lb.type == widget.type).toList();

    if (allEntries.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      });
      return const SizedBox.shrink();
    }

    double totalPrincipal = 0.0;
    double totalSettled = 0.0;
    double totalDiff = 0.0;
    bool hasActive = false;

    for (var lb in allEntries) {
      totalPrincipal += lb.principal;
      totalSettled += lb.settled;
      totalDiff += lb.diff;
      if (lb.status == 'Active') {
        hasActive = true;
      }
    }

    final entryIds = allEntries.map((e) => e.id).toSet();
    final repayments = provider.repayments.where((r) => entryIds.contains(r.lendBorrowId)).toList();
    repayments.sort((a, b) => DateTime.parse(b.paymentDate).compareTo(DateTime.parse(a.paymentDate)));

    final isLend = widget.type == 'Lend';
    final highlightColor = isLend ? Colors.greenAccent : Colors.redAccent;
    final balanceLabel = isLend ? 'Pending (To Collect)' : 'Pending (To Pay)';
    final principalLabel = isLend ? 'Total Amount Lent' : 'Total Amount Borrowed';
    final settledLabel = isLend ? 'Amount Recovered' : 'Amount Repaid';

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Ledger: ${widget.name}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.share, color: Colors.tealAccent, size: 20),
                tooltip: 'Copy & Share Summary',
                onPressed: () => _shareLedgerSummary(context, widget.name, widget.type, totalPrincipal, totalSettled, totalDiff),
              ),
              Chip(
                label: Text(
                  widget.type,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 11),
                ),
                backgroundColor: isLend ? Colors.blue : Colors.purple,
                side: BorderSide.none,
              ),
            ],
          ),
          const Divider(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    color: Colors.white.withValues(alpha: 0.04),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(principalLabel, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                  const SizedBox(height: 4),
                                  Text('₹${totalPrincipal.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(settledLabel, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                  const SizedBox(height: 4),
                                  Text('₹${totalSettled.toStringAsFixed(0)}', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 15)),
                                ],
                              ),
                            ],
                          ),
                          const Divider(height: 24, color: Colors.white12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(balanceLabel, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                              Text('₹${totalDiff.toStringAsFixed(0)}', style: TextStyle(color: highlightColor, fontWeight: FontWeight.bold, fontSize: 18)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Individual Loans & Entries', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  ...allEntries.map((lb) {
                    final lbDate = DateTime.tryParse(lb.date) ?? DateTime.now();
                    final estInterest = (lb.principal * 0.06 * (lb.tenure > 0 ? lb.tenure : 1)) / 12.0;
                    final displayStatus = lb.displayStatus;
                    final statusColor = _getStatusColor(displayStatus);

                    return Card(
                      color: Colors.white.withValues(alpha: 0.02),
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        key: ValueKey(lb.id),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Issued: ${DateFormat('MMM dd, yyyy').format(lbDate)}',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 18, color: Colors.blueAccent),
                                      onPressed: () => _showAddLendBorrowModal(context, lb),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    const SizedBox(width: 8),
                                    Chip(
                                      label: Text(
                                        displayStatus,
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                      backgroundColor: statusColor,
                                      side: BorderSide.none,
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (lb.computedDueDate != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Promised Due Date: ${DateFormat('MMM dd, yyyy').format(lb.computedDueDate!)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: lb.isOverdue ? Colors.redAccent : Colors.white70,
                                  fontWeight: lb.isOverdue ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Text('Principal: ₹${lb.principal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13)),
                            if (lb.tenure > 0) ...[
                              Text('Tenure: ${lb.tenure} months', style: const TextStyle(fontSize: 13)),
                              Text('Est. Interest (6% p.a.): ₹${estInterest.toStringAsFixed(0)}', style: const TextStyle(color: Colors.orangeAccent, fontSize: 13)),
                            ],
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Settled: ₹${lb.settled.toStringAsFixed(0)}', style: const TextStyle(color: Colors.greenAccent, fontSize: 13)),
                                Text('Pending: ₹${lb.diff.toStringAsFixed(0)}', style: TextStyle(color: highlightColor, fontWeight: FontWeight.w600, fontSize: 13)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                  if (hasActive) ...[
                    const Text('Add Repayment (FIFO Allocation)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _amountController,
                                  decoration: const InputDecoration(
                                    labelText: 'Amount (₹)',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  initialValue: _selectedMethod,
                                  decoration: const InputDecoration(
                                    labelText: 'Method',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  items: ['Cash', 'UPI', 'Bank Transfer']
                                      .map((m) => DropdownMenuItem(
                                            value: m,
                                            child: Text(m, overflow: TextOverflow.ellipsis),
                                          ))
                                      .toList(),
                                  onChanged: (v) => setState(() => _selectedMethod = v!),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextButton.icon(
                                  icon: const Icon(Icons.calendar_today, size: 16),
                                  label: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
                                  ),
                                  onPressed: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: _selectedDate,
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime(2101),
                                    );
                                    if (picked != null) {
                                      setState(() => _selectedDate = picked);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _submitRepayment,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.tealAccent,
                                    foregroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: const FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text('Add Repayment', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  const Text('Repayments History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Divider(),
                  if (repayments.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text('No repayments yet.', style: TextStyle(color: Colors.grey)),
                      ),
                    )
                  else
                    ...repayments.map((r) {
                      final rDate = DateTime.tryParse(r.paymentDate) ?? DateTime.now();
                      final appliedEntry = allEntries.firstWhere(
                        (e) => e.id == r.lendBorrowId,
                        orElse: () => allEntries.first,
                      );
                      final entryDate = DateTime.tryParse(appliedEntry.date) ?? DateTime.now();
                      final appliedText = 'Applied to: Loan on ${DateFormat('MMM dd, yyyy').format(entryDate)}';

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: Colors.tealAccent.withValues(alpha: 0.1),
                          child: const Icon(Icons.check, color: Colors.tealAccent, size: 18),
                        ),
                        title: Text('₹${r.amount.toStringAsFixed(0)} via ${r.method}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(DateFormat('MMM dd, yyyy').format(rDate)),
                            const SizedBox(height: 2),
                            Text(
                              appliedText,
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 18, color: Colors.blueAccent),
                              onPressed: () => _showEditRepaymentDialog(context, r),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 18, color: Colors.redAccent),
                              onPressed: () => _confirmDeleteRepayment(context, r),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
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
