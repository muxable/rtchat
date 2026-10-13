import 'package:rtchat/models/messages/chat.dart';
import 'package:rtchat/models/messages/message.dart';
import 'package:rtchat/models/messages/tokens.dart';

/// A chat user from a provider the app has no special handling for, used to
/// check that consumers only depend on [ChatUser].
class FakeChatUser implements ChatUser {
  @override
  final String provider;
  @override
  final String userId;
  @override
  final String login;
  @override
  final String? displayName;
  @override
  final bool isBot;

  const FakeChatUser(
      {this.provider = 'fake',
      required this.userId,
      required this.login,
      this.displayName,
      this.isBot = false});
}

class FakeChatMessage extends MessageModel implements ChatMessage {
  @override
  final FakeChatUser author;
  @override
  final String message;
  @override
  final bool isAction;
  @override
  final bool deleted;
  @override
  final bool isSubscriber;

  const FakeChatMessage(
      {required super.messageId,
      required super.timestamp,
      required this.author,
      required this.message,
      this.isAction = false,
      this.deleted = false,
      this.isSubscriber = false});

  @override
  bool get isCommand => !isAction && message.startsWith("!");

  @override
  List<MessageToken> get tokenized => [TextToken(message)];
}
