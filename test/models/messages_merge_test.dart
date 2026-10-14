import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/models/adapters/messages.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/messages.dart';
import 'package:rtchat/models/messages/message.dart';

import '../fakes/fake_chat.dart';

final twitch = Channel(Providers.twitch, '1', 'muxfd');
final kick = Channel(Providers.kick, '2', 'muxfd');
final t0 = DateTime(2025, 1, 1, 12);

FakeChatMessage chat(String id, int seconds, Channel channel,
        {String userId = 'u'}) =>
    FakeChatMessage(
        messageId: id,
        timestamp: t0.add(Duration(seconds: seconds)),
        author: FakeChatUser(userId: userId, login: userId),
        message: id)
      ..channel = channel;

List<String> ids(List<MessageModel> messages) =>
    messages.map((m) => m.messageId).toList();

void main() {
  test("interleaved channels are merged by time", () {
    final events = <ChannelEvent>[
      (channel: twitch, event: AppendDeltaEvent(chat('t1', 1, twitch))),
      (channel: twitch, event: AppendDeltaEvent(chat('t3', 3, twitch))),
      (channel: kick, event: AppendDeltaEvent(chat('k2', 2, kick))),
      (channel: kick, event: AppendDeltaEvent(chat('k4', 4, kick))),
    ];
    expect(ids(replayEvents(events)), ['t1', 'k2', 't3', 'k4']);
  });

  test("events at the same time keep the order they arrived in", () {
    final events = <ChannelEvent>[
      (channel: kick, event: AppendDeltaEvent(chat('k', 1, kick))),
      (channel: twitch, event: AppendDeltaEvent(chat('t', 1, twitch))),
    ];
    expect(ids(replayEvents(events)), ['k', 't']);
  });

  test("clearing one channel keeps the other's chat", () {
    var messages = <MessageModel>[
      chat('t1', 1, twitch),
      chat('k2', 2, kick),
      chat('t3', 3, twitch),
      chat('k4', 4, kick),
    ];
    messages = applyDeltaEvent(
        messages,
        ClearDeltaEvent(
            messageId: 'clear', timestamp: t0.add(const Duration(seconds: 5))),
        channel: twitch);
    expect(ids(messages), ['k2', 'k4', 'clear']);
    expect(messages.last, isA<ChatClearedEventModel>());
    expect(messages.last.channel, twitch);
  });

  test("a ban on one channel doesn't touch the other's messages", () {
    final messages = <MessageModel>[
      chat('t1', 1, twitch, userId: 'same'),
      chat('k2', 2, kick, userId: 'same'),
    ];
    applyDeltaEvent(
        messages,
        UpdateAllDeltaEvent(
            t0.add(const Duration(seconds: 3)),
            (message) => message is FakeChatMessage
                ? FakeChatMessage(
                    messageId: message.messageId,
                    timestamp: message.timestamp,
                    author: message.author,
                    message: message.message,
                    deleted: true)
                : message),
        channel: kick);
    expect((messages[0] as FakeChatMessage).deleted, isFalse);
    expect((messages[1] as FakeChatMessage).deleted, isTrue);
    // the replacement keeps the channel it came from.
    expect(messages[1].channel, kick);
  });

  test("without a channel, clears replace everything like before", () {
    final messages = applyDeltaEvent(
        [chat('t1', 1, twitch), chat('k2', 2, kick)],
        ClearDeltaEvent(messageId: 'clear', timestamp: t0));
    expect(ids(messages), ['clear']);
  });

  test("the model reports both channels", () {
    final model = MessagesModel.fromJson({});
    expect(model.channels, isEmpty);
    expect(model.isLive, isFalse);
  });
}
