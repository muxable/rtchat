import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/image/resilient_network_image.dart';
import 'package:rtchat/models/style.dart';

class DecoratedEventWidget extends StatelessWidget {
  final Widget child;
  final ImageProvider? avatar;
  final IconData? icon;
  final Color? accentColor;
  final BoxDecoration decoration;
  final EdgeInsets padding;

  const DecoratedEventWidget._(
      {Key? key,
      required this.child,
      this.avatar,
      this.icon,
      this.accentColor,
      this.padding = const EdgeInsets.fromLTRB(12, 4, 16, 4),
      this.decoration = const BoxDecoration()})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: decoration.copyWith(
        color: decoration.color ?? Theme.of(context).highlightColor,
        border: Border(
          left: BorderSide(
            width: 4,
            color: accentColor ?? Theme.of(context).colorScheme.secondary,
          ),
        ),
      ),
      child: Padding(
          padding: padding,
          child: Consumer<StyleModel>(
              builder: (context, styleModel, child) {
                if (avatar == null && icon == null) {
                  return child!;
                }
                // this complex chunk of change keeps:
                // 1. the text centered if there is one line + avatar aligned
                // 2. the avatar and text fit if there are two lines
                // 3. the avatar aligned to top if there are more than two lines
                return IntrinsicHeight(
                    child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                        alignment: Alignment.topLeft,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                              maxHeight: 2 * styleModel.fontSize),
                          child: Container(
                              alignment: Alignment.center,
                              child: (avatar != null)
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(
                                          styleModel.fontSize),
                                      child: FadeInImage(
                                          placeholder:
                                              MemoryImage(kTransparentImage),
                                          image: avatar!,
                                          height: styleModel.fontSize * 1.5,
                                          width: styleModel.fontSize * 1.5),
                                    )
                                  : Icon(icon,
                                      size: styleModel.fontSize * 1.5)),
                        )),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Align(
                            alignment: Alignment.centerLeft, child: child)),
                  ],
                ));
              },
              child: child)),
    );
  }

  Widget? get prefixWidget {
    return null;
  }

  const DecoratedEventWidget.avatar(
      {Key? key,
      required Widget child,
      required ImageProvider avatar,
      BoxDecoration decoration = const BoxDecoration()})
      : this._(key: key, child: child, avatar: avatar, decoration: decoration);

  const DecoratedEventWidget.icon(
      {Key? key, required Widget child, required IconData icon})
      : this._(key: key, child: child, icon: icon);

  const DecoratedEventWidget({
    Key? key,
    required Widget child,
    Color? accentColor,
    EdgeInsets padding = const EdgeInsets.fromLTRB(12, 4, 16, 4),
  }) : this._(
            key: key, child: child, accentColor: accentColor, padding: padding);
}
