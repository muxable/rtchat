import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
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
          final fontFamily = Platform.isIOS
              ? Typography.whiteCupertino.bodyText2!.fontFamily
              : Typography.whiteMountainView.bodyText2!.fontFamily;
          final themeData = theme.copyWith(
              textTheme: theme.textTheme.apply(
                  fontSizeDelta: model.fontSize - 14, fontFamily: fontFamily));
          return Theme(
              data: themeData,
              child: DefaultTextStyle(
                  style: themeData.textTheme.bodyText2!, child: child!));
        },
        child: child);
  }
}
