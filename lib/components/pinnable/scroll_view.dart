import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:rtchat/components/chat_history/sliver.dart';
import 'package:rtchat/components/pinnable/viewport.dart';

enum PinState {
  notPinnable,
  pinned,
  unpinned,
}

/// This is a total hack of a scrollview. Instead of the standard one-pass
/// render that [ScrollView] provides, this class instead performs a second
/// pass to detect [PinnableMessageSliver] slivers and renders them at the
/// correct location if they're pinned.
class PinnableMessageScrollView extends ScrollView {
  final TickerProvider vsync;
  final PinState Function(int) isPinnedBuilder;
  final Widget Function(int) itemBuilder;
  final ChildIndexGetter findChildIndexCallback;
  final int count;

  const PinnableMessageScrollView({
    Key? key,
    ScrollController? controller,
    required this.vsync,
    required this.isPinnedBuilder,
    required this.itemBuilder,
    required this.findChildIndexCallback,
    required this.count,
  }) : super(
          key: key,
          reverse: true,
          controller: controller,
        );

  @override
  List<Widget> buildSlivers(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final pinnedSliverColor =
        brightness == Brightness.dark ? Colors.grey[900] : Colors.grey[300];
    final slivers = <Widget>[];
    // this is an optimization to improve pinning performance by skipping
    // messages that can't be pinned.
    for (var start = 0; start < count;) {
      final nextPinnableIndex =
          Iterable.generate(count - start, (value) => value + start).firstWhere(
              (index) => isPinnedBuilder(index) != PinState.notPinnable,
              orElse: () => count);
      final intermediateCount = nextPinnableIndex - start;
      // key from the distance to the end of the list, which is the most stable identifier.
      if (intermediateCount > 0) {
        final offset = start;
        final sliver = SliverList(
          key: ValueKey(count - nextPinnableIndex + 1),
          delegate: SliverChildBuilderDelegate(
            (context, index) => itemBuilder(index + offset),
            findChildIndexCallback: (key) {
              final index = findChildIndexCallback(key);
              return index == null || index == -1 ? null : index - offset;
            },
            childCount: intermediateCount,
            semanticIndexOffset: offset,
          ),
        );
        slivers.add(sliver);
      }
      if (nextPinnableIndex == count) {
        break;
      }
      final pinned = isPinnedBuilder(nextPinnableIndex);
      final sliver = PinnableMessageSliver(
        key: ValueKey(count - nextPinnableIndex),
        vsync: vsync,
        pinned: pinned == PinState.pinned,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          color: pinned == PinState.pinned
              ? pinnedSliverColor
              : Colors.transparent,
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
