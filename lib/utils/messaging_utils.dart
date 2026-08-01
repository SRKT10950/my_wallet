import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class MessagingUtils {
  /// Clean phone number for WhatsApp / SMS dispatches
  static String cleanPhoneNumber(String raw) {
    // Remove non-digit characters except leading plus
    final digitsOnly = raw.replaceAll(RegExp(r'[^\d+]'), '');
    if (digitsOnly.startsWith('+')) return digitsOnly.substring(1);
    // If 10 digits without country code, default to 91 (India) or keep as is
    if (digitsOnly.length == 10) return '91$digitsOnly';
    return digitsOnly;
  }

  /// Launch WhatsApp with phone number and pre-filled message
  static Future<bool> sendWhatsApp({
    required String phone,
    required String message,
  }) async {
    final cleanedPhone = cleanPhoneNumber(phone);
    final encodedMessage = Uri.encodeComponent(message);
    
    final waUrl = Uri.parse('https://wa.me/$cleanedPhone?text=$encodedMessage');
    try {
      if (await canLaunchUrl(waUrl)) {
        return await launchUrl(waUrl, mode: LaunchMode.externalApplication);
      } else {
        final fallbackUrl = Uri.parse('whatsapp://send?phone=$cleanedPhone&text=$encodedMessage');
        return await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      return false;
    }
  }

  /// Launch SMS app with phone number and pre-filled body
  static Future<bool> sendSms({
    required String phone,
    required String message,
  }) async {
    final cleanedPhone = cleanPhoneNumber(phone);
    final encodedMessage = Uri.encodeComponent(message);
    final smsUrl = Uri.parse('sms:$cleanedPhone?body=$encodedMessage');

    try {
      if (await canLaunchUrl(smsUrl)) {
        return await launchUrl(smsUrl, mode: LaunchMode.externalApplication);
      } else {
        return await launchUrl(smsUrl);
      }
    } catch (_) {
      return false;
    }
  }

  /// Show share modal dialog with WhatsApp, SMS, and Copy to Clipboard options
  static void showShareOptionsModal(
    BuildContext context, {
    required String title,
    required String message,
    String? contactName,
    String? mobileNumber,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final hasMobile = mobileNumber != null && mobileNumber.trim().isNotEmpty;
        final displayPhone = hasMobile ? mobileNumber.trim() : null;

        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF121422),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        if (contactName != null)
                          Text('Contact: $contactName ${displayPhone != null ? "($displayPhone)" : ""}',
                              style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // WhatsApp Share Button
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFF25D366).withValues(alpha: 0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.chat_bubble_outline, color: Color(0xFF25D366)),
                ),
                title: const Text('Share via WhatsApp', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text(
                  displayPhone != null ? 'Send message directly to $displayPhone' : 'Open WhatsApp with statement',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white30, size: 14),
                onTap: () async {
                  Navigator.pop(ctx);
                  final success = await sendWhatsApp(phone: displayPhone ?? '', message: message);
                  if (!success && context.mounted) {
                    Clipboard.setData(ClipboardData(text: message));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not open WhatsApp. Statement copied to clipboard!'), backgroundColor: Colors.orange),
                    );
                  }
                },
              ),
              const Divider(color: Colors.white10),

              // SMS Share Button
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.blueAccent.withValues(alpha: 0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.sms_outlined, color: Colors.blueAccent),
                ),
                title: const Text('Share via SMS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text(
                  displayPhone != null ? 'Send SMS directly to $displayPhone' : 'Open native SMS app',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white30, size: 14),
                onTap: () async {
                  Navigator.pop(ctx);
                  final success = await sendSms(phone: displayPhone ?? '', message: message);
                  if (!success && context.mounted) {
                    Clipboard.setData(ClipboardData(text: message));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not open SMS. Statement copied to clipboard!'), backgroundColor: Colors.orange),
                    );
                  }
                },
              ),
              const Divider(color: Colors.white10),

              // Copy to Clipboard Button
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.tealAccent.withValues(alpha: 0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.copy_outlined, color: Colors.tealAccent),
                ),
                title: const Text('Copy to Clipboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text('Copy formatted statement text', style: TextStyle(color: Colors.white54, fontSize: 11)),
                onTap: () {
                  Navigator.pop(ctx);
                  Clipboard.setData(ClipboardData(text: message));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Statement copied to clipboard!'), backgroundColor: Colors.teal),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Format a standard professional Invoice / Transaction Alert for WhatsApp or SMS
  static String formatInvoiceMessage({
    required String contactName,
    String businessName = '',
    required String itemService,
    required double totalCost,
    required double paidAmount,
    required String dateStr,
    double? totalDueTillNow,
    bool isWhatsApp = true,
  }) {
    final due = (totalCost - paidAmount) > 0 ? (totalCost - paidAmount) : 0.0;

    if (isWhatsApp) {
      final buffer = StringBuffer();
      buffer.writeln('🧾 *INVOICE / TRANSACTION ALERT*');
      buffer.writeln('══════════════════════════════');
      buffer.writeln('📅 *Date:* $dateStr');
      if (businessName.isNotEmpty) {
        buffer.writeln('🏬 *Business/Shop:* $businessName');
      }
      if (contactName.isNotEmpty) {
        buffer.writeln('👤 *Contact:* $contactName');
      }
      buffer.writeln();
      buffer.writeln('🛒 *Items / Details:*');
      if (itemService.contains('\n')) {
        buffer.writeln(itemService);
      } else {
        buffer.writeln('• $itemService');
      }
      buffer.writeln();
      buffer.writeln('──────────────────────────────');
      buffer.writeln('💰 *Total Amount:* ₹${totalCost.toStringAsFixed(0)}');
      buffer.writeln('✅ *Paid Amount:*  ₹${paidAmount.toStringAsFixed(0)}');
      if (due > 0) {
        buffer.writeln('⚠️ *Pending Due:*  ₹${due.toStringAsFixed(0)}');
      } else {
        buffer.writeln('🎉 *Status:* Fully Paid');
      }
      if (totalDueTillNow != null && totalDueTillNow > 0) {
        buffer.writeln('📊 *Total Due:*    ₹${totalDueTillNow.toStringAsFixed(0)}');
      }
      buffer.writeln('──────────────────────────────');
      buffer.writeln();
      buffer.writeln('Thank you for your transaction!');
      buffer.writeln('_Sent via My Wallet App_');
      return buffer.toString();
    } else {
      final buffer = StringBuffer();
      buffer.writeln('[INVOICE ALERT]');
      buffer.writeln('Date: $dateStr');
      if (businessName.isNotEmpty) buffer.writeln('Shop: $businessName');
      if (contactName.isNotEmpty) buffer.writeln('Contact: $contactName');
      buffer.writeln('Item: ${itemService.replaceAll('\n', ', ')}');
      String summaryLine = 'Total: Rs.${totalCost.toStringAsFixed(0)} | Paid: Rs.${paidAmount.toStringAsFixed(0)} | Due: Rs.${due.toStringAsFixed(0)}';
      if (totalDueTillNow != null && totalDueTillNow > 0) {
        summaryLine += ' | Total Due Till Now: Rs.${totalDueTillNow.toStringAsFixed(0)}';
      }
      buffer.writeln(summaryLine);
      buffer.writeln('Thank you! Sent via My Wallet App.');
      return buffer.toString();
    }
  }

  /// Format a standard professional Monthly Statement / Invoice
  static String formatMonthlyStatementMessage({
    required String contactName,
    String businessName = '',
    required String monthYearStr,
    required List<Map<String, dynamic>> items,
    required double totalCost,
    required double totalPaid,
    bool isWhatsApp = true,
  }) {
    final closingDue = (totalCost - totalPaid) > 0 ? (totalCost - totalPaid) : 0.0;

    if (isWhatsApp) {
      final buffer = StringBuffer();
      buffer.writeln('📊 *MONTHLY INVOICE / STATEMENT*');
      buffer.writeln('══════════════════════════════');
      buffer.writeln('📅 *Month:* $monthYearStr');
      if (businessName.isNotEmpty) buffer.writeln('🏬 *Business:* $businessName');
      if (contactName.isNotEmpty) buffer.writeln('👤 *Contact:* $contactName');
      buffer.writeln();
      buffer.writeln('📋 *SUMMARY OF TRANSACTIONS:*');
      buffer.writeln('──────────────────────────────');
      for (final item in items) {
        final d = item['date'] ?? '';
        final desc = item['desc'] ?? '';
        final c = (item['cost'] as num?)?.toDouble() ?? 0.0;
        final p = (item['paid'] as num?)?.toDouble() ?? 0.0;
        buffer.writeln('• $d: $desc - ₹${c.toStringAsFixed(0)} (Paid: ₹${p.toStringAsFixed(0)})');
      }
      buffer.writeln();
      buffer.writeln('──────────────────────────────');
      buffer.writeln('💰 *Monthly Total:*   ₹${totalCost.toStringAsFixed(0)}');
      buffer.writeln('✅ *Total Paid:*      ₹${totalPaid.toStringAsFixed(0)}');
      if (closingDue > 0) {
        buffer.writeln('⚠️ *Closing Due:*     ₹${closingDue.toStringAsFixed(0)}');
      } else {
        buffer.writeln('🎉 *Status:* Account Clear');
      }
      buffer.writeln('──────────────────────────────');
      buffer.writeln();
      buffer.writeln('Thank you for doing business with us!');
      buffer.writeln('_Generated via My Wallet App_');
      return buffer.toString();
    } else {
      final buffer = StringBuffer();
      buffer.writeln('[MONTHLY STATEMENT - $monthYearStr]');
      if (businessName.isNotEmpty) buffer.writeln('Business: $businessName');
      if (contactName.isNotEmpty) buffer.writeln('Contact: $contactName');
      buffer.writeln('Total Txns: ${items.length}');
      buffer.writeln('Total Cost: Rs.${totalCost.toStringAsFixed(0)} | Paid: Rs.${totalPaid.toStringAsFixed(0)} | Closing Due: Rs.${closingDue.toStringAsFixed(0)}');
      buffer.writeln('Thank you for your business! My Wallet App.');
      return buffer.toString();
    }
  }

  /// Format a standard professional Lend/Borrow Dues Alert
  static String formatLendBorrowMessage({
    required String contactName,
    required String type,
    required double principal,
    required String dateStr,
    String? dueDateStr,
    bool isWhatsApp = true,
  }) {
    final isLend = type == 'Lend';
    final actionStr = isLend ? 'Lent (Given to you)' : 'Borrowed (Received from you)';

    if (isWhatsApp) {
      final buffer = StringBuffer();
      buffer.writeln('📢 *FINANCIAL DUES ALERT*');
      buffer.writeln('══════════════════════════════');
      buffer.writeln('📅 *Date:* $dateStr');
      buffer.writeln('👤 *Contact:* $contactName');
      buffer.writeln('📌 *Type:* $actionStr');
      buffer.writeln();
      buffer.writeln('💵 *Amount:* ₹${principal.toStringAsFixed(0)}');
      if (dueDateStr != null && dueDateStr.isNotEmpty) {
        buffer.writeln('⏰ *Promised Due Date:* $dueDateStr');
      }
      buffer.writeln('──────────────────────────────');
      buffer.writeln();
      buffer.writeln('Please review and confirm. Thank you! 🙏');
      buffer.writeln('_Sent via My Wallet App_');
      return buffer.toString();
    } else {
      final buffer = StringBuffer();
      buffer.writeln('[DUES ALERT]');
      buffer.writeln('Date: $dateStr');
      buffer.writeln('Name: $contactName');
      buffer.writeln('Type: $actionStr');
      buffer.writeln('Amount: Rs.${principal.toStringAsFixed(0)}');
      if (dueDateStr != null && dueDateStr.isNotEmpty) {
        buffer.writeln('Due Date: $dueDateStr');
      }
      buffer.writeln('Sent via My Wallet App.');
      return buffer.toString();
    }
  }
}
