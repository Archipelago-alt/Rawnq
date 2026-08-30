import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/utils/launcher.dart';
import '../../core/utils/money.dart';
import '../../core/widgets/state_views.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/models/checkout_options.dart';
import '../cart/cart_controller.dart';
import 'order_draft.dart';

/// Order review and submission.
///
/// The shop's checkout runs on the platform, so this screen collects and
/// validates everything the shop needs and then hands off: to WhatsApp with a
/// formatted Arabic order, or to the official web checkout. No payment is
/// taken in the app.
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _notes = TextEditingController();

  DeliveryLocation? _delivery;
  StorePaymentMethod? _payment;

  /// Guards against a double tap submitting the order twice.
  bool _submitting = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = ref.watch(cartProvider);
    final subtotal = ref.watch(cartSubtotalProvider);
    final catalog = ref.watch(loadedCatalogProvider);

    if (items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.checkoutTitle)),
        body: EmptyStateView(
          icon: Icons.shopping_bag_outlined,
          title: l10n.cartEmpty,
          body: l10n.cartEmptyHint,
          action: OutlinedButton(
            onPressed: () => context.go(Routes.home),
            child: Text(l10n.cartStartShopping),
          ),
        ),
      );
    }

    final deliveries = catalog?.deliveryLocations ?? const <DeliveryLocation>[];
    final payments = catalog?.paymentMethods ?? const <StorePaymentMethod>[];
    // A single option is preselected — the shop offers exactly one delivery
    // area, so making the shopper tap it adds nothing.
    _delivery ??= deliveries.length == 1 ? deliveries.first : null;

    final fee = _delivery?.price ?? 0;
    final total = subtotal + fee;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.checkoutTitle)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(RawnqSpace.lg),
          children: <Widget>[
            _SectionTitle(l10n.checkoutYourDetails),
            TextFormField(
              controller: _name,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: l10n.checkoutName),
              validator: (value) => CheckoutValidator.isValidName(value ?? '')
                  ? null
                  : l10n.checkoutErrorName,
            ),
            const SizedBox(height: RawnqSpace.md),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s-]')),
              ],
              decoration: InputDecoration(
                labelText: l10n.checkoutPhone,
                hintText: l10n.checkoutPhoneHint,
              ),
              validator: (value) => CheckoutValidator.isValidPhone(value ?? '')
                  ? null
                  : l10n.checkoutErrorPhone,
            ),
            const SizedBox(height: RawnqSpace.md),
            TextFormField(
              controller: _notes,
              maxLines: 3,
              maxLength: 500,
              decoration: InputDecoration(labelText: l10n.checkoutNotes),
            ),

            if (deliveries.isNotEmpty) ...<Widget>[
              _SectionTitle(l10n.checkoutDelivery),
              RadioGroup<String>(
                groupValue: _delivery?.id,
                onChanged: (value) => setState(() {
                  _delivery = deliveries
                      .where((o) => o.id == value)
                      .firstOrNull;
                }),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    for (final option in deliveries)
                      RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        value: option.id,
                        title: Text(option.name),
                        subtitle: Text(
                          option.isFree
                              ? l10n.cartFreeDelivery
                              : Money.format(option.price),
                        ),
                      ),
                  ],
                ),
              ),
            ],

            if (payments.isNotEmpty) ...<Widget>[
              _SectionTitle(l10n.checkoutPayment),
              RadioGroup<String>(
                groupValue: _payment?.id,
                onChanged: (value) => setState(() {
                  _payment = payments.where((o) => o.id == value).firstOrNull;
                }),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    for (final option in payments)
                      RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        value: option.id,
                        title: Text(option.name),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: RawnqSpace.sm),
              Text(
                l10n.checkoutNoPaymentProcessing,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],

            _SectionTitle(l10n.checkoutSummary),
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: RawnqSpace.sm),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        '${item.name} × ${Money.count(item.quantity)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    Text(
                      Money.format(item.lineTotal),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            const Divider(height: RawnqSpace.xl),
            _TotalRow(label: l10n.cartSubtotal, value: Money.format(subtotal)),
            if (_delivery != null)
              _TotalRow(
                label: l10n.cartDelivery,
                value: _delivery!.isFree
                    ? l10n.cartFreeDelivery
                    : Money.format(fee),
              ),
            const SizedBox(height: RawnqSpace.sm),
            _TotalRow(
              label: l10n.cartTotal,
              value: Money.format(total),
              emphasise: true,
            ),

            const SizedBox(height: RawnqSpace.xl),
            ElevatedButton.icon(
              onPressed: _submitting ? null : _submitViaWhatsapp,
              icon: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.chat_rounded, size: 20),
              label: Text(
                _submitting ? l10n.checkoutSending : l10n.checkoutSend,
              ),
            ),
            const SizedBox(height: RawnqSpace.md),
            OutlinedButton.icon(
              onPressed: _submitting
                  ? null
                  : () => context.push(Routes.webCheckout),
              icon: const Icon(Icons.open_in_browser_rounded, size: 20),
              label: Text(l10n.checkoutOpenWebsite),
            ),
            const SizedBox(height: RawnqSpace.xxl),
          ],
        ),
      ),
    );
  }

  Future<void> _submitViaWhatsapp() async {
    final l10n = AppLocalizations.of(context);
    final catalog = ref.read(loadedCatalogProvider);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final delivery = _delivery;
    if (delivery == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.checkoutErrorDelivery)),
      );
      return;
    }
    final payment = _payment;
    if (payment == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.checkoutErrorPayment)),
      );
      return;
    }
    final whatsapp = catalog?.store.whatsappDigits;
    if (whatsapp == null) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorCannotOpenLink)));
      return;
    }

    setState(() => _submitting = true);

    final reference = _buildReference();
    final draft = OrderDraft(
      reference: reference,
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      items: ref.read(cartProvider),
      deliveryLocation: delivery,
      paymentMethod: payment,
      notes: _notes.text,
    );

    final opened = await ExternalLauncher.open(
      draft.toWhatsappUri(whatsapp, _labels(l10n)),
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (!opened) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorCannotOpenLink)));
      return;
    }

    // The cart is cleared only once WhatsApp actually opened, so a failed
    // hand-off never loses the shopper's basket.
    ref.read(cartProvider.notifier).clear();
    router.go('${Routes.orderSuccess}?ref=$reference');
  }

  /// Short, human-readable reference the shopper and the shop can quote.
  /// Derived from the clock only — it carries no personal data.
  String _buildReference() {
    final now = DateTime.now();
    final stamp = now.millisecondsSinceEpoch
        .remainder(100000)
        .toString()
        .padLeft(5, '0');
    return 'R${now.year % 100}${now.month.toString().padLeft(2, '0')}$stamp';
  }

  OrderMessageLabels _labels(AppLocalizations l10n) => OrderMessageLabels(
    header: l10n.whatsappOrderHeader,
    items: l10n.whatsappOrderItems,
    customer: l10n.whatsappOrderCustomer,
    phone: l10n.whatsappOrderPhone,
    area: l10n.whatsappOrderArea,
    payment: l10n.whatsappOrderPayment,
    notes: l10n.whatsappOrderNotes,
    subtotal: l10n.whatsappOrderSubtotal,
    deliveryFee: l10n.whatsappOrderDeliveryFee,
    total: l10n.whatsappOrderTotal,
    color: l10n.whatsappOrderColor,
    size: l10n.whatsappOrderSize,
    quantity: l10n.whatsappOrderQuantity,
    free: l10n.cartFreeDelivery,
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: RawnqSpace.xl, bottom: RawnqSpace.md),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
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
                : theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
