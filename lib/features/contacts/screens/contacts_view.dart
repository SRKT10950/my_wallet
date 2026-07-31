import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Contact Directory View — payee & borrower contact list.
class ContactsView extends StatelessWidget {
  const ContactsView({super.key});

  @override
  Widget build(BuildContext context) {
    final contacts = [
      {'name': 'Rahul Sharma', 'mobile': '+91 98765 43210', 'avatar': 'RS', 'net': '+₹ 5,000'},
      {'name': 'Priya Patel', 'mobile': '+91 91234 56789', 'avatar': 'PP', 'net': '-₹ 2,000'},
      {'name': 'Amit Verma', 'mobile': '+91 99887 76655', 'avatar': 'AV', 'net': '+₹ 12,500'},
      {'name': 'Suresh Kumar', 'mobile': '+91 98111 22334', 'avatar': 'SK', 'net': 'Settled'},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search contacts by name or mobile...',
              prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textHint),
              fillColor: AppTheme.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Saved Contacts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 14),

          ...contacts.map((c) {
            final net = c['net'] as String;
            final isPlus = net.startsWith('+');
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.primaryViolet.withValues(alpha: 0.2),
                    child: Text(c['avatar'] as String, style: const TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c['name'] as String, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
                        const SizedBox(height: 2),
                        Text(c['mobile'] as String, style: const TextStyle(color: AppTheme.textHint, fontSize: 12)),
                      ],
                    ),
                  ),
                  Text(net, style: TextStyle(color: net == 'Settled' ? AppTheme.textHint : (isPlus ? AppTheme.success : AppTheme.error), fontWeight: FontWeight.w700, fontSize: 14)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
