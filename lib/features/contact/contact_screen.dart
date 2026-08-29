import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/config/app_config.dart';
import '../../core/utils/launcher.dart';
import '../../core/utils/money.dart';
import '../../core/widgets/catalog_scaffold.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/models/catalog.dart';
import '../../shared/models/store_info.dart';

/// Store information and contact actions, built from the shop's own published
/// details — nothing here is invented.
class ContactScreen extends ConsumerWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.contactTitle)),
      body: CatalogView(
        skeleton: (context) => const <Widget>[
          SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
        ],
        builder: (context, catalog) {
          final store = catalog.store;
          final whatsapp = store.whatsappDigits;

          return <Widget>[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(RawnqSpace.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (whatsapp != null)
                      _ActionTile(
                        icon: Icons.chat_rounded,
                        title: l10n.contactWhatsapp,
                        subtitle: store.whatsapp,
                        onTap: () => _open(context, Uri.https('wa.me', '/$whatsapp')),
                      ),
                    if (store.whatsapp != null)
                      _ActionTile(
                        icon: Icons.call_rounded,
                        title: l10n.contactCall,
                        subtitle: store.whatsapp,
                        onTap: () => _open(
                          context,
                          Uri(scheme: 'tel', path: store.whatsapp!.replaceAll(' ', '')),
                        ),
                      ),
                    if (store.email != null)
                      _ActionTile(
                        icon: Icons.mail_outline_rounded,
                        title: store.email!,
                        onTap: () => _open(context, Uri(scheme: 'mailto', path: store.email)),
                      ),
                    if (store.instagram != null)
                      _ActionTile(
                        icon: Icons.camera_alt_outlined,
                        title: l10n.contactInstagram,
                        onTap: () => _openString(context, store.instagram),
                      ),
                    if (store.facebook != null)
                      _ActionTile(
                        icon: Icons.facebook_rounded,
                        title: 'Facebook',
                        onTap: () => _openString(context, store.facebook),
                      ),
                    _ActionTile(
                      icon: Icons.language_rounded,
                      title: l10n.contactWebsite,
                      onTap: () => _open(context, StorefrontLinks.storefront),
                    ),

                    const SizedBox(height: RawnqSpace.xl),
                    Text(l10n.contactStoreInfo, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: RawnqSpace.md),
                    _InfoCard(store: store, catalogSummary: _summary(context, catalog)),

                    const SizedBox(height: RawnqSpace.xl),
                    _ActionTile(
                      icon: Icons.privacy_tip_outlined,
                      title: l10n.policyPrivacyTitle,
                      onTap: () => context.push(Routes.privacy),
                    ),
                    _ActionTile(
                      icon: Icons.gavel_rounded,
                      title: l10n.policyTermsTitle,
                      onTap: () => context.push(Routes.terms),
                    ),

                    if (store.showBringusBranding) ...<Widget>[
                      const SizedBox(height: RawnqSpace.xl),
                      Center(
                        child: Text(
                          l10n.poweredBy,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                    const SizedBox(height: RawnqSpace.xxl),
                  ],
                ),
              ),
            ),
          ];
        },
      ),
    );
  }

  List<(String, String)> _summary(BuildContext context, Catalog catalog) {
    final l10n = AppLocalizations.of(context);
    final StoreInfo store = catalog.store;
    return <(String, String)>[
      if (store.country != null) (l10n.contactCountry, store.country!),
      (l10n.contactCurrency, '${Money.symbol} (${store.currency})'),
      if (catalog.deliveryLocations.isNotEmpty)
        (
          l10n.contactDeliveryAreas,
          catalog.deliveryLocations
              .map((location) => location.isFree
                  ? '${location.name} — ${l10n.cartFreeDelivery}'
                  : '${location.name} — ${Money.format(location.price)}')
              .join('\n'),
        ),
      if (catalog.paymentMethods.isNotEmpty)
        (
          l10n.contactPaymentMethods,
          catalog.paymentMethods.map((method) => method.name).join('\n'),
        ),
    ];
  }

  Future<void> _open(BuildContext context, Uri uri) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    if (!await ExternalLauncher.open(uri)) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorCannotOpenLink)));
    }
  }

  Future<void> _openString(BuildContext context, String? value) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    if (!await ExternalLauncher.openUrlString(value)) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorCannotOpenLink)));
    }
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: RawnqSpace.md),
      child: Material(
        color: RawnqColors.surface,
        borderRadius: BorderRadius.circular(RawnqSpace.radiusMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(RawnqSpace.radiusMd),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(RawnqSpace.radiusMd),
              border: Border.all(color: RawnqColors.line),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: RawnqColors.cream,
                child: Icon(icon, color: RawnqColors.brown, size: 20),
              ),
              title: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: subtitle == null
                  ? null
                  : Text(
                      subtitle!,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.right,
                    ),
              trailing: const Icon(Icons.chevron_left_rounded, color: RawnqColors.inkSoft),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.store, required this.catalogSummary});

  final StoreInfo store;
  final List<(String, String)> catalogSummary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(RawnqSpace.lg),
      decoration: BoxDecoration(
        color: RawnqColors.surface,
        borderRadius: BorderRadius.circular(RawnqSpace.radiusMd),
        border: Border.all(color: RawnqColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(store.label, style: theme.textTheme.titleMedium),
          if (store.slogan != null) ...<Widget>[
            const SizedBox(height: 2),
            Text(store.slogan!, style: theme.textTheme.bodySmall),
          ],
          if (store.hasAboutUs) ...<Widget>[
            const SizedBox(height: RawnqSpace.md),
            Text(store.aboutUs!, style: theme.textTheme.bodyMedium),
          ],
          for (final (label, value) in catalogSummary) ...<Widget>[
            const SizedBox(height: RawnqSpace.md),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(value, style: theme.textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}
