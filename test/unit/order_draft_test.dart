import 'package:flutter_test/flutter_test.dart';
import 'package:rawnq/features/checkout/order_draft.dart';
import 'package:rawnq/shared/models/cart_item.dart';
import 'package:rawnq/shared/models/checkout_options.dart';

import '../support/fixtures.dart';

const _labels = OrderMessageLabels(
  header: 'طلب جديد من تطبيق رونق',
  items: 'المنتجات',
  customer: 'الاسم',
  phone: 'الجوال',
  area: 'منطقة التوصيل',
  payment: 'طريقة الدفع',
  notes: 'ملاحظات',
  subtotal: 'المجموع الفرعي',
  deliveryFee: 'رسوم التوصيل',
  total: 'الإجمالي',
  color: 'اللون',
  size: 'المقاس',
  quantity: 'الكمية',
  free: 'مجاني',
);

OrderDraft buildDraft({
  List<CartItem>? items,
  DeliveryLocation delivery = Fixtures.gaza,
  String? notes,
}) {
  return OrderDraft(
    reference: 'R2608123',
    name: 'سارة',
    phone: '0593208117',
    items:
        items ??
        <CartItem>[
          const CartItem(
            productId: 'p1',
            name: 'بجامة منزلية',
            unitPrice: 100,
            quantity: 2,
            variantId: 'v1',
            color: 'خمري غامق',
            size: 'L',
          ),
        ],
    deliveryLocation: delivery,
    paymentMethod: Fixtures.cashOnDelivery,
    notes: notes,
  );
}

void main() {
  group('totals', () {
    test('the subtotal sums the lines and delivery is added on top', () {
      final draft = buildDraft(
        delivery: const DeliveryLocation(id: 'd', name: 'غزة', price: 15),
      );

      expect(draft.subtotal, 200);
      expect(draft.deliveryFee, 15);
      expect(draft.total, 215);
    });

    test('the shop\'s free Gaza delivery adds nothing', () {
      final draft = buildDraft();

      expect(draft.deliveryFee, 0);
      expect(draft.total, draft.subtotal);
    });
  });

  group('WhatsApp message', () {
    test('includes the reference, options, totals and customer details', () {
      final message = buildDraft().toWhatsappMessage(_labels);

      expect(message, contains('#R2608123'));
      expect(message, contains('بجامة منزلية'));
      expect(message, contains('اللون: خمري غامق'));
      expect(message, contains('المقاس: L'));
      expect(message, contains('الكمية: 2'));
      expect(message, contains('200 ₪'));
      expect(message, contains('الاسم: سارة'));
      expect(message, contains('الجوال: 0593208117'));
      expect(message, contains('منطقة التوصيل: غزة'));
      expect(message, contains('طريقة الدفع: الدفع عند الاستلام'));
    });

    test('free delivery is worded, not printed as 0', () {
      expect(
        buildDraft().toWhatsappMessage(_labels),
        contains('رسوم التوصيل: مجاني'),
      );
    });

    test('notes appear only when the shopper wrote some', () {
      expect(
        buildDraft().toWhatsappMessage(_labels),
        isNot(contains('ملاحظات:')),
      );
      expect(
        buildDraft(notes: 'الرجاء التغليف كهدية').toWhatsappMessage(_labels),
        contains('ملاحظات: الرجاء التغليف كهدية'),
      );
    });

    test('whitespace-only notes are treated as no notes', () {
      expect(
        buildDraft(notes: '   ').toWhatsappMessage(_labels),
        isNot(contains('ملاحظات:')),
      );
    });

    test('option lines are omitted for a product with no colour or size', () {
      final message = buildDraft(
        items: <CartItem>[
          const CartItem(
            productId: 'p',
            name: 'قميص',
            unitPrice: 80,
            quantity: 1,
          ),
        ],
      ).toWhatsappMessage(_labels);

      expect(message, contains('قميص'));
      expect(message, isNot(contains('اللون:')));
      expect(message, isNot(contains('المقاس:')));
      expect(message, contains('الكمية: 1'));
    });
  });

  group('WhatsApp URI', () {
    test('targets wa.me with the store number and percent-encoded Arabic', () {
      final uri = buildDraft().toWhatsappUri('970593208117', _labels);

      expect(uri.scheme, 'https');
      expect(uri.host, 'wa.me');
      expect(uri.path, '/970593208117');

      // Arabic must survive the round trip as UTF-8 percent-encoding.
      expect(uri.queryParameters['text'], contains('سارة'));
      expect(
        uri.toString(),
        contains('%D8%B3'),
        reason: 'Arabic is percent-encoded',
      );
      expect(
        uri.toString(),
        isNot(contains('سارة')),
        reason: 'raw Arabic must not appear in the encoded URL',
      );
    });

    test('the decoded text round-trips to the original message', () {
      final draft = buildDraft(notes: 'ملاحظة & اختبار');
      final uri = draft.toWhatsappUri('970593208117', _labels);

      expect(uri.queryParameters['text'], draft.toWhatsappMessage(_labels));
    });
  });

  group('CheckoutValidator', () {
    test('accepts local and international Palestinian numbers', () {
      expect(CheckoutValidator.isValidPhone('0593208117'), isTrue);
      expect(CheckoutValidator.isValidPhone('+970 59 320 8117'), isTrue);
      expect(CheckoutValidator.isValidPhone('970593208117'), isTrue);
    });

    test('rejects numbers that are too short or empty', () {
      expect(CheckoutValidator.isValidPhone(''), isFalse);
      expect(CheckoutValidator.isValidPhone('12345'), isFalse);
      expect(CheckoutValidator.isValidPhone('abc'), isFalse);
    });

    test('requires a real name', () {
      expect(CheckoutValidator.isValidName('سارة'), isTrue);
      expect(CheckoutValidator.isValidName(' '), isFalse);
      expect(CheckoutValidator.isValidName('س'), isFalse);
    });
  });
}
