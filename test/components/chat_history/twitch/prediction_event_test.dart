import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/chat_history/twitch/prediction_event.dart';
import 'package:rtchat/models/messages/twitch/prediction_event.dart';
import 'package:rtchat/models/style.dart';

void main() {
  testWidgets('started prediction should have title and 0 progress',
      (WidgetTester tester) async {
    final model = TwitchPredictionEventModel(
        timestamp: DateTime.now(),
        messageId: 'prediction1',
        title: 'Begin prediction',
        status: 'in_progress',
        endTime: DateTime.now(),
        outcomes: [
          TwitchPredictionOutcomeModel('outcome1', 0, 'pink', 'Heads'),
          TwitchPredictionOutcomeModel('outcome2', 0, 'blue', 'Tails')
        ]);
    await tester.pumpWidget(buildWidget(model));

    final findTitle = find.byWidgetPredicate((Widget widget) =>
        widget is RichText && widget.text.toPlainText() == 'Begin prediction');

    final findPinkOutcome = find.byWidgetPredicate((Widget widget) =>
        widget is RichText && widget.text.toPlainText() == 'Heads');

    final findBlueOutcome = find.byWidgetPredicate((Widget widget) =>
        widget is RichText && widget.text.toPlainText() == 'Tails');

    final findProgressIndicator = find.byType(LinearProgressIndicator);

    final findIcon = find.byIcon(Icons.emoji_events_outlined);

    expect(findTitle, findsOneWidget);
    expect(findPinkOutcome, findsOneWidget);
    expect(findBlueOutcome, findsOneWidget);
    expect(findIcon, findsNothing);
    expect(findProgressIndicator, findsNWidgets(2));
  });

  testWidgets('updated prediction should have over zero progress',
      (WidgetTester tester) async {
    final model = TwitchPredictionEventModel(
        timestamp: DateTime.now(),
        messageId: 'prediction1',
        title: 'In Progress prediction',
        status: 'in_progress',
        endTime: DateTime.now(),
        outcomes: [
          TwitchPredictionOutcomeModel('outcome1', 2, 'pink', 'Yay'),
          TwitchPredictionOutcomeModel('outcome2', 2, 'blue', 'Nay')
        ]);
    await tester.pumpWidget(buildWidget(model));

    final findTitle = find.byWidgetPredicate((Widget widget) =>
        widget is RichText &&
        widget.text.toPlainText() == 'In Progress prediction');

    final findPinkOutcome = find.byWidgetPredicate((Widget widget) =>
        widget is RichText && widget.text.toPlainText() == 'Yay');

    final findBlueOutcome = find.byWidgetPredicate((Widget widget) =>
        widget is RichText && widget.text.toPlainText() == 'Nay');

    final findPercentage = find.byWidgetPredicate((Widget widget) =>
        widget is RichText && widget.text.toPlainText() == '50%');

    final findProgressIndicator = find.byType(LinearProgressIndicator);

    final findIcon = find.byIcon(Icons.emoji_events_outlined);

    expect(findTitle, findsOneWidget);
    expect(findPinkOutcome, findsOneWidget);
    expect(findBlueOutcome, findsOneWidget);
    expect(findIcon, findsNothing);
    expect(findPercentage, findsNWidgets(2));
    expect(findProgressIndicator, findsNWidgets(2));
  });

  testWidgets(
      'resolved prediction should have over zero progress and winner icon',
      (WidgetTester tester) async {
    final model = TwitchPredictionEventModel(
        timestamp: DateTime.now(),
        messageId: 'prediction1',
        title: 'Resolved prediction',
        status: 'resolved',
        winningOutcomeId: 'outcome1',
        endTime: DateTime.now(),
        outcomes: [
          TwitchPredictionOutcomeModel('outcome1', 2, 'pink', 'Yes'),
          TwitchPredictionOutcomeModel('outcome2', 1, 'blue', 'No')
        ]);
    await tester.pumpWidget(buildWidget(model));

    final findTitle = find.byWidgetPredicate((Widget widget) =>
        widget is RichText &&
        widget.text.toPlainText() == 'Resolved prediction');

    final findPinkOutcome = find.byWidgetPredicate((Widget widget) =>
        widget is RichText && widget.text.toPlainText() == 'Yes');

    final findBlueOutcome = find.byWidgetPredicate((Widget widget) =>
        widget is RichText && widget.text.toPlainText() == 'No');

    final findProgressIndicator = find.byType(LinearProgressIndicator);

    final findIcon = find.byIcon(Icons.emoji_events_outlined);

    expect(findTitle, findsOneWidget);
    expect(findPinkOutcome, findsOneWidget);
    expect(findBlueOutcome, findsOneWidget);
    expect(findIcon, findsOneWidget);
    expect(findProgressIndicator, findsNWidgets(2));
  });

  testWidgets('canceled prediction should be empty',
      (WidgetTester tester) async {
    final model = TwitchPredictionEventModel(
        timestamp: DateTime.now(),
        messageId: 'prediction1',
        title: 'Unresolved prediction',
        status: 'canceled',
        endTime: DateTime.now(),
        outcomes: [
          TwitchPredictionOutcomeModel('outcome1', 1, 'pink', 'Yes'),
          TwitchPredictionOutcomeModel('outcome2', 1, 'blue', 'No')
        ]);
    await tester.pumpWidget(buildWidget(model));

    final findContainer = find.byType(Container);
    final findIcon = find.byIcon(Icons.emoji_events_outlined);

    expect(findContainer, findsOneWidget);
    expect(findIcon, findsNothing);
  });
}

ChangeNotifierProvider<StyleModel> buildWidget(
    TwitchPredictionEventModel model) {
  return ChangeNotifierProvider<StyleModel>.value(
    value: StyleModel.fromJson({
      'fontSize': 20.0,
      'lightnessBoost': 0.179,
      'isDeletedMessagesVisible': true
    }),
    child: Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
            data: const MediaQueryData(),
            child: TwitchPredictionEventWidget(model))),
  );
}
