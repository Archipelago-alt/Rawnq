import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/widgets/catalog_scaffold.dart';
import '../../core/widgets/state_views.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/models/catalog.dart';
import '../products/product_filters.dart';
import '../products/widgets/filter_sheet.dart';
import '../products/widgets/product_grid.dart';

/// Search over the catalogue, with the same Arabic normalisation the live
/// storefront applies (so `قمصان` finds `قُمْصَان`).
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  ProductFilter _filter = const ProductFilter();

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    // Debounced so a fast typist does not re-filter the list on every keypress.
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 220), () {
      if (mounted) setState(() => _filter = _filter.copyWith(query: value));
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final catalog = ref.watch(loadedCatalogProvider);
    final refinements = _filter.activeRefinementCount;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.searchTitle),
        actions: <Widget>[
          IconButton(
            tooltip: l10n.filtersTitle,
            onPressed: catalog == null ? null : () => _openFilters(catalog),
            icon: Badge(
              isLabelVisible: refinements > 0,
              label: Text('$refinements'),
              backgroundColor: RawnqColors.terracotta,
              child: const Icon(Icons.tune_rounded),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(72),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              RawnqSpace.lg,
              0,
              RawnqSpace.lg,
              RawnqSpace.md,
            ),
            child: TextField(
              controller: _controller,
              onChanged: _onQueryChanged,
              textInputAction: TextInputAction.search,
              autocorrect: false,
              decoration: InputDecoration(
                hintText: l10n.searchHint,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: l10n.closeLabel,
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _controller.clear();
                          _onQueryChanged('');
                          setState(() {});
                        },
                      ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: RawnqSpace.lg,
                  vertical: RawnqSpace.md,
                ),
              ),
            ),
          ),
        ),
      ),
      body: CatalogView(
        skeleton: (context) => const <Widget>[ProductSliverGridSkeleton(itemCount: 4)],
        builder: (context, data) {
          if (_filter.query.trim().isEmpty && !_filter.hasActiveRefinements) {
            return <Widget>[
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyStateView(
                  icon: Icons.search_rounded,
                  title: l10n.searchStartHint,
                  body: l10n.searchHint,
                ),
              ),
            ];
          }

          final results = _filter.apply(data.products);
          if (results.isEmpty) {
            return <Widget>[
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyStateView(
                  icon: Icons.search_off_rounded,
                  title: l10n.searchNoResults,
                  body: l10n.searchNoResultsHint,
                ),
              ),
            ];
          }

          return <Widget>[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  RawnqSpace.lg,
                  RawnqSpace.sm,
                  RawnqSpace.lg,
                  0,
                ),
                child: Text(
                  l10n.searchResultCount(results.length),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
            ProductSliverGrid(
              products: results,
              onProductTap: (product) => context.push(Routes.productPath(product.id)),
            ),
          ];
        },
      ),
    );
  }

  Future<void> _openFilters(Catalog catalog) async {
    final next = await showProductFilterSheet(
      context,
      filter: _filter,
      brands: catalog.brands,
    );
    if (next != null && mounted) setState(() => _filter = next);
  }
}
