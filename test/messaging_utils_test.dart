import 'package:flutter_test/flutter_test.dart';
import 'package:my_wallet/utils/messaging_utils.dart';

void main() {
  group('MessagingUtils Tests', () {
    test('Cleans phone numbers correctly', () {
      expect(MessagingUtils.cleanPhoneNumber('9876543210'), equals('919876543210'));
      expect(MessagingUtils.cleanPhoneNumber('+91 98765-43210'), equals('919876543210'));
      expect(MessagingUtils.cleanPhoneNumber('+1 (555) 234-5678'), equals('15552345678'));
    });

    test('Formats WhatsApp and SMS invoice messages cleanly', () {
      final waMsg = MessagingUtils.formatInvoiceMessage(
        contactName: 'Ramesh Kumar',
        businessName: 'Super Mart',
        itemService: 'Organic Basmati Rice (2 Kg)',
        totalCost: 120.0,
        paidAmount: 100.0,
        dateStr: 'Jul 25, 2026',
        isWhatsApp: true,
      );

      expect(waMsg, contains('INVOICE / TRANSACTION ALERT'));
      expect(waMsg, contains('Ramesh Kumar'));
      expect(waMsg, contains('Super Mart'));
      expect(waMsg, contains('₹120'));
      expect(waMsg, contains('₹20')); // Pending due

      final smsMsg = MessagingUtils.formatInvoiceMessage(
        contactName: 'Ramesh Kumar',
        businessName: 'Super Mart',
        itemService: 'Organic Basmati Rice (2 Kg)',
        totalCost: 120.0,
        paidAmount: 100.0,
        dateStr: 'Jul 25, 2026',
        isWhatsApp: false,
      );

      expect(smsMsg, contains('[INVOICE ALERT]'));
      expect(smsMsg, contains('Rs.120'));
    });

    test('Formats Monthly Statement messages cleanly', () {
      final waStmt = MessagingUtils.formatMonthlyStatementMessage(
        contactName: 'Ramesh Kumar',
        businessName: 'Super Mart',
        monthYearStr: 'July 2026',
        items: [
          {'date': '02 Jul', 'desc': 'Groceries', 'cost': 450.0, 'paid': 450.0},
          {'date': '10 Jul', 'desc': 'Milk', 'cost': 180.0, 'paid': 180.0},
        ],
        totalCost: 630.0,
        totalPaid: 630.0,
        isWhatsApp: true,
      );

      expect(waStmt, contains('MONTHLY INVOICE / STATEMENT'));
      expect(waStmt, contains('July 2026'));
      expect(waStmt, contains('Account Clear'));
    });
  });
}
