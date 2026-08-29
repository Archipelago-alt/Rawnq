import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/config/app_config.dart';
import '../../core/utils/launcher.dart';
import '../../core/widgets/catalog_scaffold.dart';
import '../../core/widgets/state_views.dart';
import '../../l10n/app_localizations.dart';

enum PolicyKind { privacy, terms }

/// Renders the shop's own privacy policy or terms.
///
/// The shop has not published either text yet, so rather than inventing legal
/// copy the screen says so plainly and links to the published page on the
/// website. The moment the shop fills the field in, the real text appears.
class PolicyScreen extends ConsumerWidget {
  const PolicyScreen({super.key, required this.kind});

  final PolicyKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final title = switch (kind) {
      PolicyKind.privacy => l10n.policyPrivacyTitle,
      PolicyKind.terms => l10n.policyTermsTitle,
    };

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: CatalogView(
        skeleton: (context) => const <Widget>[
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(RawnqSpace.xxl),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
        ],
        builder: (context, catalog) {
          final store = catalog.store;
          final body = switch (kind) {
            PolicyKind.privacy => store.hasPrivacyPolicy ? store.privacyPolicy : null,
            PolicyKind.terms => store.hasTermsConditions ? store.termsConditions : null,
          };
          final webUrl = switch (kind) {
            PolicyKind.privacy => StorefrontLinks.privacyPolicy,
            PolicyKind.terms => StorefrontLinks.termsConditions,
          };

          if (body == null) {
            return <Widget>[
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyStateView(
                  icon: Icons.description_outlined,
                  title: l10n.policyNotPublished,
                  body: l10n.policyNotPublishedHint,
                  action: OutlinedButton.icon(
                    onPressed: () => ExternalLauncher.open(webUrl),
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: Text(l10n.policyOpenOnWebsite),
                  ),
                ),
              ),
            ];
          }

          return <Widget>[
            SliverPadding(
              padding: const EdgeInsets.all(RawnqSpace.lg),
              sliver: SliverToBoxAdapter(
                child: Text(body, style: Theme.of(context).textTheme.bodyMedium),
              ),
            ),
          ];
        },
      ),
    );
  }
}
