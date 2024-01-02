import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:rtchat/components/chat_history/sliver.dart';

class PinnableMessageViewport extends Viewport {
  PinnableMessageViewport({
    super.key,
    super.axisDirection,
    super.crossAxisDirection,
    super.anchor,
    required super.offset,
    center,
    super.cacheExtent,
    super.cacheExtentStyle,
    super.clipBehavior,
    super.slivers,
  }) : super(
          center: center,
        );

  @override
  RenderPinnableMessageViewport createRenderObject(BuildContext context) {
    return RenderPinnableMessageViewport(
      axisDirection: axisDirection,
      crossAxisDirection: crossAxisDirection ??
          Viewport.getDefaultCrossAxisDirection(context, axisDirection),
      anchor: anchor,
      offset: offset,
      cacheExtent: cacheExtent,
      cacheExtentStyle: cacheExtentStyle,
      clipBehavior: clipBehavior,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderPinnableMessageViewport renderObject) {
    renderObject
      ..axisDirection = axisDirection
      ..crossAxisDirection = crossAxisDirection ??
          Viewport.getDefaultCrossAxisDirection(context, axisDirection)
      ..anchor = anchor
      ..offset = offset
      ..cacheExtent = cacheExtent
      ..cacheExtentStyle = cacheExtentStyle
      ..clipBehavior = clipBehavior;
  }
}

class RenderPinnableMessageViewport extends RenderViewport {
  double cumulativeOffset = 0.0;

  RenderPinnableMessageViewport({
    super.axisDirection,
    required super.crossAxisDirection,
    required super.offset,
    double anchor = 0.0,
    super.cacheExtent,
    super.cacheExtentStyle,
    super.clipBehavior,
  });

  @override
  double layoutChildSequence({
    required RenderSliver? child,
    required double scrollOffset,
    required double overlap,
    required double layoutOffset,
    required double remainingPaintExtent,
    required double mainAxisExtent,
    required double crossAxisExtent,
    required GrowthDirection growthDirection,
    required RenderSliver? Function(RenderSliver child) advance,
    required double remainingCacheExtent,
    required double cacheOrigin,
  }) {
    cumulativeOffset = 0.0;
    final result = super.layoutChildSequence(
        child: child,
        scrollOffset: scrollOffset,
        overlap: overlap,
        layoutOffset: layoutOffset,
        remainingPaintExtent: remainingPaintExtent,
        mainAxisExtent: mainAxisExtent,
        crossAxisExtent: crossAxisExtent,
        growthDirection: growthDirection,
        advance: advance,
        remainingCacheExtent: remainingCacheExtent,
        cacheOrigin: cacheOrigin);
    // progress through the children and pin the children.
    while (child != null) {
      if (child is RenderPinnableMessageSliver) {
        final offset =
            (child.parentData! as SliverPhysicalParentData).paintOffset;

        (child.parentData! as SliverPhysicalParentData).paintOffset = Offset(
            offset.dx,
            math.max(
                offset.dy, cumulativeOffset - child.geometry!.paintExtent));
        cumulativeOffset -= child.geometry!.maxPaintExtent * child.pinFraction;
      }
      child = advance(child);
    }
    return result;
  }

  @override
  void updateChildLayoutOffset(RenderSliver child, double layoutOffset,
      GrowthDirection growthDirection) {
    super.updateChildLayoutOffset(child, layoutOffset, growthDirection);

    if (child is RenderPinnableMessageSliver) {
      cumulativeOffset += child.geometry!.maxPaintExtent * child.pinFraction;
    }
  }

  @override
  Iterable<RenderSliver> get childrenInPaintOrder sync* {
    yield* getMessageSlivers(false);
    yield* getMessageSlivers(true);
  }

  @override
  Iterable<RenderSliver> get childrenInHitTestOrder sync* {
    yield* getMessageSlivers(true);
    yield* getMessageSlivers(false);
  }

  Iterable<RenderSliver> getMessageSlivers(bool pinnable) sync* {
    if (firstChild == null) {
      return;
    }
    for (var child = firstChild; child != null; child = childAfter(child)) {
      if ((child is RenderPinnableMessageSliver) == pinnable) {
        yield child;
      }
    }
  }
}
