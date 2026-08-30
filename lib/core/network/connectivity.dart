import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the device currently has a network interface.
///
/// This reports reachability of an interface, not of the storefront, so it is
/// used only to warn the shopper — request failures are still surfaced through
/// [Failure] so a captive portal or a dead server is not mistaken for being
/// online. Errors here (for example, no platform implementation under test)
/// leave the value null, and the UI simply shows no banner.
final connectivityProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  try {
    yield _isOnline(await connectivity.checkConnectivity());
  } on Exception {
    // No platform implementation (widget tests, unsupported host). Leaving the
    // stream empty keeps the value unknown rather than raising an error the
    // caller would have to handle.
    return;
  }
  yield* connectivity.onConnectivityChanged
      .map(_isOnline)
      .handleError((Object _) {});
});

/// True when at least one interface is up.
bool _isOnline(List<ConnectivityResult> results) =>
    results.isNotEmpty &&
    results.any((result) => result != ConnectivityResult.none);

/// Null while unknown, so callers can distinguish "offline" from "not yet
/// determined" and avoid flashing a banner on start-up.
final isOfflineProvider = Provider<bool>(
  (ref) => ref.watch(connectivityProvider).asData?.value == false,
);
