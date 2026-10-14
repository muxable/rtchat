import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/messages/chat.dart';

/// A user whose messages text to speech skips, on any provider.
class MutedUser implements ChatUser {
  @override
  final String provider;
  @override
  final String userId;
  @override
  final String login;
  @override
  final String? displayName;

  const MutedUser(
      {required this.provider,
      required this.userId,
      required this.login,
      this.displayName});

  factory MutedUser.from(ChatUser user) => MutedUser(
      provider: user.provider,
      userId: user.userId,
      login: user.login,
      displayName: user.displayName);

  /// Muted users saved before other providers were supported are Twitch users.
  factory MutedUser.fromJson(Map<String, dynamic> json) => MutedUser(
      provider: json['provider'] ?? Providers.twitch,
      userId: json['userId'] ?? '',
      login: json['login'] ?? '',
      displayName: json['displayName']);

  Map<String, dynamic> toJson() => {
        'provider': provider,
        'userId': userId,
        'displayName': displayName,
        'login': login,
      };

  @override
  bool get isBot => false;

  /// Whether this is [user], matched by their stable login on the same
  /// provider.
  bool matches(ChatUser user) =>
      user.provider == provider &&
      user.login.toLowerCase() == login.toLowerCase();
}
