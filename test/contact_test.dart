import 'package:flutter_test/flutter_test.dart';
import 'package:my_wallet/models/contact.dart';

void main() {
  group('Contact Model Tests', () {
    test('Title Case formatting on creation & fromMap with notification settings', () {
      final contact = Contact(
        id: 1,
        name: 'starbucks coffee store',
        mobile: '9876543210',
        place: 'downtown city',
        occupation: 'coffee shop',
        businessName: 'starbucks india pvt ltd',
        transactionNotification: true,
        notificationMethod: 'SMS',
        active: true,
      );

      expect(contact.name, equals('Starbucks Coffee Store'));
      expect(contact.place, equals('Downtown City'));
      expect(contact.occupation, equals('Coffee Shop'));
      expect(contact.businessName, equals('Starbucks India Pvt Ltd'));
      expect(contact.transactionNotification, isTrue);
      expect(contact.notificationMethod, equals('SMS'));

      final map = contact.toMap();
      expect(map['id'], equals(1));
      expect(map['businessName'], equals('Starbucks India Pvt Ltd'));
      expect(map['transactionNotification'], equals(1));
      expect(map['notificationMethod'], equals('SMS'));
      expect(map['active'], equals(1));
      expect(map['deleted'], equals(0));

      final restored = Contact.fromMap(map);
      expect(restored.name, equals('Starbucks Coffee Store'));
      expect(restored.businessName, equals('Starbucks India Pvt Ltd'));
      expect(restored.transactionNotification, isTrue);
      expect(restored.notificationMethod, equals('SMS'));
      expect(restored.active, isTrue);
    });

    test('Contact copyWith updates notification fields correctly', () {
      final contact = Contact(
        id: 2,
        name: 'John Doe',
        mobile: '1234567890',
        businessName: 'doe enterprises',
        transactionNotification: true,
        notificationMethod: 'WhatsApp',
        active: true,
      );

      final updated = contact.copyWith(
        name: 'john doe junior',
        businessName: 'doe global group',
        transactionNotification: false,
        notificationMethod: 'SMS',
        active: false,
      );

      expect(updated.name, equals('John Doe Junior'));
      expect(updated.businessName, equals('Doe Global Group'));
      expect(updated.transactionNotification, isFalse);
      expect(updated.notificationMethod, equals('SMS'));
      expect(updated.active, isFalse);
      expect(updated.mobile, equals('1234567890'));
    });
  });
}
