import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rtchat/components/channel_attribution.dart';
import 'package:rtchat/components/message_input.dart';
import 'package:rtchat/main.dart';
import 'package:rtchat/models/accounts.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/screens/settings/chat_history.dart';
import 'package:rtchat/tts_foreground_service.dart';
import 'package:streaming_shared_preferences/streaming_shared_preferences.dart';

import 'callable_stub.dart';
import 'emulator.dart';

const channelId = '1234';
const channelPath = 'channels/twitch:$channelId/messages';

Map<String, dynamic> chatMessage(String text, DateTime timestamp) => {
  'type': 'message',
  'channelId': 'twitch:$channelId',
  'message': text,
  'timestamp': timestamp,
  'tags': {
    'user-id': '42',
    'display-name': 'E2EViewer',
    'username': 'e2eviewer',
    'color': '#00FF00',
  },
  'annotations': {'isAction': false, 'isFirstTimeChatter': false},
};

const kickChannelId = '5678';
const kickChannelPath = 'channels/kick:$kickChannelId/messages';

/// A Kick chat message as the backend's webhook stores it.
Map<String, dynamic> kickChatMessage(String text, DateTime timestamp) => {
  'type': 'kick.chat.message.sent',
  'channelId': 'kick:$kickChannelId',
  'timestamp': timestamp,
  'event': {
    'message_id': text,
    'broadcaster': {'user_id': int.parse(kickChannelId)},
    'sender': {
      'user_id': 99,
      'username': 'KickViewer',
      'channel_slug': 'kickviewer',
      'identity': {'username_color': '#53FC18', 'badges': []},
    },
    'content': text,
    'emotes': [],
  },
};

Finder findRichText(String text) => find.byWidgetPredicate(
  (widget) => widget is RichText && widget.text.toPlainText().contains(text),
  description: 'RichText containing "$text"',
);

/// pumpAndSettle never settles here because the app has ongoing animations
/// and timers, so poll until the finder matches.
Future<void> pumpUntil(
  WidgetTester tester,
  Finder finder, {
  bool found = true,
  Duration timeout = const Duration(seconds: 30),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isNotEmpty == found) {
      return;
    }
  }
  throw TestFailure(
    'Timed out waiting for $finder to be ${found ? 'found' : 'gone'}',
  );
}

Future<StreamingSharedPreferences> freshPrefs() async {
  final prefs = await StreamingSharedPreferences.instance;
  await prefs.clear();
  return prefs;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final seeder = FirestoreSeeder();
  late CallableStub callables;

  setUpAll(() async {
    await initializeFirebaseEmulators();
    callables = await CallableStub.start(callableHost, callablePort);
  });

  setUp(() async {
    await signOutEverywhere();
    await seeder.clear();
    callables.reset();
  });

  tearDownAll(() async {
    seeder.close();
    await callables.close();
  });

  testWidgets('signed out users see onboarding', (tester) async {
    await tester.pumpWidget(App(prefs: await freshPrefs()));

    await pumpUntil(tester, find.text('Continue as Guest'));
    expect(find.text('RealtimeChat'), findsOneWidget);
    expect(find.text('Sign in with Twitch'), findsOneWidget);
  });

  testWidgets('signed in users see live chat for their channel', (
    tester,
  ) async {
    final credential = await FirebaseAuth.instance.signInAnonymously();
    await seeder.setDocument('profiles/${credential.user!.uid}', {
      'twitch': {'id': channelId, 'displayName': 'e2estreamer'},
    });
    final start = DateTime.now().subtract(const Duration(minutes: 1));
    await seeder.setDocument(
      '$channelPath/history',
      chatMessage('hello from history', start),
    );

    final prefs = await freshPrefs();
    await prefs.setString(
      'style',
      jsonEncode({'isDeletedMessagesVisible': false}),
    );
    await tester.pumpWidget(App(prefs: prefs));

    await pumpUntil(tester, find.text('/e2estreamer'));
    await pumpUntil(tester, findRichText('hello from history'));

    // Messages written while the app is open stream in.
    await seeder.setDocument(
      '$channelPath/live',
      chatMessage('hello in real time', DateTime.now()),
    );
    await pumpUntil(tester, findRichText('hello in real time'));

    // A moderator deleting the message hides it.
    await seeder.setDocument('$channelPath/live-deleted', {
      'type': 'messagedeleted',
      'channelId': 'twitch:$channelId',
      'messageId': 'live',
      'timestamp': DateTime.now(),
    });
    await pumpUntil(tester, findRichText('hello in real time'), found: false);
    expect(findRichText('hello from history'), findsOneWidget);
  });

  testWidgets('chat history settings persist', (tester) async {
    final credential = await FirebaseAuth.instance.signInAnonymously();
    await seeder.setDocument('profiles/${credential.user!.uid}', {
      'twitch': {'id': channelId, 'displayName': 'e2estreamer'},
    });

    final prefs = await freshPrefs();
    await tester.pumpWidget(App(prefs: prefs));
    await pumpUntil(tester, find.text('/e2estreamer'));

    navigatorKey.currentState!.pushNamed('/settings/chat-history');
    await pumpUntil(tester, find.byType(ChatHistoryScreen));
    // the option is below the fold, and ListView only builds visible items.
    final option = find.text('Compact individual messages');
    await tester.scrollUntilVisible(
      option,
      200,
      scrollable:
          find
              .descendant(
                of: find.byType(ChatHistoryScreen),
                matching: find.byType(Scrollable),
              )
              .first,
    );
    await tester.tap(option);
    await tester.pump();

    final style =
        jsonDecode(prefs.getString('style', defaultValue: '{}').getValue())
            as Map;
    expect(style['compactMessages'], 1);
  });

  testWidgets(
    'text to speech keeps a foreground service running',
    skip: !Platform.isAndroid,
    (tester) async {
      final credential = await FirebaseAuth.instance.signInAnonymously();
      await seeder.setDocument('profiles/${credential.user!.uid}', {
        'twitch': {'id': channelId, 'displayName': 'e2estreamer'},
      });
      await tester.pumpWidget(App(prefs: await freshPrefs()));
      await pumpUntil(tester, find.text('/e2estreamer'));

      Future<bool> isRunning() async =>
          await TtsForegroundService.channel.invokeMethod<bool>('isRunning') ??
          false;
      Future<void> waitFor(bool running) async {
        final end = DateTime.now().add(const Duration(seconds: 15));
        while (await isRunning() != running) {
          if (DateTime.now().isAfter(end)) {
            throw TestFailure('tts service running != $running');
          }
          await tester.pump(const Duration(milliseconds: 250));
        }
      }

      expect(await isRunning(), isFalse);

      final toggle = find.byTooltip('Text to speech');
      await tester.tap(toggle);
      await waitFor(true);

      await tester.tap(toggle);
      await waitFor(false);
    },
  );

  testWidgets('signed out users can view twitch and kick chat together', (
    tester,
  ) async {
    // default channels are saved on the device and need no account.
    final prefs = await freshPrefs();
    await prefs.setString(
      'views',
      jsonEncode({
        'defaultChannels': [
          {
            'provider': 'twitch',
            'channelId': channelId,
            'displayName': 'e2estreamer',
          },
          {
            'provider': 'kick',
            'channelId': kickChannelId,
            'displayName': 'E2EKick',
          },
        ],
      }),
    );
    final start = DateTime.now().subtract(const Duration(minutes: 5));
    await seeder.setDocument(
      '$channelPath/t1',
      chatMessage('twitch first', start),
    );
    await seeder.setDocument(
      '$kickChannelPath/k1',
      kickChatMessage('kick second', start.add(const Duration(minutes: 1))),
    );
    await seeder.setDocument(
      '$channelPath/t2',
      chatMessage('twitch third', start.add(const Duration(minutes: 2))),
    );

    await tester.pumpWidget(App(prefs: prefs));

    await pumpUntil(tester, find.text('/e2estreamer +1'));
    await pumpUntil(tester, findRichText('kick second'));
    await pumpUntil(tester, findRichText('twitch first'));
    await pumpUntil(tester, findRichText('twitch third'));

    // messages are merged in time order (the chat list is bottom-up).
    final positions =
        [
          'twitch first',
          'kick second',
          'twitch third',
        ].map((text) => tester.getCenter(findRichText(text).first).dy).toList();
    expect(positions[0], lessThan(positions[1]));
    expect(positions[1], lessThan(positions[2]));

    // each message shows where it came from.
    expect(find.byType(ChannelAttribution), findsWidgets);

    // clearing twitch chat doesn't clear kick chat.
    await seeder.setDocument('$channelPath/clear', {
      'type': 'clear',
      'channelId': 'twitch:$channelId',
      'timestamp': DateTime.now(),
    });
    await pumpUntil(tester, findRichText('twitch first'), found: false);
    expect(findRichText('kick second'), findsOneWidget);
  });

  group('signed in to twitch and kick at once', () {
    late String twitchUid;
    late String kickUid;

    final picker = find.descendant(
      of: find.byType(MessageInputWidget),
      matching: find.byType(PopupMenuButton<Channel>),
    );

    Map<String, dynamic> sendData(String provider, String id, String text) => {
      'provider': provider,
      'channelId': id,
      'message': text,
    };

    /// Signs in a Twitch account on [DEFAULT] and a Kick account on its own
    /// slot, each its own user, then opens the app.
    Future<void> openSignedInToBoth(WidgetTester tester) async {
      twitchUid = (await FirebaseAuth.instance.signInAnonymously()).user!.uid;
      await seeder.setDocument('profiles/$twitchUid', {
        'twitch': {'id': channelId, 'displayName': 'e2estreamer'},
      });
      final kickAuth = FirebaseAuth.instanceFor(
        app: Firebase.app(accountAppName(Providers.kick)),
      );
      kickUid = (await kickAuth.signInAnonymously()).user!.uid;
      await seeder.setDocument('profiles/$kickUid', {
        'kick': {'id': kickChannelId, 'displayName': 'E2EKick'},
      });
      expect(kickUid, isNot(twitchUid));

      await tester.pumpWidget(App(prefs: await freshPrefs()));
      await pumpUntil(tester, find.text('/e2estreamer +1'));
      await pumpUntil(tester, picker);
    }

    /// Waits for [count] calls to [name], then a little longer to catch any
    /// extra ones, and returns them.
    Future<List<CallableCall>> callsTo(
      WidgetTester tester,
      String name,
      int count,
    ) async {
      final end = DateTime.now().add(const Duration(seconds: 30));
      while (callables.callsTo(name).length < count) {
        if (DateTime.now().isAfter(end)) {
          throw TestFailure(
            'expected $count $name calls, got '
            '${callables.callsTo(name)}',
          );
        }
        await tester.pump(const Duration(milliseconds: 250));
      }
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
      return callables.callsTo(name);
    }

    Future<void> type(WidgetTester tester, String text) => tester.enterText(
      find.descendant(
        of: find.byType(MessageInputWidget),
        matching: find.byType(TextField),
      ),
      text,
    );

    testWidgets('both own channels show by default', (tester) async {
      final start = DateTime.now().subtract(const Duration(minutes: 1));
      await seeder.setDocument(
        '$channelPath/t1',
        chatMessage('twitch hello', start),
      );
      await seeder.setDocument(
        '$kickChannelPath/k1',
        kickChatMessage('kick hello', start),
      );

      await openSignedInToBoth(tester);
      await pumpUntil(tester, findRichText('twitch hello'));
      await pumpUntil(tester, findRichText('kick hello'));

      // the picker starts on the first account's channel.
      expect(picker, findsOneWidget);
      expect(
        tester.widget<PopupMenuButton<Channel>>(picker).initialValue,
        Channel(Providers.twitch, channelId, 'e2estreamer'),
      );
      expect(find.text('Send a message to e2estreamer...'), findsOneWidget);

      // the sidebar names both accounts.
      tester.state<ScaffoldState>(find.byType(Scaffold).first).openDrawer();
      await pumpUntil(tester, find.text('e2estreamer, E2EKick'));
      expect(find.text('Twitch · Kick'), findsOneWidget);
    });

    testWidgets('sending reaches only the selected channel, as its account', (
      tester,
    ) async {
      await openSignedInToBoth(tester);

      await type(tester, 'hello twitch');
      await tester.tap(find.byIcon(Icons.send_rounded));

      final calls = await callsTo(tester, 'send', 1);
      expect(calls, hasLength(1));
      expect(calls.single.uid, twitchUid);
      expect(calls.single.data, sendData('twitch', channelId, 'hello twitch'));
    });

    testWidgets('picking the other channel sends only there, as its account', (
      tester,
    ) async {
      await openSignedInToBoth(tester);

      await tester.tap(picker);
      final kickItem = find.descendant(
        of: find.byType(PopupMenuItem<Channel>),
        matching: find.text('E2EKick'),
      );
      await pumpUntil(tester, kickItem);
      await tester.tap(kickItem);
      await pumpUntil(tester, find.text('Send a message to E2EKick...'));

      await type(tester, 'hello kick');
      await tester.tap(find.byIcon(Icons.send_rounded));

      final calls = await callsTo(tester, 'send', 1);
      expect(calls, hasLength(1));
      expect(calls.single.uid, kickUid);
      expect(calls.single.data, sendData('kick', kickChannelId, 'hello kick'));
    });

    testWidgets('a failed send shows the backend error', (tester) async {
      await openSignedInToBoth(tester);

      // the backend answers with the reason a message wasn't sent.
      callables.respond(
        'send',
        'You are banned in this channel',
        uid: twitchUid,
      );
      await type(tester, 'rejected');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await pumpUntil(tester, find.text('You are banned in this channel'));
      expect(callables.callsTo('send').single.uid, twitchUid);

      // a call that fails outright is retried, then reported.
      ScaffoldMessenger.of(
        tester.element(find.byType(MessageInputWidget)),
      ).removeCurrentSnackBar();
      await pumpUntil(
        tester,
        find.text('You are banned in this channel'),
        found: false,
      );
      callables.fail('send', uid: twitchUid);
      await type(tester, 'unreachable');
      await tester.tap(find.byIcon(Icons.send_rounded));
      // the first send, then three tries of this one.
      final calls = await callsTo(tester, 'send', 4);
      await pumpUntil(tester, find.textContaining('Failed to send message'));
      expect(calls, hasLength(4));
      expect(calls.every((call) => call.uid == twitchUid), isTrue);
      expect(calls.map((call) => call.data['provider']).toSet(), {'twitch'});
    });

    testWidgets('moderating acts as the account whose channel it is', (
      tester,
    ) async {
      final start = DateTime.now().subtract(const Duration(minutes: 1));
      await seeder.setDocument(
        '$kickChannelPath/k1',
        kickChatMessage('kick spam', start),
      );
      await seeder.setDocument(
        '$channelPath/t1',
        chatMessage('twitch spam', start.add(const Duration(seconds: 1))),
      );
      await openSignedInToBoth(tester);

      Future<void> delete(String text) async {
        await pumpUntil(tester, findRichText(text));
        await tester.longPress(findRichText(text).first);
        await pumpUntil(tester, find.text('Delete Message'));
        await tester.tap(find.text('Delete Message'));
        await pumpUntil(tester, find.text('Delete Message'), found: false);
      }

      await delete('kick spam');
      var calls = await callsTo(tester, 'deleteMessage', 1);
      expect(calls.single.uid, kickUid);
      expect(calls.single.data, containsPair('provider', 'kick'));
      expect(calls.single.data, containsPair('channelId', kickChannelId));

      await delete('twitch spam');
      calls = await callsTo(tester, 'deleteMessage', 2);
      expect(calls, hasLength(2));
      expect(calls.last.uid, twitchUid);
      expect(calls.last.data, containsPair('provider', 'twitch'));
      expect(calls.last.data, containsPair('channelId', channelId));
    });

    testWidgets('signing out of one account leaves the other working', (
      tester,
    ) async {
      await openSignedInToBoth(tester);

      navigatorKey.currentState!.pushNamed('/settings/accounts');
      final kickTile = find.widgetWithText(ListTile, 'E2EKick');
      await pumpUntil(tester, kickTile);
      expect(find.widgetWithText(ListTile, 'e2estreamer'), findsOneWidget);
      // let the kick avatar finish loading (the emulated channel has none),
      // or its error is reported once the tile is gone.
      final avatar =
          Channel(Providers.kick, kickChannelId, 'E2EKick').profilePicture;
      final end = DateTime.now().add(const Duration(seconds: 30));
      do {
        await tester.pump(const Duration(milliseconds: 250));
      } while (PaintingBinding.instance.imageCache
              .statusForKey(avatar)
              .pending &&
          DateTime.now().isBefore(end));
      await tester.tap(
        find.descendant(of: kickTile, matching: find.byTooltip('Sign out')),
      );
      final confirm = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(TextButton, 'Sign out'),
      );
      await pumpUntil(tester, confirm);
      await tester.tap(confirm);
      await pumpUntil(tester, kickTile, found: false);
      await pumpUntil(tester, find.byType(AlertDialog), found: false);

      // only the kick slot was signed out.
      expect(
        FirebaseAuth.instanceFor(
          app: Firebase.app(accountAppName(Providers.kick)),
        ).currentUser,
        isNull,
      );
      expect(FirebaseAuth.instance.currentUser?.uid, twitchUid);
      expect(find.widgetWithText(ListTile, 'e2estreamer'), findsOneWidget);
      callables.reset();

      navigatorKey.currentState!.pop();
      // kick can't be sent to anymore, so there's nothing to pick.
      await pumpUntil(tester, picker, found: false);
      await pumpUntil(tester, find.text('/e2estreamer'));

      await type(tester, 'still here');
      await tester.tap(find.byIcon(Icons.send_rounded));
      final calls = await callsTo(tester, 'send', 1);
      expect(calls, hasLength(1));
      expect(calls.single.uid, twitchUid);
      expect(calls.single.data, sendData('twitch', channelId, 'still here'));
      // nothing is called as the signed-out account anymore.
      expect(callables.calls.where((call) => call.uid == kickUid), isEmpty);
    });
  });
}
