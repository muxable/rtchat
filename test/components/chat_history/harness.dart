import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/style.dart';

import '../l10n.dart';

/// Wraps a chat history widget with the localizations, theme and style model
/// that event widgets depend on.
Widget buildEventWidget(Widget child) {
  return ChangeNotifierProvider<StyleModel>.value(
    value: StyleModel.fromJson({}),
    child: MaterialApp(
      home: TestLocalizations(child: Material(child: child)),
    ),
  );
}

/// Finds rich text (e.g. from StyledText) whose plain text matches [text].
Finder findRichText(String text) => find.byWidgetPredicate(
    (widget) => widget is RichText && widget.text.toPlainText() == text);

/// Pumps [widget] and waits for localizations to load.
Future<void> pumpEvent(WidgetTester tester, Widget widget) async {
  await tester.pumpWidget(widget);
  await tester.pumpAndSettle();
}
