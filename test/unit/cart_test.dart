import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rawnq/app/providers.dart';
import 'package:rawnq/features/cart/cart_controller.dart';
import 'package:rawnq/shared/models/product.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fixtures.dart';

Future<ProviderContainer> makeContainer({
  Map<String, Object> preferences = const <String, Object>{},
}) async {
  SharedPreferences.setMockInitialValues(Map<String, Object>.of(preferences));
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('option validation', () {
    test('a product with variants cannot be added without choosing one', () async {
      final container = await makeContainer();
      final cart = container.read(cartProvider.notifier);

      final result = cart.add(Fixtures.pyjamaWithSizes);

      expect(result.isSuccess, isFalse);
      expect(result.error, CartAddError.optionRequired);
      expect(container.read(cartProvider), isEmpty);
    });

    test('a product without variants adds directly', () async {
      final container = await makeContainer();
      final cart = container.read(cartProvider.notifier);

      final result = cart.add(Fixtures.shirtNoVariants);

      expect(result.isSuccess, isTrue);
      expect(container.read(cartProvider), hasLength(1));
    });

    test('a fully specified variant adds successfully', () async {
      final container = await makeContainer();
      final cart = container.read(cartProvider.notifier);
      final variant =
          Fixtures.pyjamaWithSizes.findVariant(color: 'خمري غامق', size: 'L');

      final result = cart.add(Fixtures.pyjamaWithSizes, variant: variant);

      expect(result.isSuccess, isTrue);
      expect(container.read(cartProvider).single.size, 'L');
    });

    test('an out-of-stock variant is refused', () async {
      final container = await makeContainer();
      final cart = container.read(cartProvider.notifier);
      final variant =
          Fixtures.pyjamaWithSizes.findVariant(color: 'Sand beige', size: 'XL');

      final result = cart.add(Fixtures.pyjamaWithSizes, variant: variant);

      expect(result.error, CartAddError.outOfStock);
      expect(container.read(cartProvider), isEmpty);
    });

    test('a sold-out product without variants is refused', () async {
      final container = await makeContainer();

      final result = container.read(cartProvider.notifier).add(Fixtures.soldOut);

      expect(result.error, CartAddError.outOfStock);
    });

    test('adding beyond available stock is refused and reports the ceiling', () async {
      final container = await makeContainer();
      final cart = container.read(cartProvider.notifier);
      final variant =
          Fixtures.pyjamaWithSizes.findVariant(color: 'خمري غامق', size: 'L');

      expect(cart.add(Fixtures.pyjamaWithSizes, variant: variant).isSuccess, isTrue);
      expect(cart.add(Fixtures.pyjamaWithSizes, variant: variant).isSuccess, isTrue);

      final third = cart.add(Fixtures.pyjamaWithSizes, variant: variant);
      expect(third.error, CartAddError.maxQuantity);
      expect(third.availableQuantity, 2);
      expect(container.read(cartProvider).single.quantity, 2);
    });
  });

  group('cart lines', () {
    test('the same variant increments one line', () async {
      final container = await makeContainer();
      final cart = container.read(cartProvider.notifier);
      final variant =
          Fixtures.pyjamaWithSizes.findVariant(color: 'خمري غامق', size: 'L');

      cart.add(Fixtures.pyjamaWithSizes, variant: variant);
      cart.add(Fixtures.pyjamaWithSizes, variant: variant);

      expect(container.read(cartProvider), hasLength(1));
      expect(container.read(cartProvider).single.quantity, 2);
      expect(container.read(cartCountProvider), 2);
    });

    test('different sizes of one product are separate lines', () async {
      final container = await makeContainer();
      final cart = container.read(cartProvider.notifier);

      cart.add(
        Fixtures.pyjamaWithSizes,
        variant: Fixtures.pyjamaWithSizes.findVariant(color: 'خمري غامق', size: 'M'),
      );
      cart.add(
        Fixtures.pyjamaWithSizes,
        variant: Fixtures.pyjamaWithSizes.findVariant(color: 'خمري غامق', size: 'L'),
      );

      expect(container.read(cartProvider), hasLength(2));
    });

    test('decrementing to zero removes the line', () async {
      final container = await makeContainer();
      final cart = container.read(cartProvider.notifier);
      cart.add(Fixtures.shirtNoVariants);
      final key = container.read(cartProvider).single.key;

      cart.decrement(key);

      expect(container.read(cartProvider), isEmpty);
    });

    test('a removed line can be restored at its original position', () async {
      final container = await makeContainer();
      final cart = container.read(cartProvider.notifier);
      cart.add(Fixtures.shirtNoVariants);
      cart.add(Fixtures.lingerieColorsOnly,
          variant: Fixtures.lingerieColorsOnly.findVariant(color: 'اسود'));

      final removed = container.read(cartProvider).first;
      final index = cart.indexOf(removed.key);
      cart.remove(removed.key);
      expect(container.read(cartProvider), hasLength(1));

      cart.restore(removed, at: index);

      expect(container.read(cartProvider).first.productId, removed.productId);
      expect(container.read(cartProvider), hasLength(2));
    });

    test('clear empties the cart', () async {
      final container = await makeContainer();
      final cart = container.read(cartProvider.notifier);
      cart.add(Fixtures.shirtNoVariants);

      cart.clear();

      expect(container.read(cartProvider), isEmpty);
      expect(container.read(cartCountProvider), 0);
    });
  });

  group('totals', () {
    test('the subtotal sums every line', () async {
      final container = await makeContainer();
      final cart = container.read(cartProvider.notifier);

      cart.add(Fixtures.shirtNoVariants, quantity: 2); // 80 × 2
      cart.add(
        Fixtures.lingerieColorsOnly,
        variant: Fixtures.lingerieColorsOnly.findVariant(color: 'اسود'),
      ); // 40

      expect(container.read(cartSubtotalProvider), 200);
      expect(container.read(cartCountProvider), 3);
    });

    test('the variant price wins over the product price', () async {
      final container = await makeContainer();
      final product = Product(
        id: 'p',
        name: 'x',
        price: 200,
        variants: const <ProductVariant>[
          ProductVariant(id: 'v', productId: 'p', name: 'v', price: 55, stock: 3),
        ],
      );

      container.read(cartProvider.notifier).add(product, variant: product.variants.first);

      expect(container.read(cartSubtotalProvider), 55);
    });

    test('an empty cart totals zero', () async {
      final container = await makeContainer();

      expect(container.read(cartSubtotalProvider), 0);
      expect(container.read(cartCountProvider), 0);
    });
  });

  group('persistence', () {
    test('the cart is restored from storage on the next launch', () async {
      final first = await makeContainer();
      first.read(cartProvider.notifier).add(Fixtures.shirtNoVariants, quantity: 2);

      // SharedPreferences writes are async; let them land before re-reading.
      await Future<void>.delayed(Duration.zero);
      final stored = (await SharedPreferences.getInstance())
          .getString(CartController.storageKey);
      expect(stored, isNotNull);

      final second = await makeContainer(
        preferences: <String, Object>{CartController.storageKey: stored!},
      );

      expect(second.read(cartProvider), hasLength(1));
      expect(second.read(cartProvider).single.quantity, 2);
      expect(second.read(cartSubtotalProvider), 160);
    });

    test('corrupt stored data yields an empty cart rather than a crash', () async {
      final container = await makeContainer(
        preferences: <String, Object>{CartController.storageKey: 'not json'},
      );

      expect(container.read(cartProvider), isEmpty);
    });
  });
}
