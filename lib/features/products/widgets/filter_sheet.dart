import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/category.dart';
import '../product_filters.dart';

/// Bottom sheet for refining and ordering a product list.
///
/// Returns the new filter, or null when dismissed without applying.
Future<ProductFilter?> showProductFilterSheet(
  BuildContext context, {
  required ProductFilter filter,
  required List<Brand> brands,
}) {
  return showModalBottomSheet<ProductFilter>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _FilterSheet(filter: filter, brands: brands),
  );
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.filter, required this.brands});

  final ProductFilter filter;
  final List<Brand> brands;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late ProductFilter _draft = widget.filter;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          RawnqSpace.lg,
          0,
          RawnqSpace.lg,
          RawnqSpace.lg,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(l10n.filtersTitle, style: theme.textTheme.titleLarge),
              const SizedBox(height: RawnqSpace.lg),
              if (widget.brands.isNotEmpty) ...<Widget>[
                Text(l10n.filterBrand, style: theme.textTheme.titleMedium),
                const SizedBox(height: RawnqSpace.sm),
                Wrap(
                  spacing: RawnqSpace.sm,
                  runSpacing: RawnqSpace.sm,
                  children: <Widget>[
                    ChoiceChip(
                      label: Text(l10n.filterAll),
                      selected: _draft.brandId == null,
                      onSelected: (_) => setState(() {
                        _draft = _draft.copyWith(clearBrand: true);
                      }),
                    ),
                    for (final brand in widget.brands)
                      ChoiceChip(
                        label: Text(brand.name),
                        selected: _draft.brandId == brand.id,
                        onSelected: (_) => setState(() {
                          _draft = _draft.copyWith(brandId: brand.id);
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: RawnqSpace.lg),
              ],
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.filterOnlyAvailable),
                value: _draft.onlyAvailable,
                activeThumbColor: RawnqColors.brown,
                onChanged: (value) => setState(() {
                  _draft = _draft.copyWith(onlyAvailable: value);
                }),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.filterOnlyNew),
                value: _draft.onlyNew,
                activeThumbColor: RawnqColors.brown,
                onChanged: (value) => setState(() {
                  _draft = _draft.copyWith(onlyNew: value);
                }),
              ),
              const SizedBox(height: RawnqSpace.md),
              Text(l10n.sortTitle, style: theme.textTheme.titleMedium),
              const SizedBox(height: RawnqSpace.sm),
              RadioGroup<ProductSort>(
                groupValue: _draft.sort,
                onChanged: (value) => setState(() {
                  if (value != null) _draft = _draft.copyWith(sort: value);
                }),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    for (final sort in ProductSort.values)
                      RadioListTile<ProductSort>(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        value: sort,
                        title: Text(_sortLabel(l10n, sort)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: RawnqSpace.lg),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _draft = _draft.reset()),
                      child: Text(l10n.filterReset),
                    ),
                  ),
                  const SizedBox(width: RawnqSpace.md),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(_draft),
                      child: Text(l10n.filterApply),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _sortLabel(AppLocalizations l10n, ProductSort sort) => switch (sort) {
      ProductSort.defaultOrder => l10n.sortDefault,
      ProductSort.priceAsc => l10n.sortPriceAsc,
      ProductSort.priceDesc => l10n.sortPriceDesc,
      ProductSort.nameAsc => l10n.sortNameAsc,
      ProductSort.newest => l10n.sortNewest,
    };
