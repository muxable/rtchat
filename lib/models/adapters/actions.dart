import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:rtchat/api.dart';
import 'package:rtchat/models/accounts.dart';
import 'package:rtchat/models/channels.dart';

class ActionsAdapter {
  final Api api;

  ActionsAdapter(this.api);

  /// Acts as [account]. The backend sends and moderates with the token of
  /// the account it's called as, so this must be the one on the channel's
  /// provider.
  factory ActionsAdapter.forAccount(Account account) =>
      ActionsAdapter(Api.forAccount(account));

  Future<String?> send(Channel channel, String message) async {
    final call = api.callable('send');
    for (var i = 0; i < 3; i++) {
      try {
        final result = await call({
          "provider": channel.provider,
          "channelId": channel.channelId,
          "message": message,
        });
        return result.data;
      } catch (e) {
        FirebaseCrashlytics.instance.recordError(e, StackTrace.current);
      }
    }
    throw Exception("Failed to send message");
  }

  Future<void> ban(Channel channel, String username, {String? userId}) async {
    final call = api.callable('ban');
    await call({
      "provider": channel.provider,
      "channelId": channel.channelId,
      "username": username,
      if (userId != null) "userId": userId,
    });
  }

  Future<void> unban(Channel channel, String username, {String? userId}) async {
    final call = api.callable('unban');
    await call({
      "provider": channel.provider,
      "channelId": channel.channelId,
      "username": username,
      if (userId != null) "userId": userId,
    });
  }

  Future<void> timeout(
    Channel channel,
    String username,
    String reason,
    Duration duration, {
    String? userId,
  }) async {
    final call = api.callable('timeout');
    await call({
      "provider": channel.provider,
      "channelId": channel.channelId,
      "username": username,
      "reason": reason,
      "length": duration.inSeconds,
      if (userId != null) "userId": userId,
    });
  }

  Future<void> delete(Channel channel, String messageId) async {
    final call = api.callable('deleteMessage');
    await call({
      "provider": channel.provider,
      "channelId": channel.channelId,
      "messageId": messageId,
    });
  }

  Future<void> raid(Channel fromChannel, Channel toChannel) async {
    if (fromChannel.provider != toChannel.provider) {
      throw ArgumentError(
        "Cannot raid between channels of different providers",
      );
    }
    final call = api.callable('raid');
    await call({
      "provider": fromChannel.provider,
      "fromChannelId": fromChannel.channelId,
      "toChannelId": toChannel.channelId,
    });
  }

  /// Gives [toChannelId] a shoutout in [channel], moderating as this account.
  Future<void> shoutout(Channel channel, String toChannelId) async {
    final call = api.callable('shoutout');
    await call({
      "provider": channel.provider,
      "fromChannelId": channel.channelId,
      "toChannelId": toChannelId,
    });
  }

  Future<void> cancelRaid(Channel channel) async {
    final call = api.callable('cancelRaid');
    await call({"provider": channel.provider, "channelId": channel.channelId});
  }
}
