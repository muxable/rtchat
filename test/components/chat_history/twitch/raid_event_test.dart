import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/api.dart';
import 'package:rtchat/components/chat_history/twitch/raid_event.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/messages/twitch/event.dart';
import 'package:rtchat/models/messages/twitch/eventsub_configuration.dart';
import 'package:rtchat/models/messages/twitch/user.dart';
import 'package:rtchat/models/user.dart';

import '../../../fakes/fake_accounts.dart';
import '../../../fakes/fake_api.dart';
import '../../../fakes/fake_user_model.dart';
import '../harness.dart';

final channel = Channel(Providers.twitch, '43', 'streamer');

final raid = TwitchRaidEventModel(
  timestamp: DateTime(2025),
  messageId: 'raid',
  from: const TwitchUserModel(
    userId: '158394109',
    login: 'automux',
    displayName: 'automux',
  ),
  viewers: 10,
);

void main() {
  late FakeFunctions api;
  late UserModel userModel;

  setUp(() {
    final account = fakeAccount(channel, appName: '[DEFAULT]');
    api = fakeApiFor(account);
    userModel = FakeUserModel(accounts: [account]);
  });

  tearDown(Api.debugReset);

  Future<void> pump(WidgetTester tester, {required bool enabled}) async {
    final config = EventSubConfigurationModel.fromJson({})
      ..setRaidEventEnableShoutoutButton(enabled);
    await pumpEvent(
      tester,
      MultiProvider(
        providers: [
          ChangeNotifierProvider<UserModel>.value(value: userModel),
          ChangeNotifierProvider<EventSubConfigurationModel>.value(
            value: config,
          ),
        ],
        child: buildEventWidget(TwitchRaidEventWidget(raid, channel: channel)),
      ),
    );
  }

  testWidgets('the shoutout button gives the raider a shoutout', (
    tester,
  ) async {
    await pump(tester, enabled: true);
    await tester.tap(find.text('Shoutout'));
    await tester.pumpAndSettle();

    expect(api.calls.single.name, 'shoutout');
    expect(api.calls.single.data, {
      'provider': Providers.twitch,
      'fromChannelId': '43',
      'toChannelId': '158394109',
    });
  });

  testWidgets('the shoutout button is hidden unless enabled', (tester) async {
    await pump(tester, enabled: false);
    expect(find.text('Shoutout'), findsNothing);
  });
}
