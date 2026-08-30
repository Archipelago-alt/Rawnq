import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../app/theme.dart';
import '../../core/config/app_config.dart';
import '../../l10n/app_localizations.dart';

/// Opens the shop's own checkout inside a WebView.
///
/// The app deliberately does not create orders through the platform's API, so
/// this is how a shopper completes a real web order. Navigation is pinned to
/// the storefront's host — a link that tries to leave it is refused rather
/// than silently followed inside the app frame.
class WebCheckoutScreen extends StatefulWidget {
  const WebCheckoutScreen({super.key, this.initialUrl});

  final Uri? initialUrl;

  @override
  State<WebCheckoutScreen> createState() => _WebCheckoutScreenState();
}

class _WebCheckoutScreenState extends State<WebCheckoutScreen> {
  late final Uri _target = widget.initialUrl ?? StorefrontLinks.storefrontCart;
  late final WebViewController _controller;
  int _progress = 0;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(RawnqColors.sand)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (value) {
            if (mounted) setState(() => _progress = value);
          },
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            final allowed =
                uri != null &&
                uri.isScheme('https') &&
                uri.host == _target.host;
            return allowed
                ? NavigationDecision.navigate
                : NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(_target);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.checkoutOpenWebsite),
        bottom: _progress >= 100
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(
                  value: _progress / 100,
                  minHeight: 2,
                  backgroundColor: RawnqColors.cream,
                ),
              ),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
