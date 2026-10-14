import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class PinnableMessageSliver extends SingleChildRenderObjectWidget {
  final bool pinned;
  final TickerProvider vsync;

  const PinnableMessageSliver({
    super.key,
    required this.vsync,
    required this.pinned,
    required Widget super.child,
  });

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
  late final CurvedAnimation _animation;
  bool _pinned;

  RenderPinnableMessageSliver(
      {required TickerProvider vsync, required bool pinned, super.child})
      : _vsync = vsync,
        _pinned = pinned {
    _controller = AnimationController(
        vsync: vsync,
        value: pinned ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        reverseDuration: const Duration(milliseconds: 300));
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut)
      ..addListener(markNeedsLayout);
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
    _animate(_pinned);
  }

  @override
  void detach() {
    _controller.stop();
    super.detach();
  }

  // the ticker provider holds on to every ticker until it's disposed, so a
  // dropped sliver would otherwise keep itself and its child alive.
  @override
  void dispose() {
    _animation.dispose();
    _controller.dispose();
    super.dispose();
  }

  double get pinFraction => _controller.value;

  set pinned(bool value) {
    if (value == _pinned) {
      return;
    }
    _animate(value);
    _pinned = value;
  }

  void _animate(bool value) {
    if (value) {
      if (!_controller.isCompleted) {
        _controller.forward(from: 0.0);
      }
    } else {
      if (!_controller.isDismissed) {
        _controller.reverse(from: 1.0);
      }
    }
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
