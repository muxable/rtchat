import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/chat_panel.dart';
import 'package:rtchat/models/adapters/messages.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/messages.dart';
import 'package:rtchat/models/messages/message.dart';
import 'package:rtchat/models/messages/twitch/eventsub_configuration.dart';
import 'package:rtchat/models/style.dart';
import 'package:rtchat/models/user.dart';

import '../fakes/fake_user_model.dart';
import 'l10n.dart';

final t0 = DateTime(2024, 1, 1, 12);

StreamStateEventModel state(int i) => StreamStateEventModel(
  messageId: 'm$i',
  isOnline: i.isEven,
  timestamp: t0.add(Duration(minutes: i)),
);

void main() {
  final channel = Channel('twitch', '1', 'one');

  Future<List<DateTime>> pump(
    WidgetTester tester, {
    required int loaded,
    required int older,
    int pageSize = 2,
  }) async {
    final events = StreamController<DeltaEvent>();
    addTearDown(events.close);
    final froms = <DateTime>[];
    var served = 0;
    final model =
        MessagesModel.fromJson({})
          ..forChannel = ((_) => events.stream)
          ..forChannelHistory = ((channel, from) async {
            froms.add(from);
            // the newest [pageSize] messages from before the oldest loaded.
            final n = (older - served).clamp(0, pageSize);
            final page = [
              for (var i = served + n; i > served; i--)
                AppendDeltaEvent(state(-i)),
            ];
            served += n;
            return page;
          });
    model.channel = channel;
    for (var i = 0; i < loaded; i++) {
      model.addEvent(channel, AppendDeltaEvent(state(i)));
    }
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<MessagesModel>.value(value: model),
          ChangeNotifierProvider(
            create: (_) => EventSubConfigurationModel.fromJson({}),
          ),
          ChangeNotifierProvider(create: (_) => StyleModel.fromJson({})),
          ChangeNotifierProvider<UserModel>(
            create: (_) => FakeUserModel(userChannel: channel),
          ),
        ],
        child: MaterialApp(
          home: TestLocalizations(
            child: Scaffold(body: ChatPanelWidget(channel: channel)),
          ),
        ),
      ),
    );
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      // the connection banner and separators need Firebase, which isn't set
      // up here.
      final error = tester.takeException();
      expect(error, anyOf(isNull, isA<FirebaseException>()));
    }
    return froms;
  }

  testWidgets('pages in older messages until the screen is filled', (
    tester,
  ) async {
    final froms = await pump(tester, loaded: 1, older: 5);
    // pages of 2 until the history runs out, then stops asking.
    expect(froms, [
      t0,
      t0.subtract(const Duration(minutes: 2)),
      t0.subtract(const Duration(minutes: 4)),
      t0.subtract(const Duration(minutes: 5)),
    ]);
    await tester.pump(const Duration(seconds: 1));
    expect(froms.length, 4);
  });

  testWidgets('does not page in when the screen is already full', (
    tester,
  ) async {
    final froms = await pump(tester, loaded: 100, older: 5);
    expect(froms, isEmpty);
  });

  testWidgets('pages in older messages when scrolled back to the top', (
    tester,
  ) async {
    final froms = await pump(tester, loaded: 100, older: 5);
    expect(froms, isEmpty);
    // the chat list is reversed, so its top is the end of the scroll extent.
    final position =
        tester.state<ScrollableState>(find.byType(Scrollable).first).position;
    expect(position.maxScrollExtent, greaterThan(0));
    position.jumpTo(position.maxScrollExtent);
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      // the oldest message's separator looks up the stream's uptime.
      expect(tester.takeException(), anyOf(isNull, isA<FirebaseException>()));
    }
    expect(froms, [t0]);
  });
}
