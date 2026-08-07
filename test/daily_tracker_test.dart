import 'package:flutter_test/flutter_test.dart';
import 'package:my_wallet/models/transaction.dart';
import 'package:my_wallet/models/transaction_item.dart';
import 'package:my_wallet/utils/hinglish_translator.dart';

void main() {
  group('Daily Tracker Due Filter & Local Language Custom Item Tests', () {
    test('DailyTransaction identifies due records correctly', () {
      final fullyPaidTx = DailyTransaction(
        date: '2026-08-07',
        categoryId: 1,
        itemService: 'Grocery Shopping',
        cost: 500.0,
        paidAmount: 500.0,
        cleared: true,
      );

      final partialDueTx = DailyTransaction(
        date: '2026-08-07',
        categoryId: 1,
        itemService: 'Shop Purchase',
        cost: 1000.0,
        paidAmount: 400.0,
        cleared: false,
      );

      expect(fullyPaidTx.remaining, 0.0);
      expect(fullyPaidTx.cost > fullyPaidTx.paidAmount, isFalse);

      expect(partialDueTx.remaining, 600.0);
      expect(partialDueTx.cost > partialDueTx.paidAmount, isTrue);

      final transactions = [fullyPaidTx, partialDueTx];
      final dueOnly = transactions.where((tx) => tx.cost > tx.paidAmount).toList();

      expect(dueOnly.length, 1);
      expect(dueOnly.first.itemService, 'Shop Purchase');
    });

    test('Custom items generate local language names via HinglishTranslator', () {
      final translatedPotato = HinglishTranslator.translateToHinglish('Potato');
      expect(translatedPotato, contains('आलू'));

      final translatedMilk = HinglishTranslator.translateToHinglish('Milk');
      expect(translatedMilk, contains('दूध'));

      final item = TransactionItem(
        itemName: 'Potato',
        localName: translatedPotato,
        quantity: 2.0,
        unit: 'Kg',
        unitPrice: 30.0,
      );

      expect(item.itemName, 'Potato');
      expect(item.localName, contains('आलू'));
      expect(item.totalPrice, 60.0);
    });
  });
}
