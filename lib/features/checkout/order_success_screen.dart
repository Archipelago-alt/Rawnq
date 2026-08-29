import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/utils/launcher.dart';
import '../../l10n/app_localizations.dart';

/// Confirmation shown after the order has been handed to the shop.
///
/// The wording is careful: the order was *sent*, and the shop confirms it —
/// the app has no way to know the shop accepted it.
class OrderSuccessScreen extends ConsumerWidget {
  const OrderSuccessScreen({super.key, required this.reference});

  final String reference;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final whatsapp = ref.watch(loadedCatalogProvider)?.store.whatsappDigits;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(RawnqSpace.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const _SuccessMark(),
                const SizedBox(height: RawnqSpace.xl),
                Text(
                  l10n.orderSuccessTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: RawnqSpace.md),
                Text(
                  l10n.orderSuccessBody,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: RawnqColors.inkSoft,
                  ),
                ),
                if (reference.isNotEmpty) ...<Widget>[
                  const SizedBox(height: RawnqSpace.xl),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: RawnqSpace.lg,
                      vertical: RawnqSpace.md,
                    ),
                    decoration: BoxDecoration(
                      color: RawnqColors.cream,
                      borderRadius: BorderRadius.circular(RawnqSpace.radiusMd),
                    ),
                    child: Text(
                      l10n.orderSuccessReference(reference),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
                const SizedBox(height: RawnqSpace.xxl),
                ElevatedButton(
                  onPressed: () => context.go(Routes.home),
                  child: Text(l10n.orderSuccessContinue),
                ),
                if (whatsapp != null) ...<Widget>[
                  const SizedBox(height: RawnqSpace.md),
                  OutlinedButton.icon(
                    onPressed: () =>
                        ExternalLauncher.open(Uri.https('wa.me', '/$whatsapp')),
                    icon: const Icon(Icons.chat_rounded, size: 20),
                    label: Text(l10n.orderSuccessContactUs),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated tick that plays once when the screen appears.
class _SuccessMark extends StatefulWidget {
  const _SuccessMark();

  @override
  State<_SuccessMark> createState() => _SuccessMarkState();
}

class _SuccessMarkState extends State<_SuccessMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
      child: Container(
        width: 104,
        height: 104,
        decoration: const BoxDecoration(
          color: RawnqColors.cream,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check_rounded,
          size: 52,
          color: RawnqColors.brown,
        ),
      ),
    );
  }
}
