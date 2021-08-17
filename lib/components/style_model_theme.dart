import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/style.dart';

class StyleModelTheme extends StatelessWidget {
  final Widget child;

  const StyleModelTheme({required this.child, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<StyleModel>(
        builder: (context, model, child) {
          final theme = Theme.of(context);
          final themeData = theme.copyWith(
            textTheme:
                theme.textTheme.apply(fontSizeDelta: model.fontSize - 14),
          );

          return Theme(
              data: themeData,
              child: DefaultTextStyle(
                  style: themeData.textTheme.bodyText2!, child: child!));
        },
        child: child);
  }
}
