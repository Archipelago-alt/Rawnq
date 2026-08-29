import 'package:flutter/foundation.dart';

import '../../core/utils/money.dart';
import '../../shared/models/cart_item.dart';
import '../../shared/models/checkout_options.dart';

/// Labels for the WhatsApp order message.
///
/// Passed in from the presentation layer so this class stays free of any
/// hardcoded display strings.
@immutable
class OrderMessageLabels {
  const OrderMessageLabels({
    required this.header,
    required this.items,
    required this.customer,
    required this.phone,
    required this.area,
    required this.payment,
    required this.notes,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.color,
    required this.size,
    required this.quantity,
    required this.free,
  });

  final String header;
  final String items;
  final String customer;
  final String phone;
  final String area;
  final String payment;
  final String notes;
  final String subtotal;
  final String deliveryFee;
  final String total;
  final String color;
  final String size;
  final String quantity;
  final String free;
}

/// A completed, validated order ready to be handed to the shop.
///
/// The app never submits this to the platform's database — it composes a
/// message the shopper sends to the shop's own WhatsApp number, or hands the
/// shopper to the official web checkout. See `docs/api-integration.md`.
@immutable
class OrderDraft {
  const OrderDraft({
    required this.reference,
    required this.name,
    required this.phone,
    required this.items,
    required this.deliveryLocation,
    required this.paymentMethod,
    this.notes,
  });

  final String reference;
  final String name;
  final String phone;
  final List<CartItem> items;
  final DeliveryLocation deliveryLocation;
  final StorePaymentMethod paymentMethod;
  final String? notes;

  double get subtotal =>
      items.fold<double>(0, (sum, item) => sum + item.lineTotal);

  double get deliveryFee => deliveryLocation.price;

  double get total => subtotal + deliveryFee;

  /// Builds the Arabic order message.
  ///
  /// Returned as plain text; percent-encoding for the `wa.me` URL is handled
  /// by [Uri], which encodes the UTF-8 bytes correctly for Arabic.
  String toWhatsappMessage(OrderMessageLabels labels) {
    final buffer = StringBuffer()
      ..writeln('*${labels.header}*')
      ..writeln('#$reference')
      ..writeln()
      ..writeln('*${labels.items}*');

    for (final item in items) {
      final details = <String>[
        if ((item.color ?? '').isNotEmpty) '${labels.color}: ${item.color}',
        if ((item.size ?? '').isNotEmpty) '${labels.size}: ${item.size}',
        '${labels.quantity}: ${Money.count(item.quantity)}',
      ].join(' — ');
      buffer
        ..writeln('• ${item.name}')
        ..writeln('   $details')
        ..writeln('   ${Money.format(item.lineTotal)}');
    }

    buffer
      ..writeln()
      ..writeln('${labels.subtotal}: ${Money.format(subtotal)}')
      ..writeln(
        '${labels.deliveryFee}: '
        '${deliveryLocation.isFree ? labels.free : Money.format(deliveryFee)}',
      )
      ..writeln('*${labels.total}: ${Money.format(total)}*')
      ..writeln()
      ..writeln('${labels.customer}: $name')
      ..writeln('${labels.phone}: $phone')
      ..writeln('${labels.area}: ${deliveryLocation.name}')
      ..writeln('${labels.payment}: ${paymentMethod.name}');

    final trimmedNotes = notes?.trim();
    if (trimmedNotes != null && trimmedNotes.isNotEmpty) {
      buffer.writeln('${labels.notes}: $trimmedNotes');
    }

    return buffer.toString().trimRight();
  }

  /// Builds the `wa.me` deep link for [whatsappDigits].
  Uri toWhatsappUri(String whatsappDigits, OrderMessageLabels labels) {
    return Uri.https('wa.me', '/$whatsappDigits', <String, String>{
      'text': toWhatsappMessage(labels),
    });
  }
}

/// Validation for the checkout form.
class CheckoutValidator {
  const CheckoutValidator._();

  /// Palestinian mobile numbers are 9–10 digits locally, or up to 13 with the
  /// +970/+972 country code. Kept permissive enough not to reject a number
  /// the shop would happily accept.
  static bool isValidPhone(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length >= 9 && digits.length <= 15;
  }

  static bool isValidName(String value) => value.trim().length >= 2;
}
