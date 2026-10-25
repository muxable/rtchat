import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/models/adapters/messages.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/messages.dart';
import 'package:rtchat/models/messages/message.dart';
import 'package:rtchat/models/messages/twitch/message.dart';
import 'package:rtchat/models/messages/twitch/user.dart';

final t0 = DateTime(2024, 1, 1, 12);

TwitchMessageModel chat(
  String id,
  DateTime timestamp, {
  String userId = 'u1',
  bool deleted = false,
}) => TwitchMessageModel(
  messageId: id,
  author: TwitchUserModel(userId: userId, login: 'login$userId'),
  message: 'message $id',
  tags: const {},
  annotations: const TwitchMessageAnnotationsModel(
    isAction: false,
    isFirstTimeChatter: false,
    announcement: null,
  ),
  thirdPartyEmotes: const [],
  timestamp: timestamp,
  deleted: deleted,
  channelId: 'twitch:1',
);

StreamStateEventModel streamState(String id, DateTime timestamp) =>
    StreamStateEventModel(messageId: id, isOnline: true, timestamp: timestamp);

List<String> ids(List<MessageModel> messages) =>
    messages.map((m) => m.messageId).toList();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('applyDeltaEvent', () {
    test('appends in-order messages and reports them', () {
      final appended = <MessageModel>[];
      var messages = <MessageModel>[];
      for (var i = 0; i < 3; i++) {
        messages = applyDeltaEvent(
          messages,
          AppendDeltaEvent(chat('m$i', t0.add(Duration(seconds: i)))),
          onAppend: appended.add,
        );
      }
      expect(ids(messages), ['m0', 'm1', 'm2']);
      expect(ids(appended), ['m0', 'm1', 'm2']);
    });

    test('messages with equal timestamps are appended', () {
      final appended = <MessageModel>[];
      var messages = <MessageModel>[chat('a', t0)];
      messages = applyDeltaEvent(
        messages,
        AppendDeltaEvent(chat('b', t0)),
        onAppend: appended.add,
      );
      expect(ids(messages), ['a', 'b']);
      expect(ids(appended), ['b']);
    });

    test('inserts out-of-order messages by timestamp and reports them', () {
      final appended = <MessageModel>[];
      var messages = <MessageModel>[
        chat('a', t0),
        chat('c', t0.add(const Duration(seconds: 2))),
        chat('d', t0.add(const Duration(seconds: 3))),
      ];
      messages = applyDeltaEvent(
        messages,
        AppendDeltaEvent(chat('b', t0.add(const Duration(seconds: 1)))),
        onAppend: appended.add,
      );
      expect(ids(messages), ['a', 'b', 'c', 'd']);
      expect(ids(appended), ['b']);

      messages = applyDeltaEvent(
        messages,
        AppendDeltaEvent(chat('z', t0.subtract(const Duration(seconds: 1)))),
        onAppend: appended.add,
      );
      expect(ids(messages), ['z', 'a', 'b', 'c', 'd']);
      expect(ids(appended), ['b', 'z']);
    });

    test('UpdateDeltaEvent replaces only the first matching message', () {
      final updates = <(MessageModel, MessageModel)>[];
      final messages = <MessageModel>[
        chat('a', t0),
        chat('b', t0),
        chat('b', t0),
      ];
      final result = applyDeltaEvent(
        messages,
        UpdateDeltaEvent(
          'b',
          t0,
          (m) => (m as TwitchMessageModel).withDeleted(true),
        ),
        onUpdate:
            (event, previous, updated) => updates.add((previous, updated)),
      );
      expect(result, same(messages));
      expect((result[0] as TwitchMessageModel).deleted, isFalse);
      expect((result[1] as TwitchMessageModel).deleted, isTrue);
      expect((result[2] as TwitchMessageModel).deleted, isFalse);
      expect(updates, hasLength(1));
      expect((updates.single.$1 as TwitchMessageModel).deleted, isFalse);
      expect((updates.single.$2 as TwitchMessageModel).deleted, isTrue);
    });

    test('UpdateDeltaEvent for an unknown message is a no-op', () {
      var called = false;
      final messages = <MessageModel>[chat('a', t0)];
      final result = applyDeltaEvent(
        messages,
        UpdateDeltaEvent('missing', t0, (m) => m),
        onUpdate: (messageId, oldMessage, newMessage) => called = true,
      );
      expect(ids(result), ['a']);
      expect(called, isFalse);
    });

    test('UpdateAllDeltaEvent updates every message', () {
      final updated = <MessageModel>[];
      final messages = <MessageModel>[
        chat('a', t0, userId: 'u1'),
        streamState('s', t0),
        chat('b', t0, userId: 'u2'),
      ];
      final result = applyDeltaEvent(
        messages,
        UpdateAllDeltaEvent(t0, (m) {
          if (m is TwitchMessageModel && m.author.userId == 'u1') {
            return m.withDeleted(true);
          }
          return m;
        }),
        onUpdate: (event, previous, next) => updated.add(next),
      );
      expect((result[0] as TwitchMessageModel).deleted, isTrue);
      expect(result[1], isA<StreamStateEventModel>());
      expect((result[2] as TwitchMessageModel).deleted, isFalse);
      expect(updated, hasLength(3));
    });

    test('ClearDeltaEvent replaces messages with a cleared event', () {
      final messages = <MessageModel>[chat('a', t0), chat('b', t0)];
      final clearedAt = t0.add(const Duration(minutes: 1));
      final result = applyDeltaEvent(
        messages,
        ClearDeltaEvent(messageId: 'clear', timestamp: clearedAt),
      );
      expect(result, isNot(same(messages)));
      expect(result.single, isA<ChatClearedEventModel>());
      expect(result.single.messageId, 'clear');
      expect(result.single.timestamp, clearedAt);
    });

    test('LiveStateDeltaEvent leaves messages unchanged', () {
      final messages = <MessageModel>[chat('a', t0)];
      final result = applyDeltaEvent(messages, LiveStateDeltaEvent(t0));
      expect(result, same(messages));
      expect(ids(result), ['a']);
    });
  });

  group('computeSeparators', () {
    List<int> appendAll(List<MessageModel> models) {
      final messages = <MessageModel>[];
      for (final model in models) {
        applyDeltaEvent(messages, AppendDeltaEvent(model));
      }
      return computeSeparators(messages).toList()..sort();
    }

    test('adds a separator for the first message', () {
      expect(appendAll([chat('a', t0)]), [0]);
    });

    test('adds a separator every 50 chat messages', () {
      final models = [
        for (var i = 0; i < 120; i++) chat('m$i', t0.add(Duration(seconds: i))),
      ];
      expect(appendAll(models), [0, 49, 98]);
    });

    test('non-chat messages do not trigger the 50 message separator', () {
      final models = <MessageModel>[
        for (var i = 0; i < 60; i++)
          streamState('s$i', t0.add(Duration(seconds: i))),
      ];
      expect(appendAll(models), [0]);
    });

    test('adds a separator after a gap of at least 6 whole minutes', () {
      final models = [
        chat('a', t0),
        chat('b', t0.add(const Duration(minutes: 5, seconds: 59))),
        chat('c', t0.add(const Duration(minutes: 11, seconds: 59))),
        chat('d', t0.add(const Duration(minutes: 13))),
      ];
      // the gap is compared in whole minutes, so 5m59s is not enough.
      expect(appendAll(models), [0, 2]);
    });

    test('out-of-order inserts keep separators on the right messages', () {
      // a and b are 10 minutes apart, so b starts a new section.
      final messages = <MessageModel>[];
      for (final model in [
        chat('a', t0),
        chat('b', t0.add(const Duration(minutes: 10))),
        // x arrives late and lands between a and b.
        chat('x', t0.add(const Duration(minutes: 1))),
      ]) {
        applyDeltaEvent(messages, AppendDeltaEvent(model));
      }
      expect(ids(messages), ['a', 'x', 'b']);
      // the gap is now between x and b, so the separator stays on b.
      expect(computeSeparators(messages).toList()..sort(), [0, 2]);
    });

    test('separators follow messages when older ones are pruned', () {
      final messages = <MessageModel>[
        chat('a', t0),
        chat('b', t0.add(const Duration(minutes: 1))),
        chat('c', t0.add(const Duration(minutes: 10))),
      ];
      expect(computeSeparators(messages).toList()..sort(), [0, 2]);
      messages.removeAt(0);
      expect(computeSeparators(messages).toList()..sort(), [0, 1]);
    });
  });

  group('MessagesModel', () {
    test('shouldPing is false without messages', () {
      final model = MessagesModel.fromJson({});
      expect(model.shouldPing(), isFalse);
    });

    test('shouldPing for a single message depends on its recency', () {
      final model = MessagesModel.fromJson({});
      model.messages.add(chat('a', DateTime.now()));
      expect(model.shouldPing(), isTrue);

      model.messages
        ..clear()
        ..add(chat('a', DateTime.now().subtract(const Duration(minutes: 1))));
      expect(model.shouldPing(), isFalse);
    });

    test('shouldPing compares the last gap to pingMinGapDuration', () {
      final model = MessagesModel.fromJson({'pingMinGapDuration': 60});
      expect(model.pingMinGapDuration, const Duration(minutes: 1));
      model.messages
        ..add(chat('a', t0))
        ..add(chat('b', t0.add(const Duration(seconds: 60))));
      expect(model.shouldPing(), isFalse);

      model.messages.add(chat('c', t0.add(const Duration(seconds: 121))));
      expect(model.shouldPing(), isTrue);
    });

    test('shouldPing is disabled by default', () {
      final model = MessagesModel.fromJson({});
      model.messages
        ..add(chat('a', t0))
        ..add(chat('b', t0.add(const Duration(days: 365))));
      expect(model.shouldPing(), isFalse);
    });

    test('pruneMessages keeps the latest 1000 messages', () {
      final model = MessagesModel.fromJson({});
      for (var i = 0; i < 1200; i++) {
        model.messages.add(chat('m$i', t0.add(Duration(seconds: i))));
      }
      model.pruneMessages();
      expect(model.messages, hasLength(1000));
      expect(model.messages.first.messageId, 'm200');
      expect(model.messages.last.messageId, 'm1199');
    });

    test('pruneMessages leaves small histories alone', () {
      final model = MessagesModel.fromJson({});
      for (var i = 0; i < 1000; i++) {
        model.messages.add(chat('m$i', t0.add(Duration(seconds: i))));
      }
      model.pruneMessages();
      expect(model.messages, hasLength(1000));
      expect(model.messages.first.messageId, 'm0');
    });

    test('authors are the unique chat message authors', () {
      final model = MessagesModel.fromJson({});
      model.messages
        ..add(chat('a', t0, userId: 'u1'))
        ..add(chat('b', t0, userId: 'u2'))
        ..add(chat('c', t0, userId: 'u1'))
        ..add(streamState('s', t0));
      expect(model.authors.map((a) => a.userId).toSet(), {'u1', 'u2'});
    });

    group('message alerts', () {
      final a = Channel('twitch', 'a', 'A');
      final b = Channel('kick', 'b', 'B');
      late MessagesModel model;
      late int pings;

      MessageModel from(Channel channel, String id, DateTime timestamp) =>
          chat(id, timestamp)..channel = channel;

      setUp(() {
        pings = 0;
        model =
            MessagesModel.fromJson({'pingMinGapDuration': 60})
              ..isOnline = ((_) => Stream.value(true))
              ..onMessagePing = (() => pings++);
        model.addEvent(a, LiveStateDeltaEvent(t0));
        model.addEvent(b, LiveStateDeltaEvent(t0));
      });

      test('ping on the appended message, not the previous ones', () async {
        model.addEvent(a, AppendDeltaEvent(from(a, 'a1', t0)));
        model.addEvent(
          a,
          AppendDeltaEvent(from(a, 'a2', t0.add(const Duration(seconds: 10)))),
        );
        await pumpEventQueue();
        expect(pings, 0);

        model.addEvent(
          a,
          AppendDeltaEvent(from(a, 'a3', t0.add(const Duration(seconds: 200)))),
        );
        await pumpEventQueue();
        expect(pings, 1);

        // the gap is small, so no ping even though the previous one had one.
        model.addEvent(
          a,
          AppendDeltaEvent(from(a, 'a4', t0.add(const Duration(seconds: 205)))),
        );
        await pumpEventQueue();
        expect(pings, 1);
      });
    });
  });

  group('dispose', () {
    test('stops listening to the channel', () async {
      final events = StreamController<DeltaEvent>();
      final model = MessagesModel.fromJson({})
        ..forChannel = (channel) => events.stream;
      model.channel = Channel('twitch', '1', 'one');
      expect(events.hasListener, isTrue);

      model.dispose();

      // a later event would otherwise notify the disposed model, and the
      // listener would keep the model and its messages alive.
      expect(events.hasListener, isFalse);
      await events.close();
    });
  });

  group('pullMoreMessages', () {
    final channel = Channel('twitch', '1', 'one');

    MessagesModel model(
      Future<List<DeltaEvent>> Function(Channel, DateTime) history,
    ) {
      final events = StreamController<DeltaEvent>();
      addTearDown(events.close);
      final model =
          MessagesModel.fromJson({})
            ..forChannel = ((_) => events.stream)
            ..forChannelHistory = history;
      model.channel = channel;
      model.addEvent(channel, AppendDeltaEvent(chat('m1', t0)));
      return model;
    }

    test('prepends older messages from before the oldest event', () async {
      final froms = <DateTime>[];
      final m = model((channel, from) async {
        froms.add(from);
        return [
          AppendDeltaEvent(chat('m0', t0.subtract(const Duration(minutes: 1)))),
        ];
      });
      expect(await m.pullMoreMessages(), isTrue);
      expect(froms, [t0]);
      expect(ids(m.messages), ['m0', 'm1']);
    });

    test('reports when there is nothing older', () async {
      final m = model((channel, from) async => const []);
      expect(await m.pullMoreMessages(), isFalse);
      expect(ids(m.messages), ['m1']);
    });

    test('may have more while history has not loaded yet', () async {
      final events = StreamController<DeltaEvent>();
      addTearDown(events.close);
      var calls = 0;
      final m =
          MessagesModel.fromJson({})
            ..forChannel = ((_) => events.stream)
            ..forChannelHistory = ((channel, from) async {
              calls++;
              return const [];
            });
      m.channel = channel;
      expect(await m.pullMoreMessages(), isTrue);
      expect(calls, 0);
    });
  });
}
