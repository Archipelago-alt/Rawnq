import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/shimmer_box.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/store_info.dart';

/// Branded banner at the top of the home screen: the real RAWNQ logo on the
/// cream ground taken from the shop's own artwork, with the store's slogan.
class HomeHero extends StatelessWidget {
  const HomeHero({super.key, required this.store, required this.onContactPressed});

  final StoreInfo store;
  final VoidCallback onContactPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final slogan = store.slogan ?? l10n.storeSlogan;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        RawnqSpace.lg,
        RawnqSpace.sm,
        RawnqSpace.lg,
        RawnqSpace.xl,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[RawnqColors.cream, RawnqColors.sand],
        ),
      ),
      child: Column(
        children: <Widget>[
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: IconButton(
              onPressed: onContactPressed,
              tooltip: l10n.navContact,
              icon: const Icon(Icons.support_agent_rounded, color: RawnqColors.brown),
            ),
          ),
          // The official logo asset, used unmodified.
          ClipOval(
            child: Image.asset(
              'assets/brand/rawnq_logo.jpg',
              width: 108,
              height: 108,
              fit: BoxFit.cover,
              semanticLabel: store.label,
            ),
          ),
          const SizedBox(height: RawnqSpace.md),
          Text(
            store.label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: RawnqColors.brown,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: RawnqSpace.xs),
          Text(
            slogan,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: RawnqColors.inkSoft,
                ),
          ),
        ],
      ),
    );
  }
}

class HomeHeroSkeleton extends StatelessWidget {
  const HomeHeroSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Shimmer(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: RawnqSpace.xl),
        child: Column(
          children: <Widget>[
            ShimmerBox(width: 108, height: 108, shape: BoxShape.circle),
            SizedBox(height: RawnqSpace.md),
            ShimmerBox(width: 160, height: 20),
            SizedBox(height: RawnqSpace.sm),
            ShimmerBox(width: 200, height: 14),
          ],
        ),
      ),
    );
  }
}
