import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:rtchat/components/chat_panel.dart';
import 'package:rtchat/components/sliver_pinnable_header.dart';
import 'package:rtchat/models/message.dart';

class PinnableMessageRenderViewport extends RenderViewport {
  double cumulativeOffset = 0.0;
  PinnableMessageRenderViewport({
    AxisDirection axisDirection = AxisDirection.down,
    required AxisDirection crossAxisDirection,
    required ViewportOffset offset,
    double anchor = 0.0,
    List<RenderSliver>? children,
    RenderSliver? center,
    double? cacheExtent,
    CacheExtentStyle cacheExtentStyle = CacheExtentStyle.pixel,
    Clip clipBehavior = Clip.hardEdge,
  }) : super(
          axisDirection: axisDirection,
          crossAxisDirection: crossAxisDirection,
          offset: offset,
          cacheExtent: cacheExtent,
          cacheExtentStyle: cacheExtentStyle,
          clipBehavior: clipBehavior,
        );

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
      if (child is RenderSliverPinnableHeader) {
        final offset =
            (child.parentData! as SliverPhysicalParentData).paintOffset;
        if (offset.dy == 0.0) {
          (child.parentData! as SliverPhysicalParentData).paintOffset =
              Offset(offset.dx, cumulativeOffset);
          cumulativeOffset -= child.geometry!.paintExtent * child.pinFraction;
          ;
        }
      }
      child = advance(child);
    }
    return result;
  }

  @override
  void updateChildLayoutOffset(RenderSliver child, double layoutOffset,
      GrowthDirection growthDirection) {
    final SliverPhysicalParentData childParentData =
        child.parentData! as SliverPhysicalParentData;
    childParentData.paintOffset =
        computeAbsolutePaintOffset(child, layoutOffset, growthDirection);
    if (child is RenderSliverPinnableHeader) {
      cumulativeOffset += child.geometry!.paintExtent * child.pinFraction;
    }
  }
}

class PinnableMessageScrollView extends ScrollView {
  final List<MessageModel> messages;

  const PinnableMessageScrollView({
    Key? key,
    Axis scrollDirection = Axis.vertical,
    bool reverse = false,
    ScrollController? controller,
    bool? primary,
    ScrollPhysics? physics,
    ScrollBehavior? scrollBehavior,
    bool shrinkWrap = false,
    Key? center,
    double anchor = 0.0,
    double? cacheExtent,
    required this.messages,
    int? semanticChildCount,
    DragStartBehavior dragStartBehavior = DragStartBehavior.start,
    ScrollViewKeyboardDismissBehavior keyboardDismissBehavior =
        ScrollViewKeyboardDismissBehavior.manual,
    String? restorationId,
    Clip clipBehavior = Clip.hardEdge,
  }) : super(
          key: key,
          scrollDirection: scrollDirection,
          reverse: reverse,
          controller: controller,
          primary: primary,
          physics: physics,
          scrollBehavior: scrollBehavior,
          shrinkWrap: shrinkWrap,
          center: center,
          anchor: anchor,
          cacheExtent: cacheExtent,
          semanticChildCount: semanticChildCount,
          dragStartBehavior: dragStartBehavior,
          keyboardDismissBehavior: keyboardDismissBehavior,
          restorationId: restorationId,
          clipBehavior: clipBehavior,
        );

  @override
  List<Widget> buildSlivers(BuildContext context) {
    final slivers = <Widget>[];
    for (var start = 0; start < messages.length;) {
      final nextPinnedIndex =
          messages.indexWhere((element) => element.pinned, start);
      final unpinned = nextPinnedIndex == -1
          ? messages.sublist(start)
          : messages.sublist(start, nextPinnedIndex);
      if (unpinned.isNotEmpty) {
        slivers.add(SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
          return ChatPanelMessageWidget(message: unpinned[index]);
        }, childCount: unpinned.length)));
      }
      if (nextPinnedIndex == -1) {
        break;
      } else {
        slivers.add(SliverPinnableHeader(
            pinFraction: messages[nextPinnedIndex].pinned ? 1.0 : 0.0,
            child: ChatPanelMessageWidget(message: messages[nextPinnedIndex])));
        start = nextPinnedIndex + 1;
      }
    }
    return slivers;
  }

  @override
  Widget buildViewport(
    BuildContext context,
    ViewportOffset offset,
    AxisDirection axisDirection,
    List<Widget> slivers,
  ) {
    assert(() {
      switch (axisDirection) {
        case AxisDirection.up:
        case AxisDirection.down:
          return debugCheckHasDirectionality(
            context,
            why: 'to determine the cross-axis direction of the scroll view',
            hint:
                'Vertical scroll views create Viewport widgets that try to determine their cross axis direction '
                'from the ambient Directionality.',
          );
        case AxisDirection.left:
        case AxisDirection.right:
          return true;
      }
    }());
    if (shrinkWrap) {
      return ShrinkWrappingViewport(
        axisDirection: axisDirection,
        offset: offset,
        slivers: slivers,
        clipBehavior: clipBehavior,
      );
    }
    return PinnableMessageViewport(
      axisDirection: axisDirection,
      offset: offset,
      slivers: slivers,
      cacheExtent: cacheExtent,
      center: center,
      anchor: anchor,
      clipBehavior: clipBehavior,
    );
  }
}

class PinnableMessageViewport extends Viewport {
  PinnableMessageViewport({
    Key? key,
    AxisDirection axisDirection = AxisDirection.down,
    AxisDirection? crossAxisDirection,
    double anchor = 0.0,
    required ViewportOffset offset,
    center,
    double? cacheExtent,
    CacheExtentStyle cacheExtentStyle = CacheExtentStyle.pixel,
    Clip clipBehavior = Clip.hardEdge,
    List<Widget> slivers = const <Widget>[],
  }) : super(
          key: key,
          axisDirection: axisDirection,
          crossAxisDirection: crossAxisDirection,
          anchor: anchor,
          offset: offset,
          center: center,
          cacheExtent: cacheExtent,
          cacheExtentStyle: cacheExtentStyle,
          clipBehavior: clipBehavior,
          slivers: slivers,
        );

  @override
  PinnableMessageRenderViewport createRenderObject(BuildContext context) {
    return PinnableMessageRenderViewport(
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
      BuildContext context, PinnableMessageRenderViewport renderObject) {
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
