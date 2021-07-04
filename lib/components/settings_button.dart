import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/chat_history.dart';
import 'package:rtchat/models/layout.dart';
import 'package:rtchat/models/tts.dart';
import 'package:rtchat/models/user.dart';

class SettingsButtonWidget extends StatelessWidget {
  const SettingsButtonWidget({Key? key}) : super(key: key);

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
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Sign Out'),
                    content: const Text('Are you sure you want to sign out?'),
                    actions: [
                      TextButton(
                        child: const Text('Cancel'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      TextButton(
                        child: const Text('Sign Out'),
                        onPressed: () async {
                          final chatHistoryModel =
                              Provider.of<ChatHistoryModel>(context,
                                  listen: false);
                          await chatHistoryModel.subscribe({});
                          final ttsModel =
                              Provider.of<TtsModel>(context, listen: false);
                          ttsModel.enabled = false;
                          await userModel.signOut();
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
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
