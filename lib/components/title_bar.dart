import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/user.dart';

class TitleBarWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<UserModel>(builder: (context, userModel, child) {
      if (userModel.channels.isEmpty) {
        return Text("RealtimeChat");
      }
      // TODO: Implement multi-channel rendering.
      final channel = userModel.channels.first;
      return Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.only(right: 8),
              child: Image(
                  height: 24,
                  image:
                      AssetImage('assets/providers/${channel.provider}.png')),
            ),
            Text("/${channel.displayName}", overflow: TextOverflow.fade),
          ]);
    });
  }
}
