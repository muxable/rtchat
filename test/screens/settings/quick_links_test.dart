import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/quick_links.dart';
import 'package:rtchat/screens/settings/quick_links.dart';

import '../../components/l10n.dart';

void main() {
  late QuickLinksModel model;

  setUp(() {
    model = QuickLinksModel.fromJson({
      'sources': [
        for (final name in ['a', 'b', 'c'])
          {'icon': 'link', 'url': 'https://$name.example.com', 'label': name},
      ],
    });
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<QuickLinksModel>.value(
        value: model,
        child: const MaterialApp(
          home: TestLocalizations(child: QuickLinksScreen()),
        ),
      ),
    );
    await tester.pump();
  }

  List<String> labels() => model.sources.map((s) => s.label).toList();

  Future<void> longPressDrag(
    WidgetTester tester,
    String label,
    Offset offset,
  ) async {
    final gesture = await tester.startGesture(
      tester.getCenter(find.text(label)),
      kind: PointerDeviceKind.touch,
    );
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
    // move in small steps so the reorderable list tracks the drag.
    const steps = 10;
    for (var i = 0; i < steps; i++) {
      await gesture.moveBy(offset / steps.toDouble());
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pumpAndSettle();
  }

  testWidgets('lists all quick links', (tester) async {
    await pumpScreen(tester);
    for (final label in ['a', 'b', 'c']) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('dragging the first link to the end moves it last', (
    tester,
  ) async {
    await pumpScreen(tester);
    final height = tester.getSize(find.byType(ListTile).first).height;

    await longPressDrag(tester, 'a', Offset(0, height * 2.6));

    expect(labels(), ['b', 'c', 'a']);
  });

  testWidgets('dragging the last link to the top moves it first', (
    tester,
  ) async {
    await pumpScreen(tester);
    final height = tester.getSize(find.byType(ListTile).first).height;

    await longPressDrag(tester, 'c', Offset(0, -height * 2.6));

    expect(labels(), ['c', 'a', 'b']);
  });

  testWidgets('dragging a link down by one swaps it with its neighbour', (
    tester,
  ) async {
    await pumpScreen(tester);
    final height = tester.getSize(find.byType(ListTile).first).height;

    await longPressDrag(tester, 'a', Offset(0, height * 1.1));

    expect(labels(), ['b', 'a', 'c']);
  });
}
