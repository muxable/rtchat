import 'dart:math';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// [SliverPinnableHeader] keeps its child pinned to the leading edge of the viewport.
class SliverPinnableHeader extends SingleChildRenderObjectWidget {
  const SliverPinnableHeader({
    Key? key,
    required Widget child,
  }) : super(key: key, child: child);

  @override
  _RenderSliverPinnableHeader createRenderObject(BuildContext context) {
    return _RenderSliverPinnableHeader();
  }
}

class _RenderSliverPinnableHeader extends RenderSliverSingleBoxAdapter {
  @override
  void performLayout() {
    child!.layout(constraints.asBoxConstraints(), parentUsesSize: true);
    double childExtent;
    switch (constraints.axis) {
      case Axis.horizontal:
        childExtent = child!.size.width;
        break;
      case Axis.vertical:
        childExtent = child!.size.height;
        break;
    }
    final paintedChildExtent = min(
      childExtent,
      constraints.remainingPaintExtent - constraints.overlap,
    );
    geometry = SliverGeometry(
      paintExtent: paintedChildExtent,
      maxPaintExtent: childExtent,
      maxScrollObstructionExtent: childExtent,
      paintOrigin: constraints.overlap,
      scrollExtent: childExtent,
      layoutExtent: max(0.0, paintedChildExtent - constraints.scrollOffset),
      hasVisualOverflow: paintedChildExtent < childExtent,
    );
  }

  @override
  double childMainAxisPosition(RenderBox child) {
    return 0;
  }
}
