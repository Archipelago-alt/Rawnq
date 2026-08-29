import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/product_image.dart';
import '../../../l10n/app_localizations.dart';

/// Swipeable product image gallery with a page indicator and a counter.
///
/// Live products carry between one and six photos, so the indicator adapts
/// rather than assuming a fixed count.
class ProductGallery extends StatefulWidget {
  const ProductGallery({
    super.key,
    required this.images,
    required this.semanticLabel,
    this.selectedIndex = 0,
  });

  final List<String> images;
  final String semanticLabel;

  /// External selection, e.g. after the shopper picks a colour.
  final int selectedIndex;

  @override
  State<ProductGallery> createState() => _ProductGalleryState();
}

class _ProductGalleryState extends State<ProductGallery> {
  late final PageController _controller = PageController(initialPage: widget.selectedIndex);
  late int _index = widget.selectedIndex;

  @override
  void didUpdateWidget(ProductGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != oldWidget.selectedIndex && _controller.hasClients) {
      _controller.animateToPage(
        widget.selectedIndex,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final images = widget.images;

    if (images.isEmpty) {
      return AspectRatio(
        aspectRatio: 1,
        child: ProductImage(
          url: null,
          borderRadius: BorderRadius.zero,
          semanticLabel: widget.semanticLabel,
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        children: <Widget>[
          PageView.builder(
            controller: _controller,
            itemCount: images.length,
            onPageChanged: (value) => setState(() => _index = value),
            itemBuilder: (context, index) => ProductImage(
              url: images[index],
              decodeWidth: 900,
              borderRadius: BorderRadius.zero,
              semanticLabel: widget.semanticLabel,
            ),
          ),
          if (images.length > 1)
            PositionedDirectional(
              bottom: RawnqSpace.md,
              start: 0,
              end: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  for (var i = 0; i < images.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _index ? 20 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: i == _index ? RawnqColors.brown : Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: RawnqColors.line),
                      ),
                    ),
                ],
              ),
            ),
          if (images.length > 1)
            PositionedDirectional(
              top: RawnqSpace.md,
              end: RawnqSpace.md,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: RawnqSpace.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(RawnqSpace.radiusSm),
                ),
                child: Text(
                  l10n.productImageCounter(_index + 1, images.length),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
