import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rawnq/core/utils/result.dart';
import 'package:rawnq/core/widgets/state_views.dart';
import 'package:rawnq/features/home/home_screen.dart';
import 'package:rawnq/features/home/widgets/brand_strip.dart';
import 'package:rawnq/features/home/widgets/category_strip.dart';
import 'package:rawnq/features/products/widgets/product_card.dart';
import 'package:rawnq/shared/models/catalog.dart';

import '../support/fixtures.dart';
import '../support/harness.dart';

void main() {
  testWidgets('shows the brand header, categories, brands and products', (
    tester,
  ) async {
    await pumpScreen(tester, const HomeScreen());
    await settle(tester);

    expect(find.text('رونق | RAWNQ'), findsWidgets);
    expect(find.text('لأنكِ تستحقين الأجمل'), findsOneWidget);
    expect(find.byType(CategoryStrip), findsOneWidget);
    expect(find.byType(BrandStrip), findsOneWidget);
    expect(find.byType(ProductCard), findsWidgets);
  });

  testWidgets('renders the real category names from the catalogue', (
    tester,
  ) async {
    await pumpScreen(tester, const HomeScreen());
    await settle(tester);

    expect(find.text('بجامات'), findsWidgets);
    expect(find.text('قُمْصَان'), findsWidgets);
  });

  testWidgets('shows skeletons before the catalogue arrives', (tester) async {
    await pumpScreen(
      tester,
      const HomeScreen(),
      repository: FakeCatalogRepository(delay: const Duration(seconds: 2)),
    );
    await tester.pump();

    expect(find.byType(ProductCardSkeleton), findsWidgets);
    expect(find.byType(ProductCard), findsNothing);

    await tester.pump(const Duration(seconds: 3));
    await settle(tester);

    expect(find.byType(ProductCard), findsWidgets);
  });

  testWidgets('shows an offline state with a retry action when loading fails', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      const HomeScreen(),
      repository: FakeCatalogRepository(
        error: const Failure(FailureKind.offline),
      ),
    );
    await settle(tester);

    expect(find.byType(ErrorStateView), findsOneWidget);
    expect(find.text('لا يوجد اتصال بالإنترنت'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);
  });

  testWidgets(
    'labels bundled snapshot data instead of passing it off as live',
    (tester) async {
      await pumpScreen(
        tester,
        const HomeScreen(),
        repository: FakeCatalogRepository(
          catalog: Catalog(
            store: Fixtures.store,
            categories: const [],
            brands: const [],
            products: const [],
            deliveryLocations: const [],
            paymentMethods: const [],
            isLiveData: false,
            capturedAt: DateTime.utc(2026, 8, 29),
          ),
        ),
      );
      await settle(tester);

      expect(find.byType(NoticeBanner), findsOneWidget);
      expect(find.textContaining('بيانات محلية'), findsOneWidget);
    },
  );

  testWidgets('live data shows no local-data banner', (tester) async {
    await pumpScreen(tester, const HomeScreen());
    await settle(tester);

    expect(find.byType(NoticeBanner), findsNothing);
  });

  testWidgets('pull to refresh asks the repository for fresh data', (
    tester,
  ) async {
    final repository = FakeCatalogRepository();
    await pumpScreen(tester, const HomeScreen(), repository: repository);
    await settle(tester);

    await tester.fling(
      find.byType(CustomScrollView),
      const Offset(0, 400),
      1000,
    );
    await settle(tester);

    expect(repository.forceRefreshCount, greaterThan(0));
  });

  testWidgets('lays out without overflow on a small phone', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpScreen(tester, const HomeScreen());
    await settle(tester);

    expect(tester.takeException(), isNull);
  });
}
