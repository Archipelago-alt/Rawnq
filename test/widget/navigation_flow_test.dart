import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rawnq/features/cart/cart_controller.dart';
import 'package:rawnq/features/cart/cart_screen.dart';
import 'package:rawnq/features/categories/categories_screen.dart';
import 'package:rawnq/features/favorites/favorites_screen.dart';
import 'package:rawnq/features/home/home_screen.dart';
import 'package:rawnq/features/products/product_detail_screen.dart';
import 'package:rawnq/features/products/product_list_screen.dart';
import 'package:rawnq/features/products/widgets/product_card.dart';
import 'package:rawnq/features/search/search_screen.dart';

import '../support/fixtures.dart';
import '../support/harness.dart';

void main() {
  testWidgets('the bottom bar moves between the five primary destinations',
      (tester) async {
    await pumpApp(tester);
    await settle(tester);

    expect(find.byType(HomeScreen), findsOneWidget);

    await tester.tap(find.text('الفئات'));
    await settle(tester);
    expect(find.byType(CategoriesScreen), findsOneWidget);

    await tester.tap(find.text('البحث'));
    await settle(tester);
    expect(find.byType(SearchScreen), findsOneWidget);

    await tester.tap(find.text('المفضلة'));
    await settle(tester);
    expect(find.byType(FavoritesScreen), findsOneWidget);

    await tester.tap(find.text('السلة'));
    await settle(tester);
    expect(find.byType(CartScreen), findsOneWidget);
  });

  testWidgets('home → category → product → cart is a complete shopping flow',
      (tester) async {
    final container = await pumpApp(tester);
    await settle(tester);

    // Home into a category listing.
    await tester.tap(find.text('الفئات'));
    await settle(tester);
    await tester.tap(find.text('بجامات').first);
    await settle(tester);
    expect(find.byType(ProductListScreen), findsOneWidget);

    // Category listing into the product detail.
    await tester.tap(find.byType(ProductCard).first);
    await settle(tester);
    expect(find.byType(ProductDetailScreen), findsOneWidget);
    expect(find.text(Fixtures.pyjamaWithSizes.name), findsOneWidget);

    // Choose the mandatory options and add to the cart.
    await tester.tap(find.text('خمري غامق').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('L'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('أضيفي إلى السلة'));
    await tester.pump();

    expect(container.read(cartProvider), hasLength(1));

    // The snack bar offers a shortcut into the cart.
    await tester.tap(find.byType(SnackBarAction));
    await settle(tester);

    expect(find.byType(CartScreen), findsOneWidget);
    expect(currentLocation(container), '/cart');
  });

  testWidgets('back from a pushed screen returns to the shell', (tester) async {
    final container = await pumpApp(tester);
    await settle(tester);

    await tester.tap(find.text('الفئات'));
    await settle(tester);
    await tester.tap(find.text('قُمْصَان').first);
    await settle(tester);
    expect(find.byType(ProductListScreen), findsOneWidget);

    await tester.pageBack();
    await settle(tester);

    expect(find.byType(CategoriesScreen), findsOneWidget);
    expect(currentLocation(container), '/categories');
  });

  testWidgets('Android back from a non-home tab returns to home rather than exiting',
      (tester) async {
    final container = await pumpApp(tester);
    await settle(tester);

    await tester.tap(find.text('المفضلة'));
    await settle(tester);
    expect(currentLocation(container), '/favorites');

    // Simulate the system back gesture.
    final widgetsBinding = tester.binding;
    await widgetsBinding.handlePopRoute();
    await settle(tester);

    expect(currentLocation(container), '/');
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('searching navigates to a matching product', (tester) async {
    await pumpApp(tester);
    await settle(tester);

    await tester.tap(find.text('البحث'));
    await settle(tester);

    // Undiacritised query against the diacritised catalogue name.
    await tester.enterText(find.byType(TextField), 'بجامه');
    await tester.pump(const Duration(milliseconds: 400));
    await settle(tester);

    expect(find.byType(ProductCard), findsOneWidget);

    await tester.tap(find.byType(ProductCard).first);
    await settle(tester);

    expect(find.byType(ProductDetailScreen), findsOneWidget);
    expect(find.text(Fixtures.pyjamaWithSizes.name), findsOneWidget);
  });

  testWidgets('the cart badge reflects what is in the cart', (tester) async {
    final container = await pumpApp(tester);
    await settle(tester);

    expect(find.descendant(of: find.byType(Badge), matching: find.text('1')),
        findsNothing);

    container.read(cartProvider.notifier).add(Fixtures.shirtNoVariants);
    await tester.pump();

    expect(find.descendant(of: find.byType(Badge), matching: find.text('1')),
        findsOneWidget);
  });
}
