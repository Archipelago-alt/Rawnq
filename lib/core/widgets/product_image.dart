import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';

/// Remote product photo with a warm placeholder and a graceful failure state.
///
/// Product photos are large square JPEGs on the shop's CDN, so they are
/// decoded down to the size they are actually painted at.
class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.semanticLabel,
    this.decodeWidth = 600,
  });

  final String? url;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final String? semanticLabel;

  /// Target decode width in logical pixels; scaled by device pixel ratio.
  final int decodeWidth;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(RawnqSpace.radiusMd);
    final source = url;

    final Widget image;
    if (source == null || source.isEmpty) {
      image = const _ImageFallback();
    } else {
      final ratio = MediaQuery.devicePixelRatioOf(context);
      image = CachedNetworkImage(
        imageUrl: source,
        fit: fit,
        memCacheWidth: (decodeWidth * ratio).round(),
        fadeInDuration: const Duration(milliseconds: 220),
        placeholder: (context, _) => const ColoredBox(color: RawnqColors.cream),
        errorWidget: (context, _, __) => const _ImageFallback(),
      );
    }

    return Semantics(
      label: semanticLabel,
      image: true,
      child: ClipRRect(borderRadius: radius, child: image),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  /// Below this, only the icon fits: category circles are 62px and brand
  /// logos 44px, and a caption there overflows the box.
  static const double _captionThreshold = 96;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ColoredBox(
      color: RawnqColors.cream,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact =
              constraints.maxHeight < _captionThreshold ||
              constraints.maxWidth < _captionThreshold;

          if (compact) {
            // The caption is dropped visually but kept for screen readers.
            return Semantics(
              label: l10n.stateImageUnavailable,
              child: const Center(
                child: Icon(
                  Icons.checkroom_outlined,
                  color: RawnqColors.inkSoft,
                  size: 20,
                ),
              ),
            );
          }

          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(
                  Icons.checkroom_outlined,
                  color: RawnqColors.inkSoft,
                  size: 28,
                ),
                const SizedBox(height: RawnqSpace.xs),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: RawnqSpace.sm,
                  ),
                  child: Text(
                    l10n.stateImageUnavailable,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: RawnqColors.inkSoft,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
