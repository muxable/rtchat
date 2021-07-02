import 'dart:math';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class SliverPinnableHeader extends SingleChildRenderObjectWidget {
  final double pinFraction;

  const SliverPinnableHeader({
    Key? key,
    required this.pinFraction,
    required Widget child,
  }) : super(key: key, child: child);

  @override
  RenderSliverPinnableHeader createRenderObject(BuildContext context) {
    return RenderSliverPinnableHeader(pinFraction: pinFraction);
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderSliverPinnableHeader renderObject) {
    renderObject.pinFraction = pinFraction;
  }
}

class RenderSliverPinnableHeader extends RenderSliverToBoxAdapter {
  double _pinFraction;

  RenderSliverPinnableHeader({required double pinFraction, RenderBox? child})
      : _pinFraction = pinFraction,
        super(child: child);

  double get pinFraction => _pinFraction;

  set pinFraction(double value) {
    _pinFraction = value;
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  @override
  void performLayout() {
    super.performLayout();

    geometry = SliverGeometry(
      scrollExtent: geometry!.scrollExtent,
      paintExtent: geometry!.paintExtent,
      cacheExtent: geometry!.cacheExtent,
      maxPaintExtent: geometry!.maxPaintExtent,
      hitTestExtent: geometry!.hitTestExtent,
      hasVisualOverflow: geometry!.hasVisualOverflow,
      visible: true,
    );
  }
}
