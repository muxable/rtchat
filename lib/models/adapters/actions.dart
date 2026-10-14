import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:rtchat/models/channels.dart';

class ActionsAdapter {
  final FirebaseFunctions functions;

  ActionsAdapter._({required this.functions});

  static ActionsAdapter get instance =>
      _instance ??= ActionsAdapter._(functions: FirebaseFunctions.instance);
  static ActionsAdapter? _instance;

  Future<String?> send(Channel channel, String message) async {
    final call = functions.httpsCallable('send');
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
    final call = functions.httpsCallable('ban');
    await call({
      "provider": channel.provider,
      "channelId": channel.channelId,
      "username": username,
      if (userId != null) "userId": userId,
    });
  }

  Future<void> unban(Channel channel, String username, {String? userId}) async {
    final call = functions.httpsCallable('unban');
    await call({
      "provider": channel.provider,
      "channelId": channel.channelId,
      "username": username,
      if (userId != null) "userId": userId,
    });
  }

  Future<void> timeout(
      Channel channel, String username, String reason, Duration duration,
      {String? userId}) async {
    final call = functions.httpsCallable('timeout');
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
    final call = functions.httpsCallable('deleteMessage');
    await call({
      "provider": channel.provider,
      "channelId": channel.channelId,
      "messageId": messageId,
    });
  }

  Future<void> raid(Channel fromChannel, Channel toChannel) async {
    if (fromChannel.provider != toChannel.provider) {
      throw ArgumentError(
          "Cannot raid between channels of different providers");
    }
    final call = functions.httpsCallable('raid');
    await call({
      "provider": fromChannel.provider,
      "fromChannelId": fromChannel.channelId,
      "toChannelId": toChannel.channelId,
    });
  }

  Future<void> cancelRaid(Channel channel) async {
    final call = functions.httpsCallable('cancelRaid');
    await call({
      "provider": channel.provider,
      "channelId": channel.channelId,
    });
  }
}
