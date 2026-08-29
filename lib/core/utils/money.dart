import 'package:intl/intl.dart';

/// Price formatting that matches the live storefront: Israeli new shekel,
/// Western digits, at most two decimals and no trailing `.00`.
class Money {
  const Money._();

  static const String currencyCode = 'ILS';
  static const String symbol = '₪';

  static final NumberFormat _decimal = NumberFormat('#,##0.##', 'en');

  /// `70` -> `70 ₪`, `69.5` -> `69.5 ₪`.
  static String format(double amount) => '${_decimal.format(amount)} $symbol';

  /// Formats a whole-number count (quantities, item counts).
  static String count(num value) => NumberFormat('#,##0', 'en').format(value);
}
