import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/utils/money.dart';
import '../../core/widgets/state_views.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/models/cart_item.dart';
import '../../shared/models/checkout_options.dart';
import 'cart_controller.dart';
import 'widgets/cart_line_tile.dart';

/// The السلة tab.
class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final items = ref.watch(cartProvider);
    final subtotal = ref.watch(cartSubtotalProvider);
    final catalog = ref.watch(loadedCatalogProvider);

    // The shop configures one delivery area (غزة, free); its fee is shown
    // before the order is sent, never invented.
    final delivery = catalog?.deliveryLocations.isNotEmpty ?? false
        ? catalog!.deliveryLocations.first
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.cartTitle),
        actions: <Widget>[
          if (items.isNotEmpty)
            IconButton(
              tooltip: l10n.cartClear,
              onPressed: () => _confirmClear(context, ref),
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
        ],
      ),
      body: items.isEmpty
          ? EmptyStateView(
              icon: Icons.shopping_bag_outlined,
              title: l10n.cartEmpty,
              body: l10n.cartEmptyHint,
              action: OutlinedButton(
                onPressed: () => context.go(Routes.home),
                child: Text(l10n.cartStartShopping),
              ),
            )
          : Column(
              children: <Widget>[
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(RawnqSpace.lg),
                    itemCount: items.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: RawnqSpace.md),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return CartLineTile(
                        key: ValueKey<String>(item.key),
                        item: item,
                        onRemove: () => _removeWithUndo(context, ref, item),
                      );
                    },
                  ),
                ),
                _CartSummary(subtotal: subtotal, delivery: delivery),
              ],
            ),
    );
  }

  void _removeWithUndo(BuildContext context, WidgetRef ref, CartItem item) {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(cartProvider.notifier);
    final index = controller.indexOf(item.key);
    controller.remove(item.key);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.cartRemoved),
          action: SnackBarAction(
            label: l10n.cartUndo,
            textColor: Colors.white,
            onPressed: () => controller.restore(item, at: index),
          ),
        ),
      );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.cartClearConfirmTitle),
        content: Text(l10n.cartClearConfirmBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.closeLabel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: RawnqColors.sale),
            child: Text(l10n.cartClear),
          ),
        ],
      ),
    );
    if (confirmed ?? false) ref.read(cartProvider.notifier).clear();
  }
}

class _CartSummary extends ConsumerWidget {
  const _CartSummary({required this.subtotal, required this.delivery});

  final double subtotal;
  final DeliveryLocation? delivery;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final count = ref.watch(cartCountProvider);
    final fee = delivery?.price ?? 0;
    final total = subtotal + fee;

    return Material(
      color: RawnqColors.surface,
      elevation: 8,
      shadowColor: const Color(0x1A7C3918),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(RawnqSpace.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _SummaryRow(label: l10n.cartItemCount(count), value: ''),
              const SizedBox(height: RawnqSpace.sm),
              _SummaryRow(
                label: l10n.cartSubtotal,
                value: Money.format(subtotal),
              ),
              if (delivery != null) ...<Widget>[
                const SizedBox(height: RawnqSpace.sm),
                _SummaryRow(
                  label: '${l10n.cartDelivery} — ${delivery!.name}',
                  value: delivery!.isFree
                      ? l10n.cartFreeDelivery
                      : Money.format(fee),
                ),
              ],
              const Padding(
                padding: EdgeInsets.symmetric(vertical: RawnqSpace.md),
                child: Divider(),
              ),
              _SummaryRow(
                label: l10n.cartTotal,
                value: Money.format(total),
                emphasise: true,
              ),
              const SizedBox(height: RawnqSpace.lg),
              ElevatedButton.icon(
                onPressed: () => context.push(Routes.checkout),
                icon: const Icon(Icons.arrow_back_rounded, size: 20),
                label: Text(l10n.cartCheckout),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasise = false,
  });

  final String label;
  final String value;
  final bool emphasise;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: emphasise
                ? theme.textTheme.titleMedium
                : theme.textTheme.bodyMedium?.copyWith(
                    color: RawnqColors.inkSoft,
                  ),
          ),
        ),
        Text(
          value,
          style: emphasise
              ? const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: RawnqColors.brown,
                )
              : theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
        ),
      ],
    );
  }
}
