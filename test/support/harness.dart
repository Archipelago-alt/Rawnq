import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rawnq/app/app.dart';
import 'package:rawnq/app/providers.dart';
import 'package:rawnq/app/router.dart';
import 'package:rawnq/app/theme.dart';
import 'package:rawnq/l10n/app_localizations.dart';
import 'package:rawnq/shared/data/catalog_repository.dart';
import 'package:rawnq/shared/models/catalog.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fixtures.dart';

/// A repository that never touches the network.
///
/// Every widget and repository test runs against this, so the suite does not
/// depend on the live storefront being reachable.
class FakeCatalogRepository implements CatalogRepository {
  FakeCatalogRepository({
    Catalog? catalog,
    this.error,
    this.delay = Duration.zero,
  }) : _catalog = catalog;

  final Catalog? _catalog;
  final Object? error;
  final Duration delay;

  int loadCount = 0;
  int forceRefreshCount = 0;

  @override
  Future<Catalog> loadCatalog({bool forceRefresh = false}) async {
    loadCount++;
    if (forceRefresh) forceRefreshCount++;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    final failure = error;
    if (failure != null) throw failure;
    return _catalog ?? Fixtures.catalog();
  }
}

/// Gives the test a realistic portrait phone surface.
///
/// The default 800x600 test window is landscape, which puts a square product
/// gallery taller than the viewport and leaves the content below it outside
/// the lazy-mount cache extent. The app is portrait-only, so tests should
/// measure it that way.
void usePhoneSurface(
  WidgetTester tester, {
  Size size = const Size(1080, 2340),
}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
}

/// Boots the app under test with fake persistence and a fake repository.
///
/// Returns the container so a test can read providers directly.
Future<ProviderContainer> pumpApp(
  WidgetTester tester, {
  CatalogRepository? repository,
  String initialLocation = Routes.home,
  Map<String, Object> preferences = const <String, Object>{},
}) async {
  usePhoneSurface(tester);
  SharedPreferences.setMockInitialValues(Map<String, Object>.of(preferences));
  final prefs = await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      catalogRepositoryProvider.overrideWithValue(
        repository ?? FakeCatalogRepository(),
      ),
      routerProvider.overrideWithValue(
        buildRouter(initialLocation: initialLocation),
      ),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const RawnqApp()),
  );
  return container;
}

/// Pumps a single widget inside the app's theme, localisations and RTL
/// directionality — everything a screen normally relies on.
Future<ProviderContainer> pumpScreen(
  WidgetTester tester,
  Widget child, {
  CatalogRepository? repository,
  Map<String, Object> preferences = const <String, Object>{},
}) async {
  usePhoneSurface(tester);
  SharedPreferences.setMockInitialValues(Map<String, Object>.of(preferences));
  final prefs = await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      catalogRepositoryProvider.overrideWithValue(
        repository ?? FakeCatalogRepository(),
      ),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildRawnqTheme(),
        locale: const Locale('ar'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const <LocalizationsDelegate<Object>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Directionality(textDirection: TextDirection.rtl, child: child),
      ),
    ),
  );
  return container;
}

/// Settles the tree without waiting forever on the shimmer, which repeats and
/// would make `pumpAndSettle` time out.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

/// Scrolls the primary scroll view until [finder] has been built and is
/// visible.
///
/// The home screen is a lazy CustomScrollView, so widgets below the fold are
/// not in the tree at all until they are scrolled towards. `find.byType`
/// reports zero matches for content a shopper would simply scroll to.
Future<void> scrollTo(
  WidgetTester tester,
  Finder finder, {
  double delta = 300,
  int maxScrolls = 60,
}) async {
  await tester.scrollUntilVisible(
    finder,
    delta,
    scrollable: find.byType(Scrollable).first,
    maxScrolls: maxScrolls,
  );
  await tester.pumpAndSettle();
}

/// Scrolls [finder] into view, then taps it.
///
/// Product detail is a long scroll on a phone: the option selectors sit below
/// the fold, and `tester.tap` fails hit-testing on an off-screen widget.
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Convenience matcher for a widget's `GoRouter` location.
String currentLocation(ProviderContainer container) {
  final router = container.read(routerProvider);
  return router.routerDelegate.currentConfiguration.uri.toString();
}
