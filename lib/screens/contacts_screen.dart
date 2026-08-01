import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/contact.dart';
import '../providers/finance_provider.dart';
import '../utils/string_utils.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  String _searchQuery = '';
  String _statusFilter = 'All'; // 'All', 'Active', 'Inactive'

  void _showContactModal(BuildContext context, {Contact? contact}) {
    final nameController = TextEditingController(text: contact?.name ?? '');
    final mobileController = TextEditingController(text: contact?.mobile ?? '');
    final businessNameController = TextEditingController(text: contact?.businessName ?? '');
    final placeController = TextEditingController(text: contact?.place ?? '');
    final occupationController = TextEditingController(text: contact?.occupation ?? '');
    bool isActive = contact?.active ?? true;
    bool transactionNotification = contact?.transactionNotification ?? true;
    String notificationMethod = contact?.notificationMethod ?? 'WhatsApp';
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFF121422),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.only(
              top: 24,
              left: 24,
              right: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          contact == null ? 'Add New Contact' : 'Edit Contact',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white54),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Contact / Shop Name *',
                        labelStyle: const TextStyle(color: Colors.white70),
                        hintText: 'e.g. Starbucks Coffee, John Doe',
                        hintStyle: const TextStyle(color: Colors.white30),
                        prefixIcon: const Icon(Icons.person, color: Colors.tealAccent),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: mobileController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Mobile Number (Optional)',
                        labelStyle: const TextStyle(color: Colors.white70),
                        hintText: 'e.g. +91 9876543210',
                        hintStyle: const TextStyle(color: Colors.white30),
                        prefixIcon: const Icon(Icons.phone, color: Colors.tealAccent),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: businessNameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Business / Shop Name (Optional)',
                        labelStyle: const TextStyle(color: Colors.white70),
                        hintText: 'e.g. Starbucks Cafe, Apex Traders',
                        hintStyle: const TextStyle(color: Colors.white30),
                        prefixIcon: const Icon(Icons.business, color: Colors.tealAccent),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: placeController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Place / City (Optional)',
                              labelStyle: const TextStyle(color: Colors.white70),
                              hintText: 'e.g. Downtown',
                              hintStyle: const TextStyle(color: Colors.white30),
                              prefixIcon: const Icon(Icons.location_on, color: Colors.tealAccent),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.05),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: occupationController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Occupation / Type',
                              labelStyle: const TextStyle(color: Colors.white70),
                              hintText: 'e.g. Cafe, Grocery',
                              hintStyle: const TextStyle(color: Colors.white30),
                              prefixIcon: const Icon(Icons.work, color: Colors.tealAccent),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.05),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    isActive ? Icons.check_circle : Icons.pause_circle_filled,
                                    color: isActive ? Colors.greenAccent : Colors.orangeAccent,
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Active Status', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      Text(
                                        isActive ? 'Available in picklists' : 'Hidden from picklists',
                                        style: const TextStyle(color: Colors.white54, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Switch(
                                value: isActive,
                                activeColor: Colors.tealAccent,
                                onChanged: (val) {
                                  setModalState(() => isActive = val);
                                },
                              ),
                            ],
                          ),
                          const Divider(color: Colors.white10, height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    transactionNotification ? Icons.notifications_active : Icons.notifications_off,
                                    color: transactionNotification ? Colors.tealAccent : Colors.white38,
                                  ),
                                  const SizedBox(width: 12),
                                  const Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Transaction Notification', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      Text(
                                        'Auto-notify on adding transaction',
                                        style: TextStyle(color: Colors.white54, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Switch(
                                value: transactionNotification,
                                activeColor: Colors.tealAccent,
                                onChanged: (val) {
                                  setModalState(() => transactionNotification = val);
                                },
                              ),
                            ],
                          ),
                          if (transactionNotification) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Text('Notification Method:', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 12),
                                ChoiceChip(
                                  avatar: Icon(Icons.chat_bubble, size: 14, color: notificationMethod == 'WhatsApp' ? Colors.black : const Color(0xFF25D366)),
                                  label: const Text('WhatsApp'),
                                  selected: notificationMethod == 'WhatsApp',
                                  selectedColor: const Color(0xFF25D366),
                                  labelStyle: TextStyle(
                                    color: notificationMethod == 'WhatsApp' ? Colors.black : Colors.white70,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                  onSelected: (selected) {
                                    if (selected) setModalState(() => notificationMethod = 'WhatsApp');
                                  },
                                ),
                                const SizedBox(width: 8),
                                ChoiceChip(
                                  avatar: Icon(Icons.sms, size: 14, color: notificationMethod == 'SMS' ? Colors.black : Colors.blueAccent),
                                  label: const Text('SMS'),
                                  selected: notificationMethod == 'SMS',
                                  selectedColor: Colors.blueAccent,
                                  labelStyle: TextStyle(
                                    color: notificationMethod == 'SMS' ? Colors.black : Colors.white70,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                  onSelected: (selected) {
                                    if (selected) setModalState(() => notificationMethod = 'SMS');
                                  },
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        icon: const Icon(Icons.save, color: Colors.white),
                        label: Text(
                          contact == null ? 'Save Contact' : 'Update Contact',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () async {
                          if (formKey.currentState!.validate()) {
                            final provider = Provider.of<FinanceProvider>(context, listen: false);
                            final formattedName = toTitleCase(nameController.text.trim());
                            final formattedBusiness = toTitleCase(businessNameController.text.trim());
                            final formattedPlace = toTitleCase(placeController.text.trim());
                            final formattedOcc = toTitleCase(occupationController.text.trim());
                            final cleanMobile = mobileController.text.trim();

                            final bool success;
                            if (contact == null) {
                              success = await provider.addContact(Contact(
                                name: formattedName,
                                mobile: cleanMobile,
                                place: formattedPlace,
                                occupation: formattedOcc,
                                businessName: formattedBusiness,
                                transactionNotification: transactionNotification,
                                notificationMethod: notificationMethod,
                                active: isActive,
                              ));
                            } else {
                              success = await provider.updateContact(contact.copyWith(
                                name: formattedName,
                                mobile: cleanMobile,
                                place: formattedPlace,
                                occupation: formattedOcc,
                                businessName: formattedBusiness,
                                transactionNotification: transactionNotification,
                                notificationMethod: notificationMethod,
                                active: isActive,
                              ));
                            }

                            if (!success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Contact with mobile number "$cleanMobile" already exists!'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            } else if (context.mounted) {
                              Navigator.pop(ctx);
                            }
                          }
                        },
                      ),
                    ),
                    if (contact != null) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.redAccent),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          label: const Text('Delete Contact', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (dialogCtx) => AlertDialog(
                                backgroundColor: const Color(0xFF121422),
                                title: const Text('Delete Contact', style: TextStyle(color: Colors.white)),
                                content: Text('Are you sure you want to delete ${contact.name}?', style: const TextStyle(color: Colors.white70)),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(dialogCtx),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      final provider = Provider.of<FinanceProvider>(context, listen: false);
                                      provider.deleteContact(contact.id!);
                                      Navigator.pop(dialogCtx); // close dialog
                                      Navigator.pop(ctx); // close modal
                                    },
                                    child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);
    final allContactsList = provider.contacts;

    final filteredContacts = allContactsList.where((c) {
      final matchesSearch = c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.mobile.contains(_searchQuery) ||
          c.place.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.occupation.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.businessName.toLowerCase().contains(_searchQuery.toLowerCase());
      if (!matchesSearch) return false;
      if (_statusFilter == 'Active') return c.active;
      if (_statusFilter == 'Inactive') return !c.active;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF080914),
      appBar: AppBar(
        title: const Text('Contact Directory', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add, color: Colors.tealAccent),
            tooltip: 'Add Contact',
            onPressed: () => _showContactModal(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showContactModal(context),
        backgroundColor: const Color(0xFF6366F1),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Contact', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          children: [
            // Search Input
            TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search by name, phone, place or occupation...',
                hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: Colors.tealAccent),
                filled: true,
                fillColor: const Color(0xFF121422),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Status Filter Chips
            Row(
              children: ['All', 'Active', 'Inactive'].map((status) {
                final isSelected = _statusFilter == status;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(status),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _statusFilter = status);
                    },
                    selectedColor: const Color(0xFF6366F1).withValues(alpha: 0.3),
                    backgroundColor: const Color(0xFF121422),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.tealAccent : Colors.white60,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected ? Colors.tealAccent.withValues(alpha: 0.4) : Colors.white10,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // Contact List View
            Expanded(
              child: filteredContacts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.contacts_outlined, size: 64, color: Colors.white.withValues(alpha: 0.15)),
                          const SizedBox(height: 12),
                          const Text('No Contacts Found', style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                            _searchQuery.isNotEmpty ? 'Try searching another keyword.' : 'Tap "+ Add Contact" to create one.',
                            style: const TextStyle(color: Colors.white38, fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredContacts.length,
                      itemBuilder: (context, index) {
                        final c = filteredContacts[index];
                        final initials = c.name.isNotEmpty
                            ? c.name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
                            : '?';

                        return Card(
                          color: const Color(0xFF121422),
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                          ),
                          child: InkWell(
                            onTap: () => _showContactModal(context, contact: c),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(14.0),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: c.active
                                        ? Colors.tealAccent.withValues(alpha: 0.15)
                                        : Colors.white.withValues(alpha: 0.05),
                                    child: Text(
                                      initials,
                                      style: TextStyle(
                                        color: c.active ? Colors.tealAccent : Colors.white38,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                c.name,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (c.transactionNotification) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: (c.notificationMethod == 'WhatsApp' ? const Color(0xFF25D366) : Colors.blueAccent).withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      c.notificationMethod == 'WhatsApp' ? Icons.chat_bubble : Icons.sms,
                                                      size: 10,
                                                      color: c.notificationMethod == 'WhatsApp' ? const Color(0xFF25D366) : Colors.blueAccent,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      c.notificationMethod,
                                                      style: TextStyle(
                                                        color: c.notificationMethod == 'WhatsApp' ? const Color(0xFF25D366) : Colors.blueAccent,
                                                        fontSize: 9,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: (c.active ? Colors.greenAccent : Colors.orangeAccent).withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                c.active ? 'ACTIVE' : 'INACTIVE',
                                                style: TextStyle(
                                                  color: c.active ? Colors.greenAccent : Colors.orangeAccent,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            if (c.mobile.isNotEmpty) ...[
                                              const Icon(Icons.phone, size: 12, color: Colors.white38),
                                              const SizedBox(width: 4),
                                              Text(c.mobile, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                                              const SizedBox(width: 10),
                                            ],
                                            if (c.businessName.isNotEmpty) ...[
                                              const Icon(Icons.business, size: 12, color: Colors.tealAccent),
                                              const SizedBox(width: 4),
                                              Text(c.businessName, style: const TextStyle(color: Colors.tealAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                                              const SizedBox(width: 10),
                                            ],
                                            if (c.occupation.isNotEmpty) ...[
                                              const Icon(Icons.work_outline, size: 12, color: Colors.white38),
                                              const SizedBox(width: 4),
                                              Text(c.occupation, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                                              const SizedBox(width: 10),
                                            ],
                                            if (c.place.isNotEmpty) ...[
                                              const Icon(Icons.location_on_outlined, size: 12, color: Colors.white38),
                                              const SizedBox(width: 4),
                                              Text(c.place, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
                                    tooltip: 'Delete Contact',
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          backgroundColor: const Color(0xFF121422),
                                          title: const Text('Delete Contact', style: TextStyle(color: Colors.white)),
                                          content: Text('Are you sure you want to delete ${c.name}?', style: const TextStyle(color: Colors.white70)),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                provider.deleteContact(c.id!);
                                                Navigator.pop(ctx);
                                              },
                                              child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
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
    );
  }
}
