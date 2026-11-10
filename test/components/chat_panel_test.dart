import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/components/chat_panel.dart';
import 'package:rtchat/components/pinnable/scroll_view.dart';

/// The chat list as the chat panel builds it, newest message first.
Widget _chatList(List<String> messageIds) {
  final keys = uniqueKeys(messageIds);
  return MaterialApp(
    home: Scaffold(
      body: PinnableMessageScrollView(
        vsync: const TestVSync(),
        count: keys.length,
        isPinnedBuilder: (index) => PinState.notPinnable,
        itemBuilder:
            (index) => SizedBox(
              key: Key(keys[index]),
              height: 20,
              child: Text(messageIds[index]),
            ),
        findChildIndexCallback: (key) => keys.indexWhere((k) => key == Key(k)),
      ),
    ),
  );
}

void main() {
  test('suffixes repeated keys, numbered from the oldest', () {
    expect(uniqueKeys(['c', 'a', 'b', 'a', 'a']), [
      'c',
      'a#2',
      'b',
      'a#1',
      'a',
    ]);
    expect(uniqueKeys(['b', 'a']), ['b', 'a']);
  });

  test('keeps keys stable as newer messages arrive', () {
    expect(uniqueKeys(['d', 'a', 'a']).sublist(1), uniqueKeys(['a', 'a']));
  });

  testWidgets('a repeated message keeps the chat list intact as it moves', (
    tester,
  ) async {
    // the same message delivered twice, then newer messages push it up.
    await tester.pumpWidget(_chatList(['c', 'b', 'a', 'a']));
    await tester.pumpWidget(_chatList(['e', 'd', 'c', 'b', 'a', 'a']));
    await tester.pumpWidget(
      _chatList(['g', 'f', 'e', 'd', 'c', 'b', 'a', 'a']),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('a'), findsNWidgets(2));
  });
}
