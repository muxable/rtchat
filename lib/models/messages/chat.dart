import 'package:rtchat/models/messages/message.dart';
import 'package:rtchat/models/messages/tokens.dart';

/// Someone chatting, on any provider.
abstract interface class ChatUser {
  /// The provider this user belongs to, e.g. [Providers.twitch].
  String get provider;

  String get userId;

  /// The user's stable, lowercase handle on [provider].
  String get login;

  String? get displayName;

  /// Whether this is a known chat bot.
  bool get isBot;
}

/// A chat message, on any provider.
///
/// Consumers that only need what's common to every provider (rendering text,
/// compaction, text to speech, muting) should depend on this rather than a
/// provider's model.
abstract interface class ChatMessage implements MessageModel {
  ChatUser get author;

  /// The raw message text.
  String get message;

  /// [message] split into text, emotes, mentions and links.
  List<MessageToken> get tokenized;

  /// Whether the message is an action (`/me`).
  bool get isAction;

  /// Whether the message is a chat command, e.g. `!discord`.
  bool get isCommand;

  bool get deleted;

  /// Whether the author is subscribed to the channel.
  bool get isSubscriber;
}

extension ChatUserName on ChatUser {
  /// The name to show for this user.
  String get name => displayName ?? login;
}
