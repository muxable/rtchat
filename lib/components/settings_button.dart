import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/audio.dart';
import 'package:rtchat/models/chat_history.dart';
import 'package:rtchat/models/layout.dart';
import 'package:rtchat/models/tts.dart';
import 'package:rtchat/models/user.dart';

enum _Value { layout, refreshAudio, settings, signOut }

class SettingsButtonWidget extends StatelessWidget {
  const SettingsButtonWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_Value>(
      onSelected: (value) async {
        switch (value) {
          case _Value.settings:
            await Navigator.pushNamed(context, "/settings");
            break;
          case _Value.refreshAudio:
            final audioModel = Provider.of<AudioModel>(context, listen: false);
            await audioModel.refreshAllSources();
            final count = audioModel.sources.length;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(count == 1
                    ? '1 audio source refreshsed'
                    : '$count audio sources refreshed')));
            break;
          case _Value.layout:
            final layoutModel =
                Provider.of<LayoutModel>(context, listen: false);
            layoutModel.locked = !layoutModel.locked;
            break;
          case _Value.signOut:
            await showDialog(
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
                        final chatHistoryModel = Provider.of<ChatHistoryModel>(
                            context,
                            listen: false);
                        await chatHistoryModel.subscribe({});
                        final ttsModel =
                            Provider.of<TtsModel>(context, listen: false);
                        ttsModel.enabled = false;
                        final userModel =
                            Provider.of<UserModel>(context, listen: false);
                        await userModel.signOut();
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                );
              },
            );
            break;
        }
      },
      itemBuilder: (context) {
        return [
          PopupMenuItem(
            value: _Value.layout,
            child:
                Consumer<LayoutModel>(builder: (context, layoutModel, child) {
              if (layoutModel.locked) {
                return const Text("Unlock Layout");
              }
              return const Text("Lock Layout");
            }),
          ),
          const PopupMenuItem(
              value: _Value.refreshAudio, child: Text("Refresh Audio Sources")),
          const PopupMenuItem(value: _Value.settings, child: Text("Settings")),
          const PopupMenuItem(value: _Value.signOut, child: Text("Sign Out")),
        ];
      },
    );
  }
}
