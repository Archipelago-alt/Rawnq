import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rawnq/features/cart/cart_controller.dart';
import 'package:rawnq/features/favorites/favorites_controller.dart';
import 'package:rawnq/features/products/product_detail_screen.dart';
import 'package:rawnq/features/products/widgets/product_card.dart';

import '../support/fixtures.dart';
import '../support/harness.dart';

void main() {
  testWidgets('shows the product name, price and description', (tester) async {
    await pumpScreen(
      tester,
      ProductDetailScreen(productId: Fixtures.pyjamaWithSizes.id),
    );
    await settle(tester);

    expect(find.text(Fixtures.pyjamaWithSizes.name), findsOneWidget);
    expect(find.text('100 ₪'), findsWidgets);
    expect(find.text('بجامة قطنية مريحة بتصميم عصري.'), findsOneWidget);
  });

  testWidgets('offers the colour and size selectors from the variants', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      ProductDetailScreen(productId: Fixtures.pyjamaWithSizes.id),
    );
    await settle(tester);

    expect(find.text('اختاري اللون'), findsOneWidget);
    expect(find.text('خمري غامق'), findsWidgets);
    expect(find.text('Sand beige'), findsWidgets);

    // Sizes only appear once a colour narrows them.
    expect(find.text('اختاري المقاس'), findsNothing);

    await tester.tap(find.text('خمري غامق').first);
    await tester.pumpAndSettle();

    expect(find.text('اختاري المقاس'), findsOneWidget);
    expect(find.text('M'), findsOneWidget);
    expect(find.text('L'), findsOneWidget);
    expect(
      find.text('XL'),
      findsNothing,
      reason: 'XL belongs to the other colour',
    );
  });

  testWidgets('refuses to add to the cart before an option is chosen', (
    tester,
  ) async {
    final container = await pumpScreen(
      tester,
      ProductDetailScreen(productId: Fixtures.pyjamaWithSizes.id),
    );
    await settle(tester);

    await tester.tap(find.text('أضيفي إلى السلة'));
    await tester.pump();

    expect(container.read(cartProvider), isEmpty);
    expect(find.text('الرجاء اختيار اللون أولاً'), findsOneWidget);
  });

  testWidgets('refuses to add when a colour is chosen but no size', (
    tester,
  ) async {
    final container = await pumpScreen(
      tester,
      ProductDetailScreen(productId: Fixtures.pyjamaWithSizes.id),
    );
    await settle(tester);

    await tester.tap(find.text('خمري غامق').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('أضيفي إلى السلة'));
    await tester.pump();

    expect(container.read(cartProvider), isEmpty);
    expect(find.text('الرجاء اختيار المقاس أولاً'), findsOneWidget);
  });

  testWidgets('adds to the cart once colour and size are chosen', (
    tester,
  ) async {
    final container = await pumpScreen(
      tester,
      ProductDetailScreen(productId: Fixtures.pyjamaWithSizes.id),
    );
    await settle(tester);

    await tester.tap(find.text('خمري غامق').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('L'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('أضيفي إلى السلة'));
    await tester.pump();

    final items = container.read(cartProvider);
    expect(items, hasLength(1));
    expect(items.single.size, 'L');
    expect(items.single.color, 'خمري غامق');
    expect(container.read(cartSubtotalProvider), 100);
  });

  testWidgets('a colour-only product needs just the colour', (tester) async {
    final container = await pumpScreen(
      tester,
      ProductDetailScreen(productId: Fixtures.lingerieColorsOnly.id),
    );
    await settle(tester);

    expect(find.text('اختاري المقاس'), findsNothing);

    await tester.tap(find.text('اسود').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('أضيفي إلى السلة'));
    await tester.pump();

    expect(container.read(cartProvider), hasLength(1));
  });

  testWidgets('a product with no variants adds straight away', (tester) async {
    final container = await pumpScreen(
      tester,
      ProductDetailScreen(productId: Fixtures.shirtNoVariants.id),
    );
    await settle(tester);

    expect(find.text('اختاري اللون'), findsNothing);

    await tester.tap(find.text('أضيفي إلى السلة'));
    await tester.pump();

    expect(container.read(cartProvider), hasLength(1));
  });

  testWidgets('a sold-out product cannot be added', (tester) async {
    final container = await pumpScreen(
      tester,
      ProductDetailScreen(productId: Fixtures.soldOut.id),
    );
    await settle(tester);

    expect(find.text('غير متوفر'), findsWidgets);

    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'غير متوفر'),
    );
    expect(button.onPressed, isNull);
    expect(container.read(cartProvider), isEmpty);
  });

  testWidgets('the heart toggles and persists the favourite', (tester) async {
    final container = await pumpScreen(
      tester,
      ProductDetailScreen(productId: Fixtures.shirtNoVariants.id),
    );
    await settle(tester);

    expect(container.read(favoritesProvider), isEmpty);

    await tester.tap(find.byType(FavoriteButton).first);
    await tester.pump();

    expect(
      container.read(favoritesProvider),
      contains(Fixtures.shirtNoVariants.id),
    );

    await tester.tap(find.byType(FavoriteButton).first);
    await tester.pump();

    expect(container.read(favoritesProvider), isEmpty);
  });

  testWidgets('an unknown product id shows an empty state, not a crash', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      const ProductDetailScreen(productId: 'does-not-exist'),
    );
    await settle(tester);

    expect(find.text('لا توجد منتجات في هذا القسم'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
