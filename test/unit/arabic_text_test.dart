import 'package:flutter_test/flutter_test.dart';
import 'package:rawnq/core/utils/arabic_text.dart';

void main() {
  group('normalise', () {
    test('strips tashkeel so a plain query matches a vocalised name', () {
      // The live category is written قُمْصَان with full diacritics.
      expect(ArabicText.normalise('قُمْصَان'), 'قمصان');
    });

    test('unifies alef forms', () {
      expect(ArabicText.normalise('أحمر'), ArabicText.normalise('احمر'));
      expect(ArabicText.normalise('إطلالة'), ArabicText.normalise('اطلاله'));
      expect(ArabicText.normalise('آمنة'), 'امنه');
    });

    test('folds ta marbuta, alef maqsura, hamza carriers', () {
      expect(ArabicText.normalise('بجامة'), 'بجامه');
      expect(ArabicText.normalise('مصطفى'), 'مصطفي');
      expect(ArabicText.normalise('مسؤول'), 'مسوول');
      expect(ArabicText.normalise('رئيس'), 'رييس');
    });

    test('removes tatweel', () {
      expect(ArabicText.normalise('لانـــجري'), 'لانجري');
    });

    test('converts Arabic-Indic digits to Western ones', () {
      expect(ArabicText.normalise('مقاس ٤٢'), 'مقاس 42');
      expect(ArabicText.normalise('۷۰'), '70');
    });

    test('lowercases Latin text and collapses whitespace', () {
      expect(ArabicText.normalise('  Sand   BEIGE  '), 'sand beige');
    });

    test('an empty string normalises to empty', () {
      expect(ArabicText.normalise(''), '');
    });
  });

  group('matches', () {
    test('an undiacritised query finds a diacritised product name', () {
      expect(ArabicText.matches('قُمْصَان', 'قمصان'), isTrue);
    });

    test('every token must be present', () {
      const name = 'بجامة منزلية اية موضة بنقشة أوراق';
      expect(ArabicText.matches(name, 'بجامة أوراق'), isTrue);
      expect(ArabicText.matches(name, 'بجامة فستان'), isFalse);
    });

    test('matching is case-insensitive for Latin colour names', () {
      expect(ArabicText.matches('Sand beige', 'SAND'), isTrue);
    });

    test('an empty query matches everything', () {
      expect(ArabicText.matches('أي منتج', '   '), isTrue);
    });

    test('an empty haystack matches nothing but an empty query', () {
      expect(ArabicText.matches('', 'قميص'), isFalse);
    });

    test('punctuation in the query does not break matching', () {
      expect(
        ArabicText.matches('طقم لانجري صيفي فاخر', 'لانجري، صيفي'),
        isTrue,
      );
    });
  });
}
