import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:rtchat/components/chat_history/sliver.dart';
import 'package:rtchat/components/pinnable/viewport.dart';

/// This is a total hack of a scrollview. Instead of the standard one-pass
/// render that [ScrollView] provides, this class instead performs a second
/// pass to detect [PinnableMessageSliver] slivers and renders them at the
/// correct location if they're pinned.
class PinnableMessageScrollView extends ScrollView {
  final TickerProvider vsync;
  final bool? Function(int) isPinnedBuilder;
  final Widget Function(int) itemBuilder;
  final int count;

  const PinnableMessageScrollView({
    Key? key,
    ScrollController? controller,
    required this.vsync,
    required this.isPinnedBuilder,
    required this.itemBuilder,
    required this.count,
  }) : super(
          key: key,
          reverse: true,
          controller: controller,
        );

  @override
  List<Widget> buildSlivers(BuildContext context) {
    final slivers = <Widget>[];
    // this is an optimization to improve pinning performance by skipping
    // messages that can't be pinned.
    for (var start = 0; start < count;) {
      final nextPinnableIndex =
          Iterable.generate(count - start, (value) => value + start).firstWhere(
              (index) => isPinnedBuilder(index) != null,
              orElse: () => count);
      final intermediateCount = nextPinnableIndex - start;
      if (intermediateCount > 0) {
        final offset = start;
        final sliver = SliverList(
            delegate: SliverChildBuilderDelegate(
                (context, index) => itemBuilder(index + offset),
                childCount: intermediateCount));
        slivers.add(sliver);
      }
      if (nextPinnableIndex == count) {
        break;
      }
      final pinned = isPinnedBuilder(nextPinnableIndex)!;
      final sliver = PinnableMessageSliver(
        vsync: vsync,
        pinned: pinned,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          color: pinned ? Colors.grey[900] : Colors.transparent,
          child: itemBuilder(nextPinnableIndex),
        ),
      );
      slivers.add(sliver);
      start = nextPinnableIndex + 1;
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
