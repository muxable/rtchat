import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/chat_history/twitch/channel_point_event.dart';
import 'package:rtchat/models/messages/twitch/channel_point_redemption_event.dart';
import 'package:rtchat/models/style.dart';
import 'package:styled_text/styled_text.dart';

void main() {
  testWidgets(
      'fulfilled channel point redemption should have done icon and message',
      (WidgetTester tester) async {
    final model = TwitchChannelPointRedemptionEventModel(
        timestamp: DateTime.now(),
        messageId: "testMessageId",
        redeemerUsername: "automux",
        status: TwitchChannelPointRedemptionStatus.fulfilled,
        rewardName: "Sprint",
        rewardCost: 100,
        userInput: null);
    await tester.pumpWidget(buildWidget(model));

    final findText = find.byWidgetPredicate((Widget widget) {
      return widget is StyledText &&
          widget.text ==
              '<b>automux</b> redeemed <b>Sprint</b> for 100 points. ';
    });

    final findIcon = find.byIcon(Icons.done);

    expect(findText, findsOneWidget);
    expect(findIcon, findsOneWidget);
  });

  testWidgets(
      'unfulfilled channel point redemption should have timer icon and message',
      (WidgetTester tester) async {
    final model = TwitchChannelPointRedemptionEventModel(
        timestamp: DateTime.now(),
        messageId: "testMessageId",
        redeemerUsername: "automux",
        status: TwitchChannelPointRedemptionStatus.unfulfilled,
        rewardName: "WaTeER",
        rewardCost: 350,
        userInput: "user input Kappa");
    await tester.pumpWidget(buildWidget(model));

    final findText = find.byWidgetPredicate((Widget widget) {
      return widget is StyledText &&
          widget.text ==
              '<b>automux</b> redeemed <b>WaTeER</b> for 350 points. user input Kappa';
    });

    final findIcon = find.byIcon(Icons.timer);

    expect(findText, findsOneWidget);
    expect(findIcon, findsOneWidget);
  });
}

ChangeNotifierProvider<StyleModel> buildWidget(
    TwitchChannelPointRedemptionEventModel model) {
  return ChangeNotifierProvider<StyleModel>.value(
    value: StyleModel.fromJson({
      "fontSize": 20.0,
      "lightnessBoost": 0.179,
      "isDeletedMessagesVisible": true
    }),
    child: Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
            data: const MediaQueryData(),
            child: TwitchChannelPointRedemptionEventWidget(model))),
  );
}
