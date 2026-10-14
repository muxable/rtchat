import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/components/pinnable/scroll_view.dart';

/// Counts the tickers handed out that haven't been disposed yet, the way
/// TickerProviderStateMixin keeps them until they're disposed.
class _TrackingTickerProvider implements TickerProvider {
  final live = <Ticker>{};

  @override
  Ticker createTicker(TickerCallback onTick) {
    late final _TrackedTicker ticker;
    ticker = _TrackedTicker(onTick, () => live.remove(ticker));
    live.add(ticker);
    return ticker;
  }
}

class _TrackedTicker extends Ticker {
  final VoidCallback onDispose;

  _TrackedTicker(super.onTick, this.onDispose);

  @override
  void dispose() {
    onDispose();
    super.dispose();
  }
}

Widget _scrollView(TickerProvider vsync, List<PinState> pins) {
  return MaterialApp(
    home: PinnableMessageScrollView(
      vsync: vsync,
      count: pins.length,
      isPinnedBuilder: (index) => pins[index],
      itemBuilder: (index) =>
          SizedBox(key: ValueKey(index), height: 20, child: Text('$index')),
      findChildIndexCallback: (key) => (key as ValueKey<int>).value,
    ),
  );
}

void main() {
  testWidgets("releases a pinned message's ticker when it stops being pinnable",
      (tester) async {
    final vsync = _TrackingTickerProvider();

    await tester.pumpWidget(_scrollView(vsync, [
      PinState.notPinnable,
      PinState.pinned,
      PinState.notPinnable,
    ]));
    await tester.pumpAndSettle();
    expect(vsync.live, hasLength(1));

    // the pin expires, e.g. a raid's event duration ends.
    await tester.pumpWidget(_scrollView(vsync, [
      PinState.notPinnable,
      PinState.notPinnable,
      PinState.notPinnable,
    ]));
    await tester.pumpAndSettle();
    expect(vsync.live, isEmpty);
  });

  testWidgets("doesn't accumulate tickers as pinned messages come and go",
      (tester) async {
    final vsync = _TrackingTickerProvider();

    // a busy channel: pinnable events keep arriving and old ones are pruned,
    // which shifts every sliver's key.
    for (var i = 0; i < 50; i++) {
      await tester.pumpWidget(_scrollView(vsync, [
        PinState.pinned,
        PinState.unpinned,
        // older messages; pruning them changes the list length.
        for (var j = 0; j < i % 7; j++) PinState.notPinnable,
      ]));
      await tester.pump(const Duration(milliseconds: 400));
    }
    expect(vsync.live.length, lessThanOrEqualTo(2));

    await tester.pumpWidget(const SizedBox());
    expect(vsync.live, isEmpty);
  });
}
