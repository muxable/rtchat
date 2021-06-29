import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/twitch/message.dart';
import 'package:rtchat/components/twitch/raid_event.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/chat_history.dart';
import 'package:rtchat/models/message.dart';
import 'package:rtchat/models/user.dart';

class _SliverPersistentFooterElement extends RenderObjectElement {
  _SliverPersistentFooterElement(
      _SliverPersistentFooterRenderObjectWidget widget)
      : super(widget);

  @override
  _SliverPersistentFooterRenderObjectWidget get widget =>
      super.widget as _SliverPersistentFooterRenderObjectWidget;

  @override
  _RenderSliverPersistentFooterForWidgetsMixin get renderObject =>
      super.renderObject as _RenderSliverPersistentFooterForWidgetsMixin;

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);
    renderObject._element = this;
  }

  @override
  void unmount() {
    super.unmount();
    renderObject._element = null;
  }

  @override
  void update(_SliverPersistentFooterRenderObjectWidget newWidget) {
    final _SliverPersistentFooterRenderObjectWidget oldWidget = widget;
    super.update(newWidget);
    final SliverPersistentHeaderDelegate newDelegate = newWidget.delegate;
    final SliverPersistentHeaderDelegate oldDelegate = oldWidget.delegate;
    if (newDelegate != oldDelegate &&
        (newDelegate.runtimeType != oldDelegate.runtimeType ||
            newDelegate.shouldRebuild(oldDelegate))) {
      renderObject.triggerRebuild();
    }
  }

  @override
  void performRebuild() {
    super.performRebuild();
    renderObject.triggerRebuild();
  }

  Element? child;

  void _build(double shrinkOffset, bool overlapsContent) {
    owner!.buildScope(this, () {
      child = updateChild(
        child,
        widget.delegate.build(
          this,
          shrinkOffset,
          overlapsContent,
        ),
        null,
      );
    });
  }

  @override
  void forgetChild(Element child) {
    assert(child == this.child);
    this.child = null;
    super.forgetChild(child);
  }

  @override
  void insertRenderObjectChild(covariant RenderBox child, Object? slot) {
    assert(renderObject.debugValidateChild(child));
    renderObject.child = child;
  }

  @override
  void moveRenderObjectChild(
      covariant RenderObject child, Object? oldSlot, Object? newSlot) {
    assert(false);
  }

  @override
  void removeRenderObjectChild(covariant RenderObject child, Object? slot) {
    renderObject.child = null;
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    if (child != null) visitor(child!);
  }
}

abstract class _SliverPersistentFooterRenderObjectWidget
    extends RenderObjectWidget {
  const _SliverPersistentFooterRenderObjectWidget({
    Key? key,
    required this.delegate,
  })  : assert(delegate != null),
        super(key: key);

  final SliverPersistentHeaderDelegate delegate;

  @override
  _SliverPersistentFooterElement createElement() =>
      _SliverPersistentFooterElement(this);

  @override
  _RenderSliverPersistentFooterForWidgetsMixin createRenderObject(
      BuildContext context);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(
      DiagnosticsProperty<SliverPersistentHeaderDelegate>(
        'delegate',
        delegate,
      ),
    );
  }
}

mixin _RenderSliverPersistentFooterForWidgetsMixin
    on RenderSliverPersistentHeader {
  _SliverPersistentFooterElement? _element;

  @override
  double get minExtent => _element!.widget.delegate.minExtent;

  @override
  double get maxExtent => _element!.widget.delegate.maxExtent;

  @override
  void updateChild(double shrinkOffset, bool overlapsContent) {
    assert(_element != null);
    _element!._build(shrinkOffset, overlapsContent);
  }

  @protected
  void triggerRebuild() {
    markNeedsLayout();
  }
}

Rect? _trim(
  Rect? original, {
  double top = -double.infinity,
  double right = double.infinity,
  double bottom = double.infinity,
  double left = -double.infinity,
}) =>
    original?.intersect(Rect.fromLTRB(left, top, right, bottom));

abstract class RenderSliverPinnedPersistentFooter
    extends RenderSliverPersistentHeader {
  RenderSliverPinnedPersistentFooter({
    RenderBox? child,
    OverScrollHeaderStretchConfiguration? stretchConfiguration,
    this.showOnScreenConfiguration =
        const PersistentHeaderShowOnScreenConfiguration(),
  }) : super(
          child: child,
          stretchConfiguration: stretchConfiguration,
        );

  PersistentHeaderShowOnScreenConfiguration? showOnScreenConfiguration;

  @override
  void performLayout() {
    final SliverConstraints constraints = this.constraints;
    final double maxExtent = this.maxExtent;
    final bool overlapsContent = constraints.overlap > 0.0;
    layoutChild(constraints.scrollOffset, maxExtent,
        overlapsContent: overlapsContent);
    final double effectiveRemainingPaintExtent =
        max(0, constraints.remainingPaintExtent - constraints.overlap);
    final double layoutExtent = (maxExtent - constraints.scrollOffset)
        .clamp(0.0, effectiveRemainingPaintExtent);
    final double stretchOffset =
        stretchConfiguration != null ? constraints.overlap.abs() : 0.0;
    geometry = SliverGeometry(
      scrollExtent: maxExtent,
      paintOrigin: constraints.overlap,
      paintExtent: min(childExtent, effectiveRemainingPaintExtent),
      layoutExtent: layoutExtent,
      maxPaintExtent: maxExtent + stretchOffset,
      maxScrollObstructionExtent: minExtent,
      cacheExtent: layoutExtent > 0.0
          ? -constraints.cacheOrigin + layoutExtent
          : layoutExtent,
      hasVisualOverflow:
          true, // Conservatively say we do have overflow to avoid complexity.
    );
  }

  @override
  double childMainAxisPosition(RenderBox child) => 0.0;

  @override
  void showOnScreen({
    RenderObject? descendant,
    Rect? rect,
    Duration duration = Duration.zero,
    Curve curve = Curves.ease,
  }) {
    final Rect? localBounds = descendant != null
        ? MatrixUtils.transformRect(
            descendant.getTransformTo(this), rect ?? descendant.paintBounds)
        : rect;

    Rect? newRect;
    switch (applyGrowthDirectionToAxisDirection(
        constraints.axisDirection, constraints.growthDirection)) {
      case AxisDirection.up:
        newRect = _trim(localBounds, top: childExtent);
        break;
      case AxisDirection.right:
        newRect = _trim(localBounds, left: 0);
        break;
      case AxisDirection.down:
        newRect = _trim(localBounds, top: 0);
        break;
      case AxisDirection.left:
        newRect = _trim(localBounds, right: childExtent);
        break;
    }

    super.showOnScreen(
      descendant: this,
      rect: newRect,
      duration: duration,
      curve: curve,
    );
  }
}

class _RenderSliverPinnedPersistentFooterForWidgets
    extends RenderSliverPinnedPersistentHeader
    with _RenderSliverPersistentFooterForWidgetsMixin {
  _RenderSliverPinnedPersistentFooterForWidgets({
    RenderBox? child,
    OverScrollHeaderStretchConfiguration? stretchConfiguration,
    PersistentHeaderShowOnScreenConfiguration? showOnScreenConfiguration,
  }) : super(
          child: child,
          stretchConfiguration: stretchConfiguration,
          showOnScreenConfiguration: showOnScreenConfiguration,
        );
}

class _SliverPinnedPersistentFooter
    extends _SliverPersistentFooterRenderObjectWidget {
  const _SliverPinnedPersistentFooter({
    Key? key,
    required SliverPersistentHeaderDelegate delegate,
  }) : super(
          key: key,
          delegate: delegate,
        );

  @override
  _RenderSliverPersistentFooterForWidgetsMixin createRenderObject(
      BuildContext context) {
    return _RenderSliverPinnedPersistentFooterForWidgets(
      stretchConfiguration: delegate.stretchConfiguration,
      showOnScreenConfiguration: delegate.showOnScreenConfiguration,
    );
  }
}

class PinnableDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  PinnableDelegate(this.child);

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => 38;

  @override
  double get minExtent => 38;

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}

class ChatPanelWidget extends StatefulWidget {
  final void Function(bool)? onScrollback;

  const ChatPanelWidget({Key? key, this.onScrollback}) : super(key: key);

  @override
  _ChatPanelWidgetState createState() => _ChatPanelWidgetState();
}

class _ChatPanelWidgetState extends State<ChatPanelWidget> {
  final _controller = ScrollController();
  var _atBottom = true;

  @override
  void initState() {
    super.initState();

    _controller.addListener(() {
      final value =
          _controller.position.atEdge && _controller.position.pixels == 0;
      if (_atBottom != value) {
        setState(() {
          _atBottom = value;
        });
        if (widget.onScrollback != null) {
          widget.onScrollback!(!_atBottom);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Consumer<ChatHistoryModel>(builder: (context, model, child) {
        final messages = model.messages.reversed.toList();
        // construct slivers out of message chunks, using pinnable events as
        // delimiters.
        final slivers = <Widget>[];
        for (var i = 0; i < messages.length;) {
          final j = messages.indexWhere(
              (element) => element is PinnableMessageModel, i);
          final slice = (j > -1 ? messages.sublist(i, j) : messages.sublist(i));
          if (slice.isNotEmpty) {
            slivers.add(SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
              return ChatPanelMessageWidget(message: slice[index]);
            }, childCount: slice.length)));
          }
          if (j > -1) {
            slivers.add(_SliverPinnedPersistentFooter(
                delegate: PinnableDelegate(
                    ChatPanelMessageWidget(message: messages[j]))));
            i = j + 1;
          } else {
            break;
          }
        }
        return CustomScrollView(
          controller: _controller,
          reverse: true,
          slivers: slivers,
        );
      }),
      Builder(builder: (context) {
        if (_atBottom) {
          return Container();
        }
        return Container(
          alignment: Alignment.bottomCenter,
          child: TextButton(
              onPressed: () {
                _controller.animateTo(0,
                    duration: Duration(milliseconds: 200),
                    curve: Curves.easeInOut);
              },
              style: ButtonStyle(
                backgroundColor:
                    MaterialStateProperty.all(Colors.black.withOpacity(0.6)),
                padding: MaterialStateProperty.all(
                    const EdgeInsets.only(left: 16, right: 16)),
              ),
              child: Text("Scroll to bottom")),
        );
      }),
    ]);
  }
}

class ChatPanelMessageWidget extends StatelessWidget {
  final MessageModel message;

  ChatPanelMessageWidget({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final m = message;
    if (m is TwitchMessageModel) {
      var coalesce = false;
      // the history is forward.
      // if (index + 1 < messages.length) {
      //   final prev = messages[index + 1];
      //   coalesce = prev is TwitchMessageModel && prev.author == message.author;
      // }
      return InkWell(
          onLongPress: () {
            showDialog(
                context: context,
                builder: (context) {
                  return Dialog(
                    child: ListView(shrinkWrap: true, children: [
                      ListTile(
                          title: Text('Delete Message'),
                          onTap: () {
                            final userModel =
                                Provider.of<UserModel>(context, listen: false);
                            final channelsModel = Provider.of<ChannelsModel>(
                                context,
                                listen: false);
                            userModel.delete(
                                channelsModel.channels.first, m.messageId);
                            Navigator.pop(context);
                          }),
                      ListTile(
                          title: Text('Timeout ${m.author}'), onTap: () {}),
                      ListTile(title: Text('Ban ${m.author}'), onTap: () {}),
                      ListTile(
                          title: Text('Unban ${m.author}'),
                          onTap: () {
                            final userModel =
                                Provider.of<UserModel>(context, listen: false);
                            final channelsModel = Provider.of<ChannelsModel>(
                                context,
                                listen: false);
                            userModel.unban(
                                channelsModel.channels.first, m.author);
                            Navigator.pop(context);
                          }),
                    ]),
                  );
                });
          },
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: TwitchMessageWidget(m, coalesce: coalesce),
          ));
    } else if (m is TwitchRaidEventModel) {
      return TwitchRaidEventWidget(m);
    } else {
      throw new AssertionError("invalid message type");
    }
  }
}
