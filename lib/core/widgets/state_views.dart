import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';
import '../utils/result.dart';

/// Full-screen error state with a retry action.
class ErrorStateView extends StatelessWidget {
  const ErrorStateView({super.key, required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final failure = error;
    final kind = failure is Failure ? failure.kind : FailureKind.unknown;

    final ({IconData icon, String title, String? hint}) view = switch (kind) {
      FailureKind.offline => (
          icon: Icons.wifi_off_rounded,
          title: l10n.stateErrorOffline,
          hint: l10n.stateErrorOfflineHint,
        ),
      FailureKind.timeout => (
          icon: Icons.timer_off_outlined,
          title: l10n.stateErrorTimeout,
          hint: null,
        ),
      FailureKind.server || FailureKind.notFound => (
          icon: Icons.storefront_outlined,
          title: l10n.stateErrorServer,
          hint: null,
        ),
      FailureKind.unknown => (
          icon: Icons.error_outline_rounded,
          title: l10n.stateErrorGeneric,
          hint: null,
        ),
    };

    return _CenteredMessage(
      icon: view.icon,
      title: view.title,
      body: view.hint,
      action: onRetry == null
          ? null
          : OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.stateRetry),
            ),
    );
  }
}

/// Empty-list state — no data, but nothing went wrong.
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? body;
  final Widget? action;

  @override
  Widget build(BuildContext context) =>
      _CenteredMessage(icon: icon, title: title, body: body, action: action);
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({
    required this.icon,
    required this.title,
    this.body,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(RawnqSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(color: RawnqColors.cream, shape: BoxShape.circle),
              child: Icon(icon, size: 38, color: RawnqColors.brown),
            ),
            const SizedBox(height: RawnqSpace.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            if (body != null) ...<Widget>[
              const SizedBox(height: RawnqSpace.sm),
              Text(
                body!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (action != null) ...<Widget>[
              const SizedBox(height: RawnqSpace.xl),
              SizedBox(width: 220, child: action),
            ],
          ],
        ),
      ),
    );
  }
}

/// A slim banner pinned under the app bar, used for the offline and
/// local-data notices.
class NoticeBanner extends StatelessWidget {
  const NoticeBanner({
    super.key,
    required this.icon,
    required this.message,
    this.background = RawnqColors.creamDeep,
    this.foreground = RawnqColors.brownDark,
  });

  final IconData icon;
  final String message;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        color: background,
        padding: const EdgeInsets.symmetric(
          horizontal: RawnqSpace.lg,
          vertical: RawnqSpace.sm,
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 16, color: foreground),
            const SizedBox(width: RawnqSpace.sm),
            Expanded(
              child: Text(
                message,
                style: TextStyle(fontSize: 12, color: foreground, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
