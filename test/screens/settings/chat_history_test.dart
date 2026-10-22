import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/layout.dart';
import 'package:rtchat/models/messages.dart';
import 'package:rtchat/models/messages/twitch/badge.dart';
import 'package:rtchat/models/style.dart';
import 'package:rtchat/models/user.dart';
import 'package:rtchat/screens/settings/chat_history.dart';

import '../../components/l10n.dart';
import '../../fakes/fake_user_model.dart';

void main() {
  late StyleModel styleModel;
  late MessagesModel messagesModel;

  setUp(() {
    styleModel = StyleModel.fromJson({});
    messagesModel = MessagesModel.fromJson({});
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    // tall enough that every option is on screen without scrolling.
    tester.view.physicalSize = const Size(800, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<StyleModel>.value(value: styleModel),
          ChangeNotifierProvider<MessagesModel>.value(value: messagesModel),
          ChangeNotifierProvider<UserModel>.value(value: FakeUserModel()),
          ChangeNotifierProvider<LayoutModel>.value(
            value: LayoutModel.fromJson({}),
          ),
          ChangeNotifierProvider<TwitchBadgeModel>.value(
            value: TwitchBadgeModel.fromJson({}),
          ),
        ],
        child: const MaterialApp(
          home: TestLocalizations(child: ChatHistoryScreen()),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('selecting a compact messages option updates the style model', (
    tester,
  ) async {
    await pumpScreen(tester);
    expect(styleModel.compactMessages, CompactMessages.none);

    final option = find.text('Compact individual messages');
    await tester.tap(option);
    await tester.pump();

    expect(styleModel.compactMessages, CompactMessages.withinMessage);

    await tester.tap(find.text('Don\'t compact messages'));
    await tester.pump();

    expect(styleModel.compactMessages, CompactMessages.none);
  });

  testWidgets('selecting an idle alert duration updates the messages model', (
    tester,
  ) async {
    await pumpScreen(tester);
    expect(messagesModel.pingMinGapDuration, const Duration(days: 10000));

    final option = find.text('5 minutes');
    await tester.tap(option);
    await tester.pump();

    expect(messagesModel.pingMinGapDuration, const Duration(minutes: 5));

    final group = tester.widget<RadioGroup<Duration>>(
      find.byType(RadioGroup<Duration>),
    );
    expect(group.groupValue, const Duration(minutes: 5));
  });

  testWidgets('all idle alert durations are listed', (tester) async {
    await pumpScreen(tester);
    for (final label in [
      'Disabled',
      '30 seconds',
      '1 minute',
      '5 minutes',
      '10 minutes',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
  });
}
