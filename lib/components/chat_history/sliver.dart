import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class PinnableMessageSliver extends SingleChildRenderObjectWidget {
  final bool pinned;
  final TickerProvider vsync;

  const PinnableMessageSliver({
    Key? key,
    required this.vsync,
    required this.pinned,
    required Widget child,
  }) : super(key: key, child: child);

  @override
  RenderPinnableMessageSliver createRenderObject(BuildContext context) {
    return RenderPinnableMessageSliver(vsync: vsync, pinned: pinned);
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderPinnableMessageSliver renderObject) {
    renderObject
      ..vsync = vsync
      ..pinned = pinned;
  }
}

class RenderPinnableMessageSliver extends RenderSliverToBoxAdapter {
  late final AnimationController _controller;
  bool _pinned;

  RenderPinnableMessageSliver(
      {required TickerProvider vsync, required bool pinned, RenderBox? child})
      : _vsync = vsync,
        _pinned = pinned,
        super(child: child) {
    _controller = AnimationController(
        vsync: vsync,
        value: pinned ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        reverseDuration: const Duration(milliseconds: 300));
    CurvedAnimation(parent: _controller, curve: Curves.easeOut)
        .addListener(markNeedsLayout);
  }

  TickerProvider get vsync => _vsync;
  TickerProvider _vsync;
  set vsync(TickerProvider value) {
    if (value == _vsync) return;
    _vsync = value;
    _controller.resync(vsync);
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    if (_pinned) {
      _controller.forward(from: 0.0);
    } else {
      _controller.reverse(from: 1.0);
    }
  }

  @override
  void detach() {
    _controller.stop();
    super.detach();
  }

  double get pinFraction => _controller.value;

  set pinned(bool value) {
    if (value == _pinned) {
      return;
    }
    if (value) {
      _controller.forward(from: 0.0);
    } else {
      _controller.reverse(from: 1.0);
    }
    _pinned = value;
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
