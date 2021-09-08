import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/style.dart';

class DecoratedEventWidget extends StatelessWidget {
  final Widget child;
  final ImageProvider? avatar;
  final IconData? icon;

  const DecoratedEventWidget._(
      {Key? key, required this.child, this.avatar, this.icon})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).highlightColor,
        border: Border(
          left: BorderSide(
            width: 4,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
      ),
      child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 16, 4),
          child: Builder(builder: (context) {
            if (avatar != null) {
              return Row(
                children: [
                  Consumer<StyleModel>(builder: (context, styleModel, child) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(styleModel.fontSize),
                      child: Image(
                          image: avatar!,
                          height: styleModel.fontSize * 1.5,
                          width: styleModel.fontSize * 1.5),
                    );
                  }),
                  const SizedBox(width: 12),
                  Expanded(child: child),
                ],
              );
            } else if (icon != null) {
              return Row(
                children: [
                  Consumer<StyleModel>(builder: (context, styleModel, child) {
                    return Consumer<StyleModel>(
                        builder: (context, styleModel, child) =>
                            Icon(icon!, size: styleModel.fontSize * 1.5));
                  }),
                  const SizedBox(width: 12),
                  Expanded(child: child),
                ],
              );
            }
            return child;
          })),
    );
  }

  Widget? get prefixWidget {}

  const DecoratedEventWidget.avatar(
      {Key? key, required Widget child, required ImageProvider avatar})
      : this._(key: key, child: child, avatar: avatar);

  const DecoratedEventWidget.icon(
      {Key? key, required Widget child, required IconData icon})
      : this._(key: key, child: child, icon: icon);

  const DecoratedEventWidget({Key? key, required Widget child})
      : this._(key: key, child: child);
}
