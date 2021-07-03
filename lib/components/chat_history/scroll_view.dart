import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:rtchat/components/chat_history/message.dart';
import 'package:rtchat/components/chat_history/sliver.dart';
import 'package:rtchat/components/chat_history/viewport.dart';
import 'package:rtchat/models/message.dart';

/// This is a total hack of a scrollview. Instead of the standard one-pass
/// render that [ScrollView] provides, this class instead performs a second
/// pass to detect [PinnableMessageSliver] slivers and renders them at the
/// correct location if they're pinned.
class PinnableMessageScrollView extends StatefulWidget {
  final ScrollController? controller;
  final List<MessageModel> messages;

  const PinnableMessageScrollView(
      {Key? key, this.controller, required this.messages})
      : super(key: key);

  @override
  _PinnableMessageScrollViewState createState() =>
      _PinnableMessageScrollViewState();
}

class _PinnableMessageScrollViewState extends State<PinnableMessageScrollView>
    with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return _PinnableMessageScrollView(vsync: this, messages: widget.messages);
  }
}

class _PinnableMessageScrollView extends ScrollView {
  final TickerProvider vsync;
  final List<MessageModel> messages;

  const _PinnableMessageScrollView({
    Key? key,
    ScrollController? controller,
    required this.vsync,
    required this.messages,
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
    for (var start = 0; start < messages.length;) {
      final nextPinnedIndex = messages.indexWhere(
          (element) => element is PinnableMessageModel, start);
      final unpinned = nextPinnedIndex == -1
          ? messages.sublist(start)
          : messages.sublist(start, nextPinnedIndex);
      if (unpinned.isNotEmpty) {
        slivers.add(SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
          return ChatHistoryMessage(message: unpinned[index]);
        }, childCount: unpinned.length)));
      }
      if (nextPinnedIndex == -1) {
        break;
      } else {
        final pinned = messages[nextPinnedIndex].pinned;
        slivers.add(PinnableMessageSliver(
            vsync: vsync,
            pinned: pinned,
            child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                color: pinned
                    ? Theme.of(context).primaryColor
                    : Colors.transparent,
                child:
                    ChatHistoryMessage(message: messages[nextPinnedIndex]))));
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
