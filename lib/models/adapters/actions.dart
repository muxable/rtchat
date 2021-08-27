import 'package:cloud_functions/cloud_functions.dart';
import 'package:rtchat/models/channels.dart';

class ActionsAdapter {
  final FirebaseFunctions functions;

  ActionsAdapter._({required this.functions});

  ActionsAdapter get instance =>
      _instance ??= ActionsAdapter._(functions: FirebaseFunctions.instance);
  ActionsAdapter? _instance;

  Future<void> send(Channel channel, String message) async {
    final call = functions.httpsCallable('send');
    await call({
      "provider": channel.provider,
      "channelId": channel.channelId,
      "message": message,
    });
  }

  Future<void> ban(Channel channel, String username, String reason) async {
    final call = functions.httpsCallable('ban');
    await call({
      "provider": channel.provider,
      "channelId": channel.channelId,
      "username": username,
      "reason": reason,
    });
  }

  Future<void> unban(Channel channel, String username) async {
    final call = functions.httpsCallable('unban');
    await call({
      "provider": channel.provider,
      "channelId": channel.channelId,
      "username": username,
    });
  }

  Future<void> timeout(Channel channel, String username, String reason,
      Duration duration) async {
    final call = functions.httpsCallable('timeout');
    await call({
      "provider": channel.provider,
      "channelId": channel.channelId,
      "username": username,
      "reason": reason,
      "length": duration.inSeconds,
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
}
