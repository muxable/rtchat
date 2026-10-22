import 'package:rtchat/models/messages/chat.dart';
import 'package:rtchat/models/messages/kick/user.dart';
import 'package:rtchat/models/messages/message.dart';
import 'package:rtchat/models/messages/tokens.dart';
import 'package:rtchat/models/messages/twitch/message.dart'
    show tokenizeLinks, tokenizeTags;

/// Kick inlines emotes in message content as `[emote:<id>:<name>]`.
final _emotePattern = RegExp(r'\[emote:(\d+):([^\]]+)\]');

Uri kickEmoteUrl(String emoteId) =>
    Uri.parse("https://files.kick.com/emotes/$emoteId/fullsize");

class KickMessageReplyModel {
  final String messageId;
  final String content;
  final KickUserModel author;

  const KickMessageReplyModel({
    required this.messageId,
    required this.content,
    required this.author,
  });

  /// The replied-to message with emotes shown by name.
  String get text =>
      content.replaceAllMapped(_emotePattern, (match) => match.group(2)!);
}

class KickMessageModel extends MessageModel implements ChatMessage {
  @override
  final KickUserModel author;
  @override
  final String message;
  final KickMessageReplyModel? reply;
  @override
  final bool deleted;
  final String channelId;

  KickMessageModel({
    required super.messageId,
    required super.timestamp,
    required this.author,
    required this.message,
    this.reply,
    this.deleted = false,
    required this.channelId,
  });

  /// Parses the `event` of a `kick.chat.message.sent` document.
  factory KickMessageModel.fromEvent({
    required String messageId,
    required DateTime timestamp,
    required String channelId,
    required Map<String, dynamic> event,
  }) {
    final repliesTo = event['replies_to'];
    return KickMessageModel(
      messageId: messageId,
      timestamp: timestamp,
      channelId: channelId,
      author: KickUserModel.fromJson(
        Map<String, dynamic>.from(event['sender']),
      ),
      message: event['content'] ?? '',
      reply:
          repliesTo == null
              ? null
              : KickMessageReplyModel(
                messageId: "kick:${repliesTo['message_id']}",
                content: repliesTo['content'] ?? '',
                author: KickUserModel.fromJson(
                  Map<String, dynamic>.from(repliesTo['sender'] ?? {}),
                ),
              ),
    );
  }

  @override
  bool get isAction => false;

  @override
  bool get isCommand => message.startsWith("!");

  @override
  bool get isSubscriber => author.hasBadge("subscriber");

  @override
  List<MessageToken> get tokenized => _tokenized ??= tokenize();
  List<MessageToken>? _tokenized;

  List<MessageToken> tokenize() {
    Iterable<MessageToken> tokens = _tokenizeEmotes(message);
    tokens = tokenizeLinks(tokens);
    tokens = tokenizeTags(tokens);
    return tokens.toList();
  }

  static Iterable<MessageToken> _tokenizeEmotes(String message) sync* {
    var last = 0;
    for (final match in _emotePattern.allMatches(message)) {
      if (match.start > last) {
        yield TextToken(message.substring(last, match.start));
      }
      yield EmoteToken(
        url: kickEmoteUrl(match.group(1)!),
        code: match.group(2)!,
      );
      last = match.end;
    }
    if (last < message.length) {
      yield TextToken(message.substring(last));
    }
  }

  KickMessageModel withDeleted(bool deleted) => KickMessageModel(
    messageId: messageId,
    timestamp: timestamp,
    author: author,
    message: message,
    reply: reply,
    deleted: deleted,
    channelId: channelId,
  );
}
