import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/cart/cart_screen.dart';
import '../features/categories/categories_screen.dart';
import '../features/checkout/checkout_screen.dart';
import '../features/checkout/order_success_screen.dart';
import '../features/contact/contact_screen.dart';
import '../features/contact/policy_screen.dart';
import '../features/contact/web_checkout_screen.dart';
import '../features/favorites/favorites_screen.dart';
import '../features/home/home_screen.dart';
import '../features/products/product_detail_screen.dart';
import '../features/products/product_list_screen.dart';
import '../features/search/search_screen.dart';
import 'shell_scaffold.dart';

/// Named routes, so screens never build path strings by hand.
class Routes {
  const Routes._();

  static const String home = '/';
  static const String categories = '/categories';
  static const String search = '/search';
  static const String favorites = '/favorites';
  static const String cart = '/cart';
  static const String contact = '/contact';

  static const String products = '/products';
  static const String product = '/product';
  static const String checkout = '/checkout';
  static const String orderSuccess = '/order-success';
  static const String privacy = '/privacy';
  static const String terms = '/terms';
  static const String webCheckout = '/web-checkout';

  static String productPath(String id) => '$product/$id';
  static String categoryPath(String id) => '$products?category=$id';
  static String brandPath(String id) => '$products?brand=$id';
  static const String newArrivalsPath = '$products?scope=new';
  static const String allProductsPath = products;
}

GoRouter buildRouter({String initialLocation = Routes.home}) {
  // Created per router: reusing global keys across routers (as widget tests
  // build a fresh one per test) would attach one key to two trees.
  final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  final shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: initialLocation,
    routes: <RouteBase>[
      // The five bottom-navigation destinations share one scaffold so the bar
      // stays put while their content swaps.
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) => ShellScaffold(state: state, child: child),
        routes: <RouteBase>[
          GoRoute(
            path: Routes.home,
            pageBuilder: (context, state) => _fade(state, const HomeScreen()),
          ),
          GoRoute(
            path: Routes.categories,
            pageBuilder: (context, state) => _fade(state, const CategoriesScreen()),
          ),
          GoRoute(
            path: Routes.search,
            pageBuilder: (context, state) => _fade(state, const SearchScreen()),
          ),
          GoRoute(
            path: Routes.favorites,
            pageBuilder: (context, state) => _fade(state, const FavoritesScreen()),
          ),
          GoRoute(
            path: Routes.cart,
            pageBuilder: (context, state) => _fade(state, const CartScreen()),
          ),
        ],
      ),
      GoRoute(
        path: Routes.products,
        builder: (context, state) => ProductListScreen(
          categoryId: state.uri.queryParameters['category'],
          brandId: state.uri.queryParameters['brand'],
          scope: state.uri.queryParameters['scope'],
        ),
      ),
      GoRoute(
        path: '${Routes.product}/:id',
        builder: (context, state) =>
            ProductDetailScreen(productId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: Routes.checkout,
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: Routes.orderSuccess,
        builder: (context, state) => OrderSuccessScreen(
          reference: state.uri.queryParameters['ref'] ?? '',
        ),
      ),
      GoRoute(
        path: Routes.contact,
        builder: (context, state) => const ContactScreen(),
      ),
      GoRoute(
        path: Routes.privacy,
        builder: (context, state) => const PolicyScreen(kind: PolicyKind.privacy),
      ),
      GoRoute(
        path: Routes.terms,
        builder: (context, state) => const PolicyScreen(kind: PolicyKind.terms),
      ),
      GoRoute(
        path: Routes.webCheckout,
        builder: (context, state) => const WebCheckoutScreen(),
      ),
    ],
  );
}

CustomTransitionPage<void> _fade(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}
