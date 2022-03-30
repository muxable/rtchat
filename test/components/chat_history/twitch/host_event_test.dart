import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/chat_history/twitch/host_event.dart';
import 'package:rtchat/models/messages/twitch/event.dart';
import 'package:rtchat/models/messages/twitch/user.dart';
import 'package:rtchat/models/style.dart';

void main() {
  AutomatedTestWidgetsFlutterBinding();
  HttpOverrides.global = null;
  testWidgets('host event should have channel name and viewer count',
      (WidgetTester tester) async {
    final model = TwitchHostEventModel(
      timestamp: DateTime.now(),
      messageId: "testMessageId",
      from: const TwitchUserModel(
          userId: '158394109', login: "automux", displayName: "automux"),
      viewers: 10,
    );
    await tester.pumpWidget(buildWidget(model));

    final findText = find.byWidgetPredicate((Widget widget) =>
        widget is RichText &&
        widget.text.toPlainText() == "automux is hosting with a party of 10.");

    expect(findText, findsOneWidget);
  });
}

ChangeNotifierProvider<StyleModel> buildWidget(TwitchHostEventModel model) {
  return ChangeNotifierProvider<StyleModel>.value(
    value: StyleModel.fromJson({
      "fontSize": 20.0,
      "lightnessBoost": 0.179,
      "isDeletedMessagesVisible": true
    }),
    child: Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
            data: const MediaQueryData(), child: TwitchHostEventWidget(model))),
  );
}
