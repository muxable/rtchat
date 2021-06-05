import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/chat_history.dart';
import 'package:rtchat/models/layout.dart';
import 'package:rtchat/models/user.dart';

class SettingsButtonWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<UserModel>(builder: (context, userModel, child) {
      return Consumer<LayoutModel>(builder: (context, layoutModel, child) {
        return PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == "Settings") {
              Navigator.pushNamed(context, "/settings");
            } else if (value == "Lock Layout" || value == "Unlock Layout") {
              layoutModel.locked = !layoutModel.locked;
            } else if (value == "Sign Out") {
              await Provider.of<ChatHistoryModel>(context, listen: false)
                  .subscribe({});
              userModel.signOut();
            }
          },
          itemBuilder: (context) {
            final options = {
              layoutModel.locked ? "Unlock Layout" : "Lock Layout",
              'Settings',
              'Sign Out'
            };
            return options.map((String choice) {
              return PopupMenuItem<String>(
                value: choice,
                child: Text(choice),
              );
            }).toList();
          },
        );
      });
    });
  }
}
