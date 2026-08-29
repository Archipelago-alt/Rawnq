import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../shared/models/product.dart';

/// Colour swatches. The live variants carry an exact `color_hex`, so real
/// swatches are shown rather than translated colour names.
class ColorSelector extends StatelessWidget {
  const ColorSelector({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    required this.isAvailable,
  });

  final List<ProductVariant> options;
  final String? selected;
  final ValueChanged<String> onSelected;

  /// Whether any variant of this colour is in stock.
  final bool Function(String color) isAvailable;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: RawnqSpace.md,
      runSpacing: RawnqSpace.md,
      children: <Widget>[
        for (final option in options)
          if ((option.color ?? '').isNotEmpty)
            _Swatch(
              label: option.color!,
              color: option.swatch,
              selected: option.color == selected,
              available: isAvailable(option.color!),
              onTap: () => onSelected(option.color!),
            ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.label,
    required this.color,
    required this.selected,
    required this.available,
    required this.onTap,
  });

  final String label;
  final Color? color;
  final bool selected;
  final bool available;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // A swatch alone is not accessible, so the colour name rides along as the
    // semantic label and as visible text under the chip.
    return Semantics(
      button: true,
      selected: selected,
      enabled: available,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(RawnqSpace.radiusSm),
        child: Opacity(
          opacity: available ? 1 : 0.4,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color ?? RawnqColors.cream,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? RawnqColors.brown : RawnqColors.line,
                    width: selected ? 3 : 1,
                  ),
                ),
                child: color == null
                    ? const Icon(Icons.palette_outlined, size: 18, color: RawnqColors.inkSoft)
                    : null,
              ),
              const SizedBox(height: RawnqSpace.xs),
              SizedBox(
                width: 64,
                child: Text(
                  label,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                    color: selected ? RawnqColors.brown : RawnqColors.inkSoft,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Size chips. Sizes on the live data range from `S` to `XXXXL` plus
/// `One Size` and `Big Size`.
class SizeSelector extends StatelessWidget {
  const SizeSelector({
    super.key,
    required this.sizes,
    required this.selected,
    required this.onSelected,
    required this.isAvailable,
  });

  final List<String> sizes;
  final String? selected;
  final ValueChanged<String> onSelected;
  final bool Function(String size) isAvailable;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: RawnqSpace.sm,
      runSpacing: RawnqSpace.sm,
      children: <Widget>[
        for (final size in sizes)
          _SizeChip(
            label: size,
            selected: size == selected,
            available: isAvailable(size),
            onTap: () => onSelected(size),
          ),
      ],
    );
  }
}

class _SizeChip extends StatelessWidget {
  const _SizeChip({
    required this.label,
    required this.selected,
    required this.available,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool available;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      enabled: available,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(RawnqSpace.radiusSm),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          constraints: const BoxConstraints(minWidth: 54, minHeight: 44),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: RawnqSpace.md),
          decoration: BoxDecoration(
            color: selected ? RawnqColors.brown : RawnqColors.surface,
            borderRadius: BorderRadius.circular(RawnqSpace.radiusSm),
            border: Border.all(
              color: selected ? RawnqColors.brown : RawnqColors.line,
              width: selected ? 2 : 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected
                  ? Colors.white
                  : (available ? RawnqColors.ink : RawnqColors.inkSoft),
              decoration: available ? null : TextDecoration.lineThrough,
            ),
          ),
        ),
      ),
    );
  }
}
