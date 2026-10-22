import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/components/channel_attribution.dart';
import 'package:rtchat/components/provider_icon.dart';
import 'package:rtchat/models/channels.dart';

void main() {
  testWidgets("attribution shows the message's platform", (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ChannelAttribution(provider: Providers.kick, child: Text('hi')),
      ),
    );
    expect(find.byType(ProviderIcon), findsOneWidget);
    expect(find.text('hi'), findsOneWidget);
  });

  Widget attributed(
    String text, {
    TextDirection direction = TextDirection.ltr,
  }) => MaterialApp(
    home: Directionality(
      textDirection: direction,
      child: DefaultTextStyle(
        style: const TextStyle(fontSize: 20),
        child: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 200,
            child: ChannelAttribution(
              provider: Providers.kick,
              child: Text(text),
            ),
          ),
        ),
      ),
    ),
  );

  testWidgets("attribution sits at the end of the message's first line", (
    tester,
  ) async {
    await tester.pumpWidget(attributed('hi'));
    final line = tester.getRect(find.text('hi'));
    final icon = tester.getRect(find.byType(ProviderIcon));
    expect(icon.left, greaterThan(line.right));
    expect(
      tester.getRect(find.byType(ChannelAttribution)).right - icon.right,
      moreOrLessEquals(8),
    );
    expect(icon.center.dy, moreOrLessEquals(line.center.dy, epsilon: 1));

    const long = 'a message long enough to wrap onto a few lines';
    await tester.pumpWidget(attributed(long));
    final message = tester.getRect(find.text(long));
    final wrapped = tester.getRect(find.byType(ProviderIcon));
    expect(message.height, greaterThan(2 * line.height));
    // pinned to the first line, not centered on the whole message.
    expect(
      wrapped.center.dy - message.top,
      moreOrLessEquals(line.height / 2, epsilon: 1),
    );
  });

  testWidgets("attribution follows the text direction", (tester) async {
    await tester.pumpWidget(attributed('hi', direction: TextDirection.rtl));
    final line = tester.getRect(find.text('hi'));
    final icon = tester.getRect(find.byType(ProviderIcon));
    expect(icon.right, lessThan(line.left));
    expect(
      icon.left - tester.getRect(find.byType(ChannelAttribution)).left,
      moreOrLessEquals(8),
    );
  });
}
