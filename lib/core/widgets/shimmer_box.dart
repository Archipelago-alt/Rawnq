import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// A shimmering placeholder block used to build loading skeletons.
///
/// One animation controller drives every child through a shader, so a screen
/// full of skeletons still animates from a single ticker.
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
  });

  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final BoxShape shape;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: RawnqColors.creamDeep,
        shape: shape,
        borderRadius: shape == BoxShape.circle
            ? null
            : borderRadius ?? BorderRadius.circular(RawnqSpace.radiusSm),
      ),
    );
  }
}

/// Wraps a skeleton subtree in a moving highlight.
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child, this.enabled = true});

  final Widget child;
  final bool enabled;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final slide = _controller.value * 2 - 1;
            return LinearGradient(
              begin: Alignment(-1 + slide, -0.3),
              end: Alignment(1 + slide, 0.3),
              colors: const <Color>[
                RawnqColors.creamDeep,
                Color(0xFFF8F1E8),
                RawnqColors.creamDeep,
              ],
              stops: const <double>[0.1, 0.5, 0.9],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: ExcludeSemantics(child: widget.child),
    );
  }
}
