import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/models/adapters/messages.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/messages.dart';
import 'package:rtchat/models/messages/message.dart';
import 'package:rtchat/models/messages/youtube/event.dart';
import 'package:rtchat/models/messages/youtube/message.dart';

const channelId = "UCX6OQ3DkcsbYNE6H8uQQuVA";
final channel = Channel(Providers.youtube, channelId, "MrBeast");
final published = DateTime.utc(2026, 10, 14, 12, 0, 0, 123, 456);

Map<String, dynamic> author({String id = "UCauthor"}) => {
      "channelId": id,
      "channelUrl": "https://www.youtube.com/channel/$id",
      "displayName": "@Viewer",
      "profileImageUrl": "https://yt4.ggpht.com/viewer=s64",
      "isVerified": false,
      "isChatOwner": false,
      "isChatSponsor": true,
      "isChatModerator": true,
    };

Map<String, dynamic> emptyAuthor() => {
      "channelId": "",
      "channelUrl": "",
      "displayName": "",
      "profileImageUrl": "",
      "isVerified": false,
      "isChatOwner": false,
      "isChatSponsor": false,
      "isChatModerator": false,
    };

// A document exactly as agent/internal/youtube/actions.go actionData writes it
// to channels/youtube:{channelId}/messages/youtube:{id}.
Map<String, dynamic> agentDoc(String kind, String id,
    {String display = "",
    Map<String, dynamic> details = const {},
    Map<String, dynamic>? authorDetails,
    String authorChannelId = "UCauthor"}) {
  return {
    "type": "youtube.$kind",
    "channelId": "youtube:$channelId",
    "timestamp": Timestamp.fromDate(published),
    "expiresAt": Timestamp.fromDate(published.add(const Duration(days: 14))),
    "event": {
      "id": id,
      "snippet": {
        "type": kind,
        "liveChatId": "innertube:dQw4w9WgXcQ",
        "authorChannelId": authorChannelId,
        // go's time.RFC3339Nano.
        "publishedAt": "2026-10-14T12:00:00.123456Z",
        "hasDisplayContent": true,
        "displayMessage": display,
        ...details,
      },
      "authorDetails": authorDetails ?? author(),
    },
  };
}

Map<String, dynamic> textDoc(String id, String text,
        {String authorId = "UCauthor"}) =>
    agentDoc("textMessageEvent", id,
        display: text,
        authorChannelId: authorId,
        authorDetails: author(id: authorId),
        details: {
          "textMessageDetails": {"messageText": text}
        });

void main() {
  test("text messages parse into youtube messages on their channel", () {
    final event = toChannelDeltaEvent(
        channel, const [], "youtube:LCC.abc", textDoc("LCC.abc", "hi :wave:"));
    final model = (event as AppendDeltaEvent).model as YouTubeMessageModel;
    expect(model.messageId, "youtube:LCC.abc");
    expect(model.message, "hi :wave:");
    expect(model.channelId, "youtube:$channelId");
    expect(model.channel, channel);
    expect(model.timestamp, published);
    expect(model.author.userId, "UCauthor");
    expect(model.author.displayName, "@Viewer");
    expect(model.author.isChatModerator, isTrue);
    expect(model.author.isChatSponsor, isTrue);
  });

  test("messages carry the channel from the document", () {
    final event =
        toDeltaEvent(const [], "youtube:LCC.abc", textDoc("LCC.abc", "hi"));
    expect((event as AppendDeltaEvent).model.channel, channel);
  });

  test("super chats parse their amount", () {
    final event = toDeltaEvent(
        const [],
        "youtube:LCC.sc",
        agentDoc("superChatEvent", "LCC.sc", display: "gg", details: {
          "superChatDetails": {
            "amountDisplayString": "USD 5.00",
            "userComment": "gg",
            "currency": "USD",
            "amountMicros": "5000000",
          }
        }));
    final model =
        (event as AppendDeltaEvent).model as YouTubeSuperChatEventModel;
    expect(model.amountMicros, 5000000);
    expect(model.currency, "USD");
    expect(model.amountDisplayString, "USD 5.00");
    expect(model.comment, "gg");
  });

  test("membership events parse", () {
    final milestone = toDeltaEvent(
        const [],
        "youtube:LCC.ms",
        agentDoc("memberMilestoneChatEvent", "LCC.ms", details: {
          "memberMilestoneChatDetails": {
            "memberMonth": 12,
            "userComment": "hello",
            "memberLevelName": "Gold",
          }
        })) as AppendDeltaEvent;
    expect((milestone.model as YouTubeMemberMilestoneEventModel).months, 12);

    final gifting = toDeltaEvent(
        const [],
        "youtube:LCC.gift",
        agentDoc("membershipGiftingEvent", "LCC.gift", details: {
          "membershipGiftingDetails": {"giftMembershipsCount": 5}
        })) as AppendDeltaEvent;
    expect((gifting.model as YouTubeMembershipGiftingEventModel).count, 5);
  });

  test("a tombstone deletes the message it targets", () {
    final append = toChannelDeltaEvent(
            channel, const [], "youtube:LCC.abc", textDoc("LCC.abc", "hi"))
        as AppendDeltaEvent;
    final messages = applyDeltaEvent([], append);
    final tombstone = toDeltaEvent(
        const [],
        "youtube:LCC.abc",
        agentDoc("tombstone", "LCC.abc",
            authorChannelId: "", authorDetails: emptyAuthor()))!;
    expect(tombstone, isA<UpdateDeltaEvent>());
    applyDeltaEvent(messages, tombstone);
    final message = messages.single as YouTubeMessageModel;
    expect(message.deleted, isTrue);
    expect(message.channel, channel);
  });

  test("a ban deletes the banned user's messages", () {
    var messages = applyDeltaEvent(
        [],
        toChannelDeltaEvent(channel, const [], "youtube:a",
            textDoc("a", "spam", authorId: "UCspammer"))!);
    messages = applyDeltaEvent(
        messages,
        toChannelDeltaEvent(channel, const [], "youtube:b",
            textDoc("b", "hi", authorId: "UCother"))!);
    final ban = toDeltaEvent(
        const [],
        "youtube:ban-1",
        agentDoc("userBannedEvent", "ban-1",
            authorChannelId: "",
            authorDetails: emptyAuthor(),
            details: {
              "userBannedDetails": {
                "bannedUserDetails": {"channelId": "UCspammer"}
              }
            }))!;
    expect(ban, isA<UpdateAllDeltaEvent>());
    messages = applyDeltaEvent(messages, ban);
    final byAuthor = {
      for (final m in messages.cast<YouTubeMessageModel>())
        m.author.userId: m.deleted
    };
    expect(byAuthor, {"UCspammer": true, "UCother": false});
  });

  test("the document timestamp is used when the snippet has none", () {
    final doc = textDoc("LCC.abc", "hi");
    (doc["event"]["snippet"] as Map).remove("publishedAt");
    final event = toDeltaEvent(const [], "youtube:LCC.abc", doc);
    expect((event as AppendDeltaEvent).model.timestamp, published);
  });

  test("malformed or unknown youtube documents are skipped", () {
    expect(
        toDeltaEvent(const [], "youtube:x",
            agentDoc("viewerEngagementMessageEvent", "x")),
        isNull);
    expect(
        toDeltaEvent(
            const [],
            "youtube:x",
            {
              "type": "youtube.textMessageEvent",
              "channelId": "youtube:$channelId",
            }),
        isNull);
    expect(
        toDeltaEvent(
            const [],
            "youtube:x",
            {
              ...textDoc("x", "hi"),
              "channelId": "twitch:123",
            }),
        isNull);
  });
}
