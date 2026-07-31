import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

import '../models/contact_model.dart';
import '../services/contact_service.dart';

/// Contact Directory View — full CRUD management for payee/borrower contacts.
class ContactsView extends StatefulWidget {
  const ContactsView({super.key});

  @override
  State<ContactsView> createState() => _ContactsViewState();
}

class _ContactsViewState extends State<ContactsView> {
  final _contactService = ContactService.instance;
  final _searchCtrl = TextEditingController();

  List<ContactModel> _allContacts = [];
  List<ContactModel> _filteredContacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);
    final list = await _contactService.fetchContacts();
    if (!mounted) return;
    setState(() {
      _allContacts = list;
      _filteredContacts = list;
      _isLoading = false;
    });
  }

  void _onSearchChanged() {
    final query = _searchCtrl.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() => _filteredContacts = _allContacts);
    } else {
      setState(() {
        _filteredContacts = _allContacts.where((c) {
          final owner = c.ownerName.toLowerCase();
          final mobile = c.mobileNumber.toLowerCase();
          final shop = (c.businessShopName ?? '').toLowerCase();
          final city = (c.placeCity ?? '').toLowerCase();
          return owner.contains(query) ||
              mobile.contains(query) ||
              shop.contains(query) ||
              city.contains(query);
        }).toList();
      });
    }
  }

  void _showAddEditContactDialog([ContactModel? existingContact]) {
    final formKey = GlobalKey<FormState>();
    final ownerCtrl = TextEditingController(text: existingContact?.ownerName ?? '');
    final mobileCtrl = TextEditingController(text: existingContact?.mobileNumber ?? '');
    final shopCtrl = TextEditingController(text: existingContact?.businessShopName ?? '');
    final cityCtrl = TextEditingController(text: existingContact?.placeCity ?? '');

    bool isActive = existingContact?.isActiveStatus ?? true;
    bool enableNotification = existingContact?.enableNotification ?? true;
    String method = existingContact?.notificationMethod ?? NotificationMethod.whatsApp;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return AlertDialog(
              backgroundColor: AppTheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text(
                existingContact == null ? 'Add New Contact' : 'Edit Contact',
                style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700),
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Person / Owner Name (Required)
                      TextFormField(
                        controller: ownerCtrl,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Person / Owner Name *',
                          hintText: 'e.g. Rahul Sharma',
                          prefixIcon: Icon(Icons.person_outline_rounded, color: AppTheme.primaryTeal),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Person / Owner Name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Mobile Number (Required)
                      TextFormField(
                        controller: mobileCtrl,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Mobile Number *',
                          hintText: 'e.g. 9876543210',
                          prefixIcon: Icon(Icons.phone_outlined, color: AppTheme.primaryTeal),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Mobile Number is required';
                          }
                          final clean = v.replaceAll(RegExp(r'\D'), '');
                          if (clean.length < 10) {
                            return 'Enter a valid 10-digit mobile number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Business / Shop Name (Optional)
                      TextFormField(
                        controller: shopCtrl,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Business / Shop Name',
                          hintText: 'e.g. Sharma General Store',
                          prefixIcon: Icon(Icons.storefront_outlined, color: AppTheme.primaryTeal),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Place / City (Optional)
                      TextFormField(
                        controller: cityCtrl,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Place / City',
                          hintText: 'e.g. Mumbai',
                          prefixIcon: Icon(Icons.location_city_outlined, color: AppTheme.primaryTeal),
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Divider(color: Colors.white10),

                      // Active Status Switch
                      SwitchListTile(
                        title: const Text('Active Status', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: Text(isActive ? 'Account is Active' : 'Account is Inactive', style: const TextStyle(color: AppTheme.textHint, fontSize: 12)),
                        value: isActive,
                        activeTrackColor: AppTheme.primaryViolet,
                        activeThumbColor: AppTheme.primaryTeal,
                        onChanged: (v) => setDlgState(() => isActive = v),
                      ),

                      // Notification Enable Toggle
                      SwitchListTile(
                        title: const Text('Enable Notifications', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: const Text('Send automated alerts & payment reminders', style: TextStyle(color: AppTheme.textHint, fontSize: 12)),
                        value: enableNotification,
                        activeTrackColor: AppTheme.primaryViolet,
                        activeThumbColor: AppTheme.primaryTeal,
                        onChanged: (v) => setDlgState(() => enableNotification = v),
                      ),

                      if (enableNotification) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Notification Method',
                          style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: ChoiceChip(
                                label: const Center(child: Text('💬 WhatsApp')),
                                selected: method == NotificationMethod.whatsApp,
                                selectedColor: AppTheme.primaryTeal.withValues(alpha: 0.25),
                                labelStyle: TextStyle(
                                  color: method == NotificationMethod.whatsApp
                                      ? AppTheme.primaryTeal
                                      : AppTheme.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                                onSelected: (_) => setDlgState(() => method = NotificationMethod.whatsApp),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ChoiceChip(
                                label: const Center(child: Text('📱 SMS')),
                                selected: method == NotificationMethod.sms,
                                selectedColor: AppTheme.primaryViolet.withValues(alpha: 0.25),
                                labelStyle: TextStyle(
                                  color: method == NotificationMethod.sms
                                      ? AppTheme.primaryViolet
                                      : AppTheme.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                                onSelected: (_) => setDlgState(() => method = NotificationMethod.sms),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel', style: TextStyle(color: AppTheme.textHint)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;

                    final newContact = ContactModel(
                      id: existingContact?.id ?? '',
                      createdAt: existingContact?.createdAt ?? DateTime.now().toUtc().toIso8601String(),
                      updatedAt: DateTime.now().toUtc().toIso8601String(),
                      version: (existingContact?.version ?? 1),
                      ownerName: ownerCtrl.text.trim(),
                      mobileNumber: mobileCtrl.text.replaceAll(RegExp(r'\D'), ''),
                      businessShopName: shopCtrl.text.trim().isNotEmpty ? shopCtrl.text.trim() : null,
                      placeCity: cityCtrl.text.trim().isNotEmpty ? cityCtrl.text.trim() : null,
                      isActiveStatus: isActive,
                      enableNotification: enableNotification,
                      notificationMethod: method,
                    );

                    Navigator.pop(dialogCtx);
                    await _contactService.saveContact(newContact);
                    _loadContacts();
                  },
                  child: Text(existingContact == null ? 'Save Contact' : 'Update Contact'),
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditContactDialog(),
        backgroundColor: AppTheme.primaryViolet,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text('Add Contact', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: RefreshIndicator(
        onRefresh: _loadContacts,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar
              TextField(
                controller: _searchCtrl,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search by Owner, Shop, City, or Mobile...',
                  prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textHint),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, color: AppTheme.textHint),
                          onPressed: () {
                            _searchCtrl.clear();
                            _onSearchChanged();
                          },
                        )
                      : null,
                  fillColor: AppTheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Saved Directory (${_filteredContacts.length})',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(30.0),
                    child: CircularProgressIndicator(color: AppTheme.primaryTeal),
                  ),
                )
              else if (_filteredContacts.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(20)),
                  child: Column(
                    children: const [
                      Icon(Icons.contacts_outlined, size: 48, color: AppTheme.textHint),
                      SizedBox(height: 12),
                      Text('No contacts found', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                      SizedBox(height: 4),
                      Text('Tap "Add Contact" to create a new directory entry', style: TextStyle(color: AppTheme.textHint, fontSize: 12)),
                    ],
                  ),
                )
              else
                ..._filteredContacts.map((c) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: AppTheme.primaryViolet.withValues(alpha: 0.2),
                              child: Text(
                                c.initials,
                                style: const TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.w700, fontSize: 16),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        c.ownerName,
                                        style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 16),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: (c.isActiveStatus ? AppTheme.success : AppTheme.error).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          c.isActiveStatus ? 'Active' : 'Inactive',
                                          style: TextStyle(
                                            color: c.isActiveStatus ? AppTheme.success : AppTheme.error,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (c.businessShopName != null && c.businessShopName!.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      '🏪 ${c.businessShopName!}',
                                      style: const TextStyle(color: AppTheme.primaryTeal, fontSize: 13, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                  const SizedBox(height: 2),
                                  Text(
                                    '📱 ${c.formattedMobile}${c.placeCity != null ? ' • 📍 ${c.placeCity!}' : ''}',
                                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: AppTheme.textHint, size: 20),
                              onPressed: () => _showAddEditContactDialog(c),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),
                        const Divider(color: Colors.white10),

                        // Notification Method Badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  c.notificationMethod == NotificationMethod.whatsApp
                                      ? Icons.chat_bubble_outline_rounded
                                      : Icons.sms_outlined,
                                  size: 16,
                                  color: c.enableNotification ? AppTheme.primaryTeal : AppTheme.textHint,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  c.enableNotification
                                      ? 'Alerts via ${c.notificationMethod}'
                                      : 'Notifications Disabled',
                                  style: TextStyle(
                                    color: c.enableNotification ? AppTheme.textSecondary : AppTheme.textHint,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),

                            // Action Shortcuts
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.message_rounded, color: AppTheme.primaryTeal, size: 20),
                                  tooltip: 'Send WhatsApp / SMS',
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Opening ${c.notificationMethod} for ${c.ownerName}...'),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.phone_rounded, color: AppTheme.success, size: 20),
                                  tooltip: 'Call',
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Calling ${c.formattedMobile}...'),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}
