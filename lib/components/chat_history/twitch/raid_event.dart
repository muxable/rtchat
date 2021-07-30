import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_image/flutter_image.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/message.dart';
import 'package:rtchat/models/style.dart';

class TwitchRaidEventWidget extends StatelessWidget {
  final TwitchRaidEventModel model;

  final NumberFormat _formatter = NumberFormat.decimalPattern();

  TwitchRaidEventWidget(this.model, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
          padding: const EdgeInsets.fromLTRB(12, 4, 16, 4),
          child: Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(styleModel.fontSize),
              child: Image(
                  image: NetworkImageWithRetry(model.profilePictureUrl),
                  height: styleModel.fontSize * 1.5),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(text: model.fromUsername, style: boldStyle),
                    TextSpan(
                        text: " is raiding with a party of ", style: baseStyle),
                    TextSpan(
                        text: _formatter.format(model.viewers),
                        style: boldStyle),
                    TextSpan(text: ".", style: baseStyle),
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
