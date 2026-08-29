import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rawnq/core/widgets/state_views.dart';
import 'package:rawnq/features/cart/cart_controller.dart';
import 'package:rawnq/features/cart/cart_screen.dart';
import 'package:rawnq/features/cart/widgets/cart_line_tile.dart';

import '../support/fixtures.dart';
import '../support/harness.dart';

void main() {
  testWidgets('shows an empty state when nothing has been added', (tester) async {
    await pumpScreen(tester, const CartScreen());
    await settle(tester);

    expect(find.byType(EmptyStateView), findsOneWidget);
    expect(find.text('سلتك فارغة'), findsOneWidget);
    expect(find.byType(CartLineTile), findsNothing);
  });

  testWidgets('lists the cart lines with their chosen options', (tester) async {
    final container = await pumpScreen(tester, const CartScreen());
    container.read(cartProvider.notifier).add(
          Fixtures.pyjamaWithSizes,
          variant: Fixtures.pyjamaWithSizes.findVariant(color: 'خمري غامق', size: 'L'),
        );
    await settle(tester);

    expect(find.byType(CartLineTile), findsOneWidget);
    expect(find.text(Fixtures.pyjamaWithSizes.name), findsOneWidget);
    expect(find.textContaining('خمري غامق'), findsOneWidget);
    expect(find.textContaining('L'), findsWidgets);
  });

  testWidgets('shows the subtotal, the shop\'s delivery area and the total',
      (tester) async {
    final container = await pumpScreen(tester, const CartScreen());
    container.read(cartProvider.notifier).add(Fixtures.shirtNoVariants, quantity: 2);
    await settle(tester);

    expect(find.text('المجموع الفرعي'), findsOneWidget);
    expect(find.text('160 ₪'), findsWidgets);
    // Gaza delivery is free on the live store, so it must read as free.
    expect(find.textContaining('غزة'), findsOneWidget);
    expect(find.text('مجاني'), findsOneWidget);
    expect(find.text('الإجمالي'), findsOneWidget);
  });

  testWidgets('the stepper increases and decreases the quantity', (tester) async {
    final container = await pumpScreen(tester, const CartScreen());
    container.read(cartProvider.notifier).add(Fixtures.shirtNoVariants);
    await settle(tester);

    expect(container.read(cartCountProvider), 1);

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pump();
    expect(container.read(cartCountProvider), 2);
    expect(container.read(cartSubtotalProvider), 160);

    await tester.tap(find.byIcon(Icons.remove_rounded));
    await tester.pump();
    expect(container.read(cartCountProvider), 1);
  });

  testWidgets('the stepper refuses to exceed available stock', (tester) async {
    final container = await pumpScreen(tester, const CartScreen());
    // Only two of this variant exist.
    container.read(cartProvider.notifier).add(
          Fixtures.pyjamaWithSizes,
          variant: Fixtures.pyjamaWithSizes.findVariant(color: 'خمري غامق', size: 'L'),
          quantity: 2,
        );
    await settle(tester);

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pump();

    expect(container.read(cartCountProvider), 2, reason: 'capped at the stock level');
  });

  testWidgets('removing a line offers an undo that restores it', (tester) async {
    final container = await pumpScreen(tester, const CartScreen());
    container.read(cartProvider.notifier).add(Fixtures.shirtNoVariants);
    await settle(tester);

    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    await tester.pump();

    expect(container.read(cartProvider), isEmpty);
    expect(find.text('تمت إزالة المنتج'), findsOneWidget);

    await tester.tap(find.text('تراجع'));
    await tester.pump();

    expect(container.read(cartProvider), hasLength(1));
  });

  testWidgets('clearing the cart asks for confirmation first', (tester) async {
    final container = await pumpScreen(tester, const CartScreen());
    container.read(cartProvider.notifier).add(Fixtures.shirtNoVariants);
    await settle(tester);

    await tester.tap(find.byIcon(Icons.delete_sweep_outlined));
    await tester.pumpAndSettle();

    expect(find.text('إفراغ السلة؟'), findsOneWidget);
    expect(container.read(cartProvider), hasLength(1));

    await tester.tap(find.widgetWithText(TextButton, 'إفراغ السلة'));
    await tester.pumpAndSettle();

    expect(container.read(cartProvider), isEmpty);
  });

  testWidgets('two sizes of the same product show as two lines', (tester) async {
    final container = await pumpScreen(tester, const CartScreen());
    final cart = container.read(cartProvider.notifier);
    cart.add(
      Fixtures.pyjamaWithSizes,
      variant: Fixtures.pyjamaWithSizes.findVariant(color: 'خمري غامق', size: 'M'),
    );
    cart.add(
      Fixtures.pyjamaWithSizes,
      variant: Fixtures.pyjamaWithSizes.findVariant(color: 'خمري غامق', size: 'L'),
    );
    await settle(tester);

    expect(find.byType(CartLineTile), findsNWidgets(2));
  });
}
