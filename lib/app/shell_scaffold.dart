import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/cart/cart_controller.dart';
import '../l10n/app_localizations.dart';
import 'router.dart';
import 'theme.dart';

/// Persistent bottom navigation wrapping the five primary destinations.
///
/// Android's back gesture on a non-home tab returns to the home tab rather
/// than leaving the app, which is what shoppers expect from a tabbed store.
class ShellScaffold extends ConsumerWidget {
  const ShellScaffold({super.key, required this.state, required this.child});

  final GoRouterState state;
  final Widget child;

  static const List<String> _destinations = <String>[
    Routes.home,
    Routes.categories,
    Routes.search,
    Routes.favorites,
    Routes.cart,
  ];

  int get _currentIndex {
    final location = state.matchedLocation;
    final index = _destinations.indexOf(location);
    return index == -1 ? 0 : index;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cartCount = ref.watch(cartCountProvider);
    final index = _currentIndex;

    return PopScope(
      canPop: index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(Routes.home);
      },
      child: Scaffold(
        body: child,
        bottomNavigationBar: DecoratedBox(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: RawnqColors.line)),
          ),
          child: NavigationBar(
            selectedIndex: index,
            onDestinationSelected: (next) => context.go(_destinations[next]),
            destinations: <Widget>[
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home_rounded),
                label: l10n.navHome,
              ),
              NavigationDestination(
                icon: const Icon(Icons.grid_view_outlined),
                selectedIcon: const Icon(Icons.grid_view_rounded),
                label: l10n.navCategories,
              ),
              NavigationDestination(
                icon: const Icon(Icons.search_outlined),
                selectedIcon: const Icon(Icons.search_rounded),
                label: l10n.navSearch,
              ),
              NavigationDestination(
                icon: const Icon(Icons.favorite_border_rounded),
                selectedIcon: const Icon(Icons.favorite_rounded),
                label: l10n.navFavorites,
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: cartCount > 0,
                  label: Text('$cartCount'),
                  backgroundColor: RawnqColors.terracotta,
                  child: const Icon(Icons.shopping_bag_outlined),
                ),
                selectedIcon: Badge(
                  isLabelVisible: cartCount > 0,
                  label: Text('$cartCount'),
                  backgroundColor: RawnqColors.terracotta,
                  child: const Icon(Icons.shopping_bag_rounded),
                ),
                label: l10n.navCart,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
