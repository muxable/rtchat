import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:rtchat/api.dart';
import 'package:flutter/foundation.dart';
import 'package:rtchat/models/channels.dart';

class ActionsAdapter {
  final Api api;

  ActionsAdapter._({required this.api});

  @visibleForTesting
  ActionsAdapter.withFunctions(FirebaseFunctions functions)
      : api = Api(functions);

  static ActionsAdapter get instance =>
      _instance ??= ActionsAdapter._(api: Api.instance);
  static ActionsAdapter? _instance;

  @visibleForTesting
  static set instance(ActionsAdapter? adapter) => _instance = adapter;

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
        final error = userFacingError(e);
        if (error != null) {
          return error;
        }
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
      Channel channel, String username, String reason, Duration duration,
      {String? userId}) async {
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
          "Cannot raid between channels of different providers");
    }
    final call = api.callable('raid');
    await call({
      "provider": fromChannel.provider,
      "fromChannelId": fromChannel.channelId,
      "toChannelId": toChannel.channelId,
    });
  }

  Future<void> cancelRaid(Channel channel) async {
    final call = api.callable('cancelRaid');
    await call({
      "provider": channel.provider,
      "channelId": channel.channelId,
    });
  }
}

/// Callable errors whose message is written for the user, like YouTube's quota
/// running out or the chat having ended. Retrying them only repeats the error.
const _userFacingErrorCodes = {
  'failed-precondition',
  'invalid-argument',
  'not-found',
  'permission-denied',
  'resource-exhausted',
  'unauthenticated',
};

/// The message to show for [error], or null if it isn't meant for the user.
String? userFacingError(Object error) {
  if (error is FirebaseFunctionsException &&
      _userFacingErrorCodes.contains(error.code)) {
    return error.message ?? error.code;
  }
  return null;
}
