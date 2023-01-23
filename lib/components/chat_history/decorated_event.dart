import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/image/cross_fade_image.dart';
import 'package:rtchat/components/image/resilient_network_image.dart';
import 'package:rtchat/models/style.dart';

class DecoratedEventWidget extends StatelessWidget {
  final Widget child;
  final Iterable<ImageProvider> avatars;
  final IconData? icon;
  final Color? accentColor;
  final BoxDecoration decoration;
  final EdgeInsets padding;

  const DecoratedEventWidget._(
      {Key? key,
      required this.child,
      this.avatars = const [],
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
          child: avatars.isEmpty && icon == null
              ? child
              : Consumer<StyleModel>(
                  builder: (context, styleModel, child) {
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
                                child: Builder(builder: (context) {
                                  if (avatars.isNotEmpty) {
                                    if (avatars.length == 1) {
                                      // short circuit for faster rendering.
                                      return ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                            styleModel.fontSize),
                                        child: CrossFadeImage(
                                            image: avatars.first,
                                            height: styleModel.fontSize * 1.5,
                                            width: styleModel.fontSize * 1.5),
                                      );
                                    }
                                    return Stack(
                                        children: avatars
                                            .toList()
                                            .asMap()
                                            .entries
                                            .map((entry) {
                                              final index = entry.key;
                                              final avatar = entry.value;
                                              return Padding(
                                                  padding: EdgeInsets.only(
                                                      left: index * 12),
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            styleModel
                                                                .fontSize),
                                                    child: CrossFadeImage(
                                                        placeholder: MemoryImage(
                                                            kTransparentImage),
                                                        image: avatar,
                                                        height: styleModel
                                                                .fontSize *
                                                            1.5,
                                                        width: styleModel
                                                                .fontSize *
                                                            1.5),
                                                  ));
                                            })
                                            .toList()
                                            .reversed
                                            .toList());
                                  }
                                  // icon is not empty by precondition.
                                  return Icon(icon,
                                      size: styleModel.fontSize * 1.5);
                                }),
                              ),
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

  DecoratedEventWidget.avatar(
      {Key? key,
      required Widget child,
      required ImageProvider avatar,
      BoxDecoration decoration = const BoxDecoration()})
      : this._(
            key: key, child: child, avatars: [avatar], decoration: decoration);

  const DecoratedEventWidget.avatars(
      {Key? key,
      required Widget child,
      required Iterable<ImageProvider> avatars,
      BoxDecoration decoration = const BoxDecoration()})
      : this._(
            key: key, child: child, avatars: avatars, decoration: decoration);

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
