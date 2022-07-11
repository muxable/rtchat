import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/chat_history/twitch/prediction_event.dart';
import 'package:rtchat/models/messages/twitch/prediction_event.dart';
import 'package:rtchat/models/style.dart';

void main() {
  testWidgets('minimized prediction should include title',
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

    final titleFinder = find.text('Prediction - Begin prediction');
    final iconFinder = find.byIcon(Icons.expand_more);

    expect(titleFinder, findsOneWidget);
    expect(iconFinder, findsOneWidget);
  });

  testWidgets('expanded started prediction should have title and 0 progress',
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

    // Expand the tile
    await tester.tap(find.byType(ListTile));
    await tester.pump();

    final titleFinder = find.text('Prediction - Begin prediction');

    final iconFinder = find.byIcon(Icons.expand_more);

    final findPinkOutcome = find.text('Heads');

    final findBlueOutcome = find.text('Tails');

    final findProgressIndicator = find.byType(LinearProgressIndicator);

    final findIcon = find.byIcon(Icons.emoji_events_outlined);

    expect(titleFinder, findsOneWidget);
    expect(iconFinder, findsOneWidget);
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

    // Expand the tile
    await tester.tap(find.byType(ListTile));
    await tester.pump();

    final findTitle = find.text('Prediction - In Progress prediction');

    final findPinkOutcome = find.text('Yay');

    final findBlueOutcome = find.text('Nay');

    final findPercentage = find.text('50%');

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

    // Expand the tile
    await tester.tap(find.byType(ListTile));
    await tester.pump();

    final findTitle = find.text('Prediction - Resolved prediction');

    final findPinkOutcome = find.text('Yes');

    final findBlueOutcome = find.text('No');

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
            child: Scaffold(body: TwitchPredictionEventWidget(model)))),
  );
}
