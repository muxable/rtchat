import 'package:rtchat/models/adapters/messages.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/messages/message.dart';
import 'package:rtchat/models/messages/youtube/event.dart';
import 'package:rtchat/models/messages/youtube/message.dart';
import 'package:rtchat/models/messages/youtube/user.dart';

// These parse a `LiveChatMessage` in its REST/proto3 JSON form, see
// https://developers.google.com/youtube/v3/live/docs/liveChatMessages#resource.
// proto3 JSON encodes 64-bit integers as strings, so numbers are read either
// way.

int _int(dynamic value, [int fallback = 0]) {
  if (value is int) {
    return value;
  } else if (value is num) {
    return value.toInt();
  } else if (value is String) {
    return int.tryParse(value) ?? double.tryParse(value)?.toInt() ?? fallback;
  }
  return fallback;
}

Map<String, dynamic> _map(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : const {};

String? _nonEmpty(dynamic value) =>
    value is String && value.isNotEmpty ? value : null;

/// The app's message ID for a YouTube message ID.
String youTubeMessageId(String id) => "youtube:$id";

/// The time the message was published, or now if it's missing.
DateTime youTubeMessageTimestamp(Map<String, dynamic> message) =>
    DateTime.tryParse(_map(message['snippet'])['publishedAt'] ?? '') ??
    DateTime.now();

/// Parses the messages and events that are shown in chat. Returns null for
/// tombstones, bans and types that aren't shown.
MessageModel? youTubeMessageFromJson(Map<String, dynamic> message,
    {required Channel channel}) {
  final snippet = _map(message['snippet']);
  final messageId = youTubeMessageId(message['id']?.toString() ?? '');
  final timestamp = youTubeMessageTimestamp(message);
  final author = YouTubeUserModel.fromJson(_map(message['authorDetails']));

  switch (snippet['type']) {
    case 'textMessageEvent':
      return YouTubeMessageModel(
          messageId: messageId,
          timestamp: timestamp,
          author: author,
          message: _map(snippet['textMessageDetails'])['messageText'] ??
              snippet['displayMessage'] ??
              '',
          channelId: channel.toString());
    case 'superChatEvent':
      final details = _map(snippet['superChatDetails']);
      return YouTubeSuperChatEventModel(
          messageId: messageId,
          timestamp: timestamp,
          author: author,
          amountMicros: _int(details['amountMicros']),
          currency: details['currency'] ?? '',
          amountDisplayString: details['amountDisplayString'] ?? '',
          tier: _int(details['tier'], 1),
          comment: _nonEmpty(details['userComment']));
    case 'superStickerEvent':
      final details = _map(snippet['superStickerDetails']);
      final sticker = _map(details['superStickerMetadata']);
      return YouTubeSuperStickerEventModel(
          messageId: messageId,
          timestamp: timestamp,
          author: author,
          amountMicros: _int(details['amountMicros']),
          currency: details['currency'] ?? '',
          amountDisplayString: details['amountDisplayString'] ?? '',
          tier: _int(details['tier'], 1),
          stickerId: sticker['stickerId'] ?? '',
          altText: _nonEmpty(sticker['altText']));
    case 'newSponsorEvent':
      final details = _map(snippet['newSponsorDetails']);
      return YouTubeNewMemberEventModel(
          messageId: messageId,
          timestamp: timestamp,
          member: author,
          levelName: details['memberLevelName'] ?? '',
          isUpgrade: details['isUpgrade'] == true);
    case 'memberMilestoneChatEvent':
      final details = _map(snippet['memberMilestoneChatDetails']);
      return YouTubeMemberMilestoneEventModel(
          messageId: messageId,
          timestamp: timestamp,
          member: author,
          levelName: details['memberLevelName'] ?? '',
          months: _int(details['memberMonth'], 1),
          comment: _nonEmpty(details['userComment']));
    case 'membershipGiftingEvent':
      final details = _map(snippet['membershipGiftingDetails']);
      return YouTubeMembershipGiftingEventModel(
          messageId: messageId,
          timestamp: timestamp,
          gifter: author,
          count: _int(details['giftMembershipsCount'], 1),
          levelName: details['giftMembershipsLevelName'] ?? '');
    case 'giftMembershipReceivedEvent':
      final details = _map(snippet['giftMembershipReceivedDetails']);
      return YouTubeGiftMembershipReceivedEventModel(
          messageId: messageId,
          timestamp: timestamp,
          recipient: author,
          levelName: details['memberLevelName'] ?? '',
          gifterChannelId: _nonEmpty(details['gifterChannelId']));
    case 'giftEvent':
      final details = _map(snippet['giftDetails']);
      return YouTubeGiftEventModel(
          messageId: messageId,
          timestamp: timestamp,
          sender: author,
          giftName: details['giftName'] ?? '',
          jewels: details['jewelsAmount'] == null
              ? null
              : _int(details['jewelsAmount']),
          giftUrl: _nonEmpty(details['giftUrl']),
          altText: _nonEmpty(details['altText']),
          comboCount: _int(details['comboCount'], 1));
    case 'pollEvent':
      final details = _map(snippet['pollDetails']);
      final metadata = _map(details['metadata']);
      return YouTubePollEventModel(
          messageId: messageId,
          timestamp: timestamp,
          author: author,
          question: metadata['questionText'] ?? '',
          options: [
            for (final option in (metadata['options'] as List?) ?? const [])
              YouTubePollOption(
                  text: _map(option)['optionText'] ?? '',
                  tally: _int(_map(option)['tally'])),
          ],
          isClosed: details['status']?.toString().toLowerCase() == 'closed');
    case 'sponsorOnlyModeStartedEvent':
    case 'sponsorOnlyModeEndedEvent':
      return YouTubeMembersOnlyModeEventModel(
          messageId: messageId,
          timestamp: timestamp,
          isEnabled: snippet['type'] == 'sponsorOnlyModeStartedEvent');
    case 'chatEndedEvent':
      return YouTubeChatEndedEventModel(
          messageId: messageId, timestamp: timestamp);
  }
  return null;
}

/// Turns a `LiveChatMessage` into a change to the chat history: new messages
/// and events are appended, a tombstone marks its message deleted and a ban
/// hides the banned user's messages.
DeltaEvent? youTubeDeltaEvent(Map<String, dynamic> message,
    {required Channel channel}) {
  final snippet = _map(message['snippet']);
  final timestamp = youTubeMessageTimestamp(message);
  switch (snippet['type']) {
    case 'tombstone':
      // a tombstone replaces the deleted message and keeps its id.
      return UpdateDeltaEvent(
          youTubeMessageId(message['id']?.toString() ?? ''), timestamp,
          (model) {
        if (model is! YouTubeMessageModel) {
          return model;
        }
        return model.withDeleted(true);
      });
    case 'messageDeletedEvent':
      final deletedId =
          _map(snippet['messageDeletedDetails'])['deletedMessageId'];
      if (deletedId == null) {
        return null;
      }
      return UpdateDeltaEvent(youTubeMessageId(deletedId.toString()), timestamp,
          (model) {
        if (model is! YouTubeMessageModel) {
          return model;
        }
        return model.withDeleted(true);
      });
    case 'userBannedEvent':
      // like a twitch userclear: the user's messages are removed.
      final bannedUserId =
          _map(_map(snippet['userBannedDetails'])['bannedUserDetails'])[
                  'channelId']
              ?.toString();
      if (bannedUserId == null) {
        return null;
      }
      return UpdateAllDeltaEvent(timestamp, (model) {
        if (model is! YouTubeMessageModel ||
            model.author.userId != bannedUserId) {
          return model;
        }
        return model.withDeleted(true);
      });
  }
  final model = youTubeMessageFromJson(message, channel: channel);
  if (model == null) {
    return null;
  }
  model.channel = channel;
  return AppendDeltaEvent(model);
}
