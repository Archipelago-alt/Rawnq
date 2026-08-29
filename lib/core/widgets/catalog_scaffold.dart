import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/models/catalog.dart';
import 'state_views.dart';

/// Wraps a screen that needs the catalogue.
///
/// Handles the loading skeleton, the error state with retry, pull-to-refresh
/// and the "this is local data" notice in one place, so individual screens
/// only describe their content.
class CatalogView extends ConsumerWidget {
  const CatalogView({
    super.key,
    required this.builder,
    required this.skeleton,
    this.onRefresh,
  });

  /// Builds the screen's slivers once the catalogue is available.
  final List<Widget> Function(BuildContext context, Catalog catalog) builder;

  /// Slivers shown while loading.
  final List<Widget> Function(BuildContext context) skeleton;

  /// Extra work to run on pull-to-refresh, after the catalogue reloads.
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogProvider);

    return catalog.when(
      loading: () => CustomScrollView(
        physics: const NeverScrollableScrollPhysics(),
        slivers: skeleton(context),
      ),
      error: (error, _) => ErrorStateView(
        error: error,
        onRetry: () => ref.invalidate(catalogProvider),
      ),
      data: (data) => RefreshIndicator(
        color: RawnqColors.brown,
        onRefresh: () async {
          await refreshCatalog(ref);
          await onRefresh?.call();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: <Widget>[
            if (!data.isLiveData) _LocalDataNotice(catalog: data),
            ...builder(context, data),
          ],
        ),
      ),
    );
  }
}

/// Says plainly that the screen is showing the bundled snapshot rather than
/// live storefront data.
class _LocalDataNotice extends StatelessWidget {
  const _LocalDataNotice({required this.catalog});

  final Catalog catalog;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final captured = catalog.capturedAt?.toLocal();
    // A plain numeric date avoids pulling in locale-specific date symbols,
    // which would need `initializeDateFormatting` before first use.
    final date = captured == null
        ? '—'
        : '${captured.year}/${_two(captured.month)}/${_two(captured.day)}';

    return SliverToBoxAdapter(
      child: NoticeBanner(
        icon: Icons.info_outline_rounded,
        message: l10n.localDataBanner(date),
      ),
    );
  }
}

String _two(int value) => value.toString().padLeft(2, '0');

/// A section heading with an optional "see all" action.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        RawnqSpace.lg,
        RawnqSpace.xl,
        RawnqSpace.sm,
        RawnqSpace.sm,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleLarge,
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(actionLabel!),
                  const Icon(Icons.chevron_left_rounded, size: 18),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
