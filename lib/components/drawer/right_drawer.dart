import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/channel_search_dialog.dart';
import 'package:rtchat/components/drawer/quicklinks_listview.dart';
import 'package:rtchat/models/audio.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/layout.dart';
import 'package:rtchat/models/tts.dart';
import 'package:rtchat/models/user.dart';

class _ChannelPickerValue {
  final Channel? channel;
  final bool isAdd;

  const _ChannelPickerValue({this.channel, this.isAdd = false});
}

class RightDrawer extends StatelessWidget {
  const RightDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final channelsModel = Provider.of<ChannelsModel>(context, listen: false);
    final first = channelsModel.subscribedChannels.first;
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              color: Colors.black.withOpacity(0),
            ),
          ),
          SizedBox(
            height: 128,
            child: DrawerHeader(
              padding: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 20,
                  top: 8,
                  bottom: 8,
                ),
                child: PopupMenuButton<_ChannelPickerValue>(
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Image(
                                height: 24,
                                image: AssetImage(
                                    'assets/providers/${first.provider}.png')),
                          ),
                          Expanded(
                            child: Text("/${first.displayName}",
                                softWrap: false, overflow: TextOverflow.fade),
                          ),
                        ]),
                    onSelected: (value) async {
                      if (value.isAdd) {
                        // show the search dialog.
                        await showDialog(
                          context: context,
                          builder: (context) =>
                              ChannelSearchDialog(onSelect: (channel) {
                            channelsModel.subscribedChannels = {channel};
                            Navigator.pop(context);
                          }),
                        );
                      } else {
                        channelsModel.subscribedChannels = {value.channel!};
                      }
                    },
                    itemBuilder: (context) {
                      return [
                        ...channelsModel.availableChannels.map((channel) {
                          return PopupMenuItem(
                              value: _ChannelPickerValue(channel: channel),
                              child: ListTile(
                                title: Text(channel.displayName),
                              ));
                        }),
                        const PopupMenuItem(
                            value: _ChannelPickerValue(isAdd: true),
                            child: ListTile(
                                title: Text("Find a channel"),
                                leading: Icon(Icons.add)))
                      ];
                    }),
              ),
            ),
          ),

          // quicklinks
          QuicklinksListView(),

          const Divider(
            indent: 30,
            endIndent: 30,
            thickness: 2,
          ),

          // setting
          Consumer<LayoutModel>(builder: (context, layoutModel, child) {
            if (!layoutModel.locked) {
              return ListTile(
                leading: const Icon(Icons.lock_open_outlined),
                title: const Text("Lock layout"),
                onTap: () async {
                  layoutModel.locked = !layoutModel.locked;
                  Navigator.pop(context);
                },
              );
            }
            return ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text("Unlock layout"),
              onTap: () async {
                layoutModel.locked = !layoutModel.locked;
                Navigator.pop(context);
              },
            );
          }),
          ListTile(
            leading: const Icon(Icons.refresh_outlined),
            title: const Text("Refresh audio sources"),
            onTap: () async {
              final audioModel =
                  Provider.of<AudioModel>(context, listen: false);
              final count = await audioModel.refreshAllSources();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(count == 1
                      ? '1 audio source refreshed'
                      : '$count audio sources refreshed')));
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text("Settings"),
            onTap: () async {
              await Navigator.pushNamed(context, "/settings");
            },
          ),
          ListTile(
            leading: const Icon(Icons.exit_to_app_outlined),
            iconColor: Colors.redAccent,
            title: const Text("Sign out"),
            onTap: () async {
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
                          final channelsModel = Provider.of<ChannelsModel>(
                              context,
                              listen: false);
                          channelsModel.subscribedChannels = {};
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
            },
          ),
          const SizedBox(
            height: 16,
          )
        ],
      ),
    );
  }
}
