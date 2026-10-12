import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rtchat/main.dart';
import 'package:rtchat/screens/settings/chat_history.dart';
import 'package:streaming_shared_preferences/streaming_shared_preferences.dart';

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

Finder findRichText(String text) => find.byWidgetPredicate(
    (widget) => widget is RichText && widget.text.toPlainText().contains(text),
    description: 'RichText containing "$text"');

/// pumpAndSettle never settles here because the app has ongoing animations
/// and timers, so poll until the finder matches.
Future<void> pumpUntil(WidgetTester tester, Finder finder,
    {bool found = true, Duration timeout = const Duration(seconds: 30)}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isNotEmpty == found) {
      return;
    }
  }
  throw TestFailure(
      'Timed out waiting for $finder to be ${found ? 'found' : 'gone'}');
}

Future<StreamingSharedPreferences> freshPrefs() async {
  final prefs = await StreamingSharedPreferences.instance;
  await prefs.clear();
  return prefs;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final seeder = FirestoreSeeder();

  setUpAll(initializeFirebaseEmulators);

  setUp(() async {
    await FirebaseAuth.instance.signOut();
    await seeder.clear();
  });

  tearDownAll(seeder.close);

  testWidgets('signed out users see onboarding', (tester) async {
    await tester.pumpWidget(App(prefs: await freshPrefs()));

    await pumpUntil(tester, find.text('Continue as Guest'));
    expect(find.text('RealtimeChat'), findsOneWidget);
    expect(find.text('Sign in with Twitch'), findsOneWidget);
  });

  testWidgets('signed in users see live chat for their channel',
      (tester) async {
    final credential = await FirebaseAuth.instance.signInAnonymously();
    await seeder.setDocument('profiles/${credential.user!.uid}', {
      'twitch': {'id': channelId, 'displayName': 'e2estreamer'},
    });
    final start = DateTime.now().subtract(const Duration(minutes: 1));
    await seeder.setDocument(
        '$channelPath/history', chatMessage('hello from history', start));

    final prefs = await freshPrefs();
    await prefs.setString(
        'style', jsonEncode({'isDeletedMessagesVisible': false}));
    await tester.pumpWidget(App(prefs: prefs));

    await pumpUntil(tester, find.text('/e2estreamer'));
    await pumpUntil(tester, findRichText('hello from history'));

    // Messages written while the app is open stream in.
    await seeder.setDocument(
        '$channelPath/live', chatMessage('hello in real time', DateTime.now()));
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
    await tester.scrollUntilVisible(option, 200,
        scrollable: find
            .descendant(
                of: find.byType(ChatHistoryScreen),
                matching: find.byType(Scrollable))
            .first);
    await tester.tap(option);
    await tester.pump();

    final style =
        jsonDecode(prefs.getString('style', defaultValue: '{}').getValue())
            as Map;
    expect(style['compactMessages'], 1);
  });
}
