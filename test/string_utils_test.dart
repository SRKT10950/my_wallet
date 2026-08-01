import 'package:flutter_test/flutter_test.dart';
import 'package:my_wallet/utils/string_utils.dart';

void main() {
  group('toTitleCase Tests', () {
    test('Capitalizes single word', () {
      expect(toTitleCase('starbucks'), equals('Starbucks'));
    });

    test('Capitalizes multiple words', () {
      expect(toTitleCase('my coffee shop'), equals('My Coffee Shop'));
    });

    test('Converts ALL CAPS to Title Case', () {
      expect(toTitleCase('AMAZON INDIA STORE'), equals('Amazon India Store'));
    });

    test('Handles extra whitespace', () {
      expect(toTitleCase('   super   market  '), equals('Super Market'));
    });

    test('Handles hyphenated words', () {
      expect(toTitleCase('sub-category store'), equals('Sub-Category Store'));
    });

    test('Handles null or empty string', () {
      expect(toTitleCase(null), equals(''));
      expect(toTitleCase(''), equals(''));
      expect(toTitleCase('   '), equals(''));
    });
  });
}
