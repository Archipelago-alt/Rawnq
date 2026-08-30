import 'package:flutter_test/flutter_test.dart';
import 'package:rawnq/core/utils/money.dart';

void main() {
  test('whole prices print without decimals, matching the storefront', () {
    // The live catalogue prices are 40, 45, 60, 70, 80, 90 and 100 ILS.
    expect(Money.format(70), '70 ₪');
    expect(Money.format(100), '100 ₪');
  });

  test('fractional prices keep at most two decimals', () {
    expect(Money.format(69.5), '69.5 ₪');
    expect(Money.format(69.499), '69.5 ₪');
  });

  test('zero formats cleanly', () {
    expect(Money.format(0), '0 ₪');
  });

  test('thousands are grouped', () {
    expect(Money.format(1234), '1,234 ₪');
  });

  test('counts use Western digits without a currency symbol', () {
    expect(Money.count(3), '3');
    expect(Money.count(1200), '1,200');
  });
}
