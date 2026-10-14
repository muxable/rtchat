import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/models/adapters/actions.dart';
import 'package:rtchat/models/channels.dart';

import '../../fakes/fake_functions.dart';

final youtube = Channel(Providers.youtube, 'UCaaaaaaaaaaaaaaaaaaaaaa', 'me');

void main() {
  test('sends to youtube through the send callable', () async {
    final send = FakeCallable((_) async => null);
    final actions = ActionsAdapter.withFunctions(FakeFunctions({'send': send}));
    expect(await actions.send(youtube, 'hello'), isNull);
    expect(send.calls.single, {
      'provider': 'youtube',
      'channelId': 'UCaaaaaaaaaaaaaaaaaaaaaa',
      'message': 'hello',
    });
  });

  test('shows quota errors once instead of retrying', () async {
    final send = FakeCallable((_) async => throw youTubeQuotaError());
    final actions = ActionsAdapter.withFunctions(FakeFunctions({'send': send}));
    expect(await actions.send(youtube, 'hello'), youTubeQuotaMessage);
    expect(send.calls, hasLength(1));
  });

  test('only errors written for the user are shown', () {
    expect(userFacingError(youTubeQuotaError()), youTubeQuotaMessage);
    expect(
        userFacingError(FirebaseFunctionsException(
            code: 'failed-precondition',
            message: "This YouTube channel isn't live.")),
        "This YouTube channel isn't live.");
    expect(
        userFacingError(
            FirebaseFunctionsException(code: 'internal', message: 'INTERNAL')),
        isNull);
    expect(userFacingError(Exception('offline')), isNull);
  });

  test('youtube moderation goes through the shared callables', () async {
    final delete = FakeCallable((_) async => null);
    final ban = FakeCallable((_) async => null);
    final timeout = FakeCallable((_) async => null);
    final actions = ActionsAdapter.withFunctions(FakeFunctions(
        {'deleteMessage': delete, 'ban': ban, 'timeout': timeout}));
    await actions.delete(youtube, 'youtube:LCC.1');
    await actions.ban(youtube, '@viewer', userId: 'UCbbbbbbbbbbbbbbbbbbbbbb');
    await actions.timeout(
        youtube, '@viewer', 'timed out by streamer', const Duration(minutes: 5),
        userId: 'UCbbbbbbbbbbbbbbbbbbbbbb');
    expect(delete.calls.single['messageId'], 'youtube:LCC.1');
    expect(ban.calls.single['userId'], 'UCbbbbbbbbbbbbbbbbbbbbbb');
    expect(timeout.calls.single['length'], 300);
    expect(timeout.calls.single['provider'], 'youtube');
  });
}
