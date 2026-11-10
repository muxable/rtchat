import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/models/adapters/messages.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/messages.dart';
import 'package:rtchat/models/messages/message.dart';
import 'package:rtchat/models/messages/twitch/message.dart';

final channel = Channel(Providers.twitch, "123", "muxfd");

Map<String, dynamic> chatDoc(String text) => {
  'type': 'message',
  'channelId': 'twitch:123',
  'message': text,
  'timestamp': Timestamp.fromDate(DateTime(2024)),
  'tags': {'user-id': '42', 'display-name': 'Viewer', 'username': 'viewer'},
  'annotations': {'isAction': false, 'isFirstTimeChatter': false},
};

void main() {
  test("parsed messages carry the channel they came from", () {
    final event = toChannelDeltaEvent(
      channel,
      const [],
      "twitch:m1",
      chatDoc("hi"),
    );
    expect((event as AppendDeltaEvent).model.channel, channel);
  });

  test("messages without a known channel return null", () {
    final event = toDeltaEvent(const [], "twitch:m1", chatDoc("hi"));
    expect((event as AppendDeltaEvent).model.channel, isNull);
  });

  test("updates keep the replaced message's channel", () {
    final append =
        toChannelDeltaEvent(channel, const [], "twitch:m1", chatDoc("hi"))
            as AppendDeltaEvent;
    final messages = applyDeltaEvent([], append);
    final deleted =
        toDeltaEvent(const [], "twitch:d1", {
          'type': 'messagedeleted',
          'messageId': 'twitch:m1',
          'timestamp': Timestamp.fromDate(DateTime(2024, 1, 2)),
        })!;
    applyDeltaEvent(messages, deleted);
    final message = messages.single as TwitchMessageModel;
    expect(message.deleted, isTrue);
    expect(message.channel, channel);
  });
}
