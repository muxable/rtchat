import 'dart:math';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class SliverPinnableHeader extends SingleChildRenderObjectWidget {
  const SliverPinnableHeader({
    Key? key,
    required Widget child,
  }) : super(key: key, child: child);

  @override
  RenderSliverPinnableHeader createRenderObject(BuildContext context) {
    return RenderSliverPinnableHeader();
  }
}

class RenderSliverPinnableHeader extends RenderSliverSingleBoxAdapter {
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
    final layoutExtent =
        max(0.0, paintedChildExtent - constraints.scrollOffset);
    final paintOrigin =
        constraints.overlap + (layoutExtent - paintedChildExtent);
    geometry = SliverGeometry(
      visible: true,
      paintExtent: paintedChildExtent,
      maxPaintExtent: childExtent,
      maxScrollObstructionExtent: childExtent,
      paintOrigin: paintOrigin,
      scrollExtent: childExtent,
      layoutExtent: layoutExtent,
      hasVisualOverflow: paintedChildExtent < childExtent,
    );
  }

  @override
  double childMainAxisPosition(RenderBox child) {
    return 0;
  }
}
