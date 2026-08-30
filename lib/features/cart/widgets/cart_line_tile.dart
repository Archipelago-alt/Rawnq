import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/product_image.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/cart_item.dart';
import '../cart_controller.dart';

/// One cart line: photo, name, chosen options, quantity stepper and remove.
class CartLineTile extends ConsumerWidget {
  const CartLineTile({super.key, required this.item, required this.onRemove});

  final CartItem item;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final options = <String>[
      if ((item.color ?? '').isNotEmpty)
        '${l10n.whatsappOrderColor}: ${item.color}',
      if ((item.size ?? '').isNotEmpty)
        '${l10n.whatsappOrderSize}: ${item.size}',
    ].join('  •  ');

    return Container(
      padding: const EdgeInsets.all(RawnqSpace.md),
      decoration: BoxDecoration(
        color: RawnqColors.surface,
        borderRadius: BorderRadius.circular(RawnqSpace.radiusMd),
        boxShadow: kCardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 84,
            height: 84,
            child: ProductImage(
              url: item.imageUrl,
              decodeWidth: 200,
              semanticLabel: item.name,
            ),
          ),
          const SizedBox(width: RawnqSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (options.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(options, style: theme.textTheme.bodySmall),
                ],
                const SizedBox(height: RawnqSpace.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    // The stepper has a fixed width, so the price yields
                    // first: a long total at a large text scale would
                    // otherwise overflow the narrow remaining column.
                    Flexible(
                      child: Text(
                        Money.format(item.lineTotal),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: RawnqColors.brown,
                        ),
                      ),
                    ),
                    const SizedBox(width: RawnqSpace.sm),
                    _QuantityStepper(item: item),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: l10n.cartRemove,
            onPressed: onRemove,
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: RawnqColors.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityStepper extends ConsumerWidget {
  const _QuantityStepper({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final max = item.maxQuantity;
    final canIncrease = max == null || item.quantity < max;

    return Container(
      decoration: BoxDecoration(
        color: RawnqColors.cream,
        borderRadius: BorderRadius.circular(RawnqSpace.radiusLg),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _StepButton(
            icon: Icons.remove_rounded,
            tooltip: l10n.cartDecrease,
            onPressed: () =>
                ref.read(cartProvider.notifier).decrement(item.key),
          ),
          SizedBox(
            width: 34,
            child: Text(
              Money.count(item.quantity),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          _StepButton(
            icon: Icons.add_rounded,
            tooltip: l10n.cartIncrease,
            onPressed: !canIncrease
                ? null
                : () {
                    final result = ref
                        .read(cartProvider.notifier)
                        .increment(item.key);
                    if (!result.isSuccess &&
                        result.error == CartAddError.maxQuantity) {
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          SnackBar(
                            content: Text(
                              l10n.cartMaxQuantityReached(
                                result.availableQuantity ?? 0,
                              ),
                            ),
                          ),
                        );
                    }
                  },
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: InkResponse(
        onTap: onPressed,
        radius: 22,
        child: Padding(
          padding: const EdgeInsets.all(RawnqSpace.sm),
          child: Icon(
            icon,
            size: 18,
            color: onPressed == null ? RawnqColors.inkSoft : RawnqColors.brown,
          ),
        ),
      ),
    );
  }
}
