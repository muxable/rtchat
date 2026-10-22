import 'package:rtchat/models/messages/chat.dart';
import 'package:rtchat/models/messages/message.dart';
import 'package:rtchat/models/messages/tokens.dart';
import 'package:rtchat/models/messages/twitch/message.dart'
    show tokenizeLinks, tokenizeTags;
import 'package:rtchat/models/messages/youtube/user.dart';

/// A YouTube `textMessageEvent`.
class YouTubeMessageModel extends MessageModel implements ChatMessage {
  @override
  final YouTubeUserModel author;
  @override
  final String message;
  @override
  final bool deleted;

  /// The channel the message was sent to, e.g. `youtube:UC...`.
  final String channelId;

  YouTubeMessageModel(
      {required super.messageId,
      required super.timestamp,
      required this.author,
      required this.message,
      this.deleted = false,
      required this.channelId});

  @override
  bool get isAction => false;

  @override
  bool get isCommand => message.startsWith("!");

  @override
  bool get isSubscriber => author.isChatSponsor;

  @override
  List<MessageToken> get tokenized => _tokenized ??= tokenize();
  List<MessageToken>? _tokenized;

  // YouTube emoji arrive as `:shortcode:` text, which is left as is.
  List<MessageToken> tokenize() =>
      tokenizeTags(tokenizeLinks([TextToken(message)])).toList();

  YouTubeMessageModel withDeleted(bool deleted) => YouTubeMessageModel(
      messageId: messageId,
      timestamp: timestamp,
      author: author,
      message: message,
      deleted: deleted,
      channelId: channelId);
}
