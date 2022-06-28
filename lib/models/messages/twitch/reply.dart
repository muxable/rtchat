import 'package:rtchat/models/messages/twitch/user.dart';

class TwitchMessageReplyModel {
  final String messageId;
  final String message;
  final TwitchUserModel author;

  TwitchMessageReplyModel(
      {required this.messageId, required this.message, required this.author});
}
