import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/layout.dart';
import 'package:rtchat/models/message.dart';

class TwitchRaidEventWidget extends StatelessWidget {
  final TwitchRaidEventModel model;

  final NumberFormat _formatter = NumberFormat.decimalPattern();

  TwitchRaidEventWidget(this.model);

  @override
  Widget build(BuildContext context) {
    return Consumer<LayoutModel>(builder: (context, layoutModel, child) {
      var boldStyle = Theme.of(context).textTheme.bodyText2!.copyWith(
          fontSize: layoutModel.fontSize, fontWeight: FontWeight.w500);
      var baseStyle = Theme.of(context)
          .textTheme
          .bodyText2!
          .copyWith(fontSize: layoutModel.fontSize);
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
          padding: EdgeInsets.fromLTRB(12, 4, 16, 4),
          child: Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(layoutModel.fontSize),
              child: Image(
                  image: NetworkImage(model.profilePictureUrl),
                  height: layoutModel.fontSize * 1.5),
            ),
            SizedBox(width: 12),
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
