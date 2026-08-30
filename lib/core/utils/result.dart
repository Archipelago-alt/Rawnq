/// The failure modes the UI actually distinguishes between.
enum FailureKind { offline, timeout, server, notFound, unknown }

/// A user-facing failure. The message key is resolved by the presentation
/// layer against the localisations, so no display strings live in here.
class Failure implements Exception {
  const Failure(this.kind, {this.detail});

  final FailureKind kind;

  /// Technical detail for logs only. Never contains personal data.
  final String? detail;

  @override
  String toString() => 'Failure($kind${detail == null ? '' : ': $detail'})';
}
