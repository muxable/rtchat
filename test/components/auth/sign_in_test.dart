import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/components/auth/twitch.dart';
import 'package:rtchat/components/provider_icon.dart';

import '../l10n.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget button) async {
    await tester.pumpWidget(MaterialApp(
        home: TestLocalizations(child: Scaffold(body: Center(child: button)))));
    await tester.pumpAndSettle();
  }

  testWidgets("each provider has its own sign in label", (tester) async {
    await pump(tester, const SignInWithTwitch());
    expect(find.text("Sign in with Twitch"), findsOneWidget);

    await pump(tester, const SignInWithKick());
    expect(find.text("Sign in with Kick"), findsOneWidget);

    await pump(tester, const SignInWithYouTube());
    expect(find.text("Sign in with YouTube"), findsOneWidget);
  });

  testWidgets("youtube's button is youtube red with white text",
      (tester) async {
    await pump(tester, const SignInWithYouTube());
    final text = tester.widget<Text>(find.text("Sign in with YouTube"));
    expect(text.style?.color, Colors.white);
    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.style?.backgroundColor?.resolve({}), youTubeRed);
  });

  testWidgets("labels stay readable on kick's light green", (tester) async {
    await pump(tester, const SignInWithKick());
    final text = tester.widget<Text>(find.text("Sign in with Kick"));
    expect(text.style?.color, Colors.black);
  });
}
