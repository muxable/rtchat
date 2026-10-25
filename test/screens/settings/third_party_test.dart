import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/accounts.dart';
import 'package:rtchat/models/adapters/donations.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/user.dart';
import 'package:rtchat/screens/settings/third_party.dart';

import '../../fakes/fake_accounts.dart';
import '../../fakes/fake_user_model.dart';

/// One account's connections: Streamlabs is connected when [streamlabs].
class FakeDonations extends Fake implements DonationsAdapter {
  final Account account;
  final bool streamlabs;
  final reads = <String>[];

  final realtimeKitKeys = <String, String>{};

  @override
  Stream<RealtimeKitConfig?> forRealtimeKitConfig({required String userId}) {
    return Stream.value(
      realtimeKitKeys[userId] == null
          ? null
          : RealtimeKitConfig(apiKey: realtimeKitKeys[userId]!),
    );
  }

  @override
  Future<void> setRealtimeKitApiKey({required String apiKey}) async {
    realtimeKitKeys[account.user.uid] = apiKey;
  }

  FakeDonations(this.account, {this.streamlabs = false});

  @override
  Stream<String?> forRealtimeChatAddress({required String userId}) {
    reads.add(userId);
    return Stream.value(null);
  }

  @override
  Stream<StreamlabsConfig?> forStreamlabsConfig({required String userId}) {
    reads.add(userId);
    return Stream.value(streamlabs ? StreamlabsConfig() : null);
  }

  @override
  Stream<StreamElementsConfig?> forStreamElementsConfig({
    required String userId,
  }) {
    reads.add(userId);
    return Stream.value(null);
  }
}

final twitchChannel = Channel(Providers.twitch, '1', 'TwitchMux');
final kickChannel = Channel(Providers.kick, '2', 'KickMux');

void main() {
  late Account twitch, kick;
  late Map<String, FakeDonations> donations;
  late List<Uri> opened;

  setUp(() {
    twitch = fakeAccount(twitchChannel, appName: '[DEFAULT]');
    kick = fakeAccount(kickChannel);
    donations = {
      twitch.provider: FakeDonations(twitch),
      kick.provider: FakeDonations(kick, streamlabs: true),
    };
    opened = [];
  });

  Future<void> pump(WidgetTester tester, List<Account> accounts) async {
    // tall enough to build every section.
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ChangeNotifierProvider<UserModel>.value(
        value: FakeUserModel(accounts: accounts),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ThirdPartyScreen(
            donations: (account) => donations[account.provider]!,
            authenticate: (url) async {
              opened.add(url);
              return 'com.rtirl.chat://?token=connected';
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('one account has no account sections', (tester) async {
    await pump(tester, [twitch]);

    expect(find.text('Streamlabs'), findsOneWidget);
    expect(find.text('TwitchMux'), findsNothing);
    expect(find.text('RealtimeKit'), findsOneWidget);
    expect(donations[Providers.twitch]!.reads, everyElement(twitch.user.uid));
  });

  testWidgets('each account has its own section', (tester) async {
    await pump(tester, [twitch, kick]);

    expect(find.text('TwitchMux'), findsOneWidget);
    expect(find.text('KickMux'), findsOneWidget);
    expect(find.text('Streamlabs'), findsNWidgets(2));
    expect(find.text('StreamElements'), findsNWidgets(2));
    expect(find.text('RealtimeKit'), findsNWidgets(2));

    // each section reads its own account's connections.
    expect(donations[Providers.twitch]!.reads, everyElement(twitch.user.uid));
    expect(donations[Providers.kick]!.reads, everyElement(kick.user.uid));
    expect(donations[Providers.kick]!.reads, isNotEmpty);

    // only kick's Streamlabs is connected.
    final streamlabs = find.ancestor(
      of: find.text('Streamlabs'),
      matching: find.byType(ListTile),
    );
    expect(
      find.descendant(
        of: streamlabs.first,
        matching: find.byIcon(Icons.check_circle),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: streamlabs.last,
        matching: find.byIcon(Icons.check_circle),
      ),
      findsOneWidget,
    );
  });

  testWidgets('connecting signs in as the section\'s account', (tester) async {
    await pump(tester, [twitch, kick]);

    await tester.tap(find.text('Streamlabs').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('StreamElements').first);
    await tester.pumpAndSettle();

    expect(opened, [
      Uri.https('chat.rtirl.com', '/auth/streamlabs/redirect', {
        'token': 'id-token-${kick.user.uid}',
        'provider': 'kick',
      }),
      Uri.https('chat.rtirl.com', '/auth/streamelements/redirect', {
        'token': 'id-token-${twitch.user.uid}',
        'provider': 'twitch',
      }),
    ]);
  });
}
