import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/channel_search_dialog.dart';
import 'package:rtchat/models/audio.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/layout.dart';
import 'package:rtchat/models/quick_links.dart';
import 'package:rtchat/models/tts.dart';
import 'package:rtchat/models/user.dart';
import 'package:rtchat/screens/settings/quick_links.dart';
import 'package:url_launcher/url_launcher.dart';

class _ChannelPickerValue {
  final Channel? channel;
  final bool isAdd;

  const _ChannelPickerValue({this.channel, this.isAdd = false});
}

class RightDrawer extends StatelessWidget {
  final browser = ChromeSafariBrowser();

  RightDrawer({Key? key}) : super(key: key);

  void launchLink(QuickLinkSource source) async {
    final isWebUrl =
        source.url.scheme == 'http' || source.url.scheme == 'https';
    if (isWebUrl) {
      await browser.open(url: source.url);
    } else {
      await launch(source.url.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    print('rebuilding drawer');
    return Drawer(
      child: Column(
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 1, sigmaY: 2),
            child: Container(
              color: Colors.black.withOpacity(0),
            ),
          ),
          const SizedBox(
            height: 100,
          ),
          // channel
          Padding(
            padding: const EdgeInsets.only(left: 20, bottom: 8),
            child: _buildChannelListView(),
          ),
          const Divider(
            indent: 30,
            endIndent: 30,
            thickness: 2,
          ),

          // quicklinks title
          const Text("Quicklinks"),
          // quicklinks
          _buildQuicklinksListView(),

          const Divider(
            indent: 30,
            endIndent: 30,
            thickness: 2,
          ),

          // setting
          Consumer<LayoutModel>(builder: (context, layoutModel, child) {
            if (layoutModel.locked) {
              return ListTile(
                leading: const Icon(Icons.lock_open_outlined),
                title: const Text("lock Layout"),
                onTap: () async {
                  layoutModel.locked = !layoutModel.locked;
                  Navigator.pop(context);
                },
              );
            }
            return ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text("unlock Layout"),
              onTap: () async {
                layoutModel.locked = !layoutModel.locked;
                Navigator.pop(context);
              },
            );
          }),
          ListTile(
            leading: const Icon(Icons.refresh_outlined),
            title: const Text("refresh audio sources"),
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
            leading: Icon(Icons.settings_outlined),
            title: Text("setting"),
            onTap: () async {
              await Navigator.pushNamed(context, "/settings");
            },
          ),
          ListTile(
            leading: Icon(Icons.exit_to_app_outlined),
            iconColor: Colors.redAccent,
            title: Text("sign out"),
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

  Widget _buildChannelListView() {
    return Consumer<ChannelsModel>(builder: (context, channelsModel, child) {
      if (channelsModel.subscribedChannels.isEmpty) {
        return const Spacer();
      }
      final first = channelsModel.subscribedChannels.first;
      return Container(
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
      );
    });
  }

  Widget _buildQuicklinksListView() {
    return Consumer<QuickLinksModel>(
        builder: (context, quickLinksModel, child) {
      return Expanded(
        child: ListView(
          children: quickLinksModel.sources.reversed.map((source) {
            return ListTile(
              leading: Icon(quickLinksIconsMap[source.icon] ?? Icons.link),
              title: Text(source.toString()),
              onTap: () => launchLink(source),
            );
          }).toList(),
        ),
      );
    });
  }
}
