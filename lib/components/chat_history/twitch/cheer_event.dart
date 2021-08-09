import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/messages/twitch/event.dart';
import 'package:rtchat/models/style.dart';

class TwitchCheerEventWidget extends StatelessWidget {
  final TwitchCheerEventModel model;
  final NumberFormat _formatter = NumberFormat.compactSimpleCurrency();

  TwitchCheerEventWidget(this.model, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var name = model.isAnonymous ? 'Anonymous' : model.giverName;
    return Consumer<StyleModel>(builder: (context, styleModel, child) {
      var boldStyle = Theme.of(context)
          .textTheme
          .bodyText2!
          .copyWith(fontSize: styleModel.fontSize, fontWeight: FontWeight.w500);
      var baseStyle = Theme.of(context)
          .textTheme
          .bodyText2!
          .copyWith(fontSize: styleModel.fontSize);
      return Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              width: 4,
              color: Theme.of(context).accentColor,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(1, 4, 16, 4),
          child: Row(children: [
            // ClipRRect(
            //   borderRadius: BorderRadius.circular(styleModel.fontSize),
            //   child: Image(
            //       image: NetworkImageWithRetry(model.profilePictureUrl),
            //       height: styleModel.fontSize * 1.5),
            // ),
            const SizedBox(width: 12),
            Expanded(
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(text: name, style: boldStyle),
                    TextSpan(text: " gifted you", style: baseStyle),
                    TextSpan(
                        text: " ${_formatter.format(model.bits)}",
                        style: boldStyle),
                    TextSpan(text: " bits.", style: baseStyle),
                    TextSpan(text: " ${model.cheerMessage}", style: baseStyle)
                  ],
                ),
              ),
            )
          ]),
        ),
      );
    });
  }
}
