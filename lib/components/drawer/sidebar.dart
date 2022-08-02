import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/channel_search_bottom_sheet.dart';
import 'package:rtchat/components/drawer/quicklinks_listview.dart';
import 'package:rtchat/components/image/resilient_network_image.dart';
import 'package:rtchat/models/adapters/actions.dart';
import 'package:rtchat/models/audio.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/layout.dart';
import 'package:rtchat/models/user.dart';

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.tertiary,
      child: SafeArea(
        child: SizedBox(
          height: 96,
          child: Consumer<UserModel>(builder: (context, model, child) {
            final userChannel = model.userChannel;
            return DrawerHeader(
              margin: EdgeInsets.zero,
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10.0),
                      onTap: () {
                        if (model.activeChannel != userChannel) {
                          model.activeChannel = userChannel;
                        }
                        Navigator.of(context).pop();
                      },
                      child: Row(children: [
                        CircleAvatar(
                          backgroundImage: userChannel != null
                              ? ResilientNetworkImage(
                                  userChannel.profilePictureUrl)
                              : null,
                          backgroundColor: Colors.transparent,
                        ),
                        const SizedBox(width: 16),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(userChannel?.displayName ?? "Not signed in",
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyText1
                                    ?.copyWith(color: Colors.white)),
                            const SizedBox(height: 8),
                            Text("twitch.tv",
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyText2
                                    ?.copyWith(color: Colors.white)),
                          ],
                        ),
                      ]),
                    ),
                  ),
                  VerticalDivider(
                    width: 4,
                    thickness: 2,
                    indent: 8,
                    endIndent: 8,
                    color: Theme.of(context)
                        .colorScheme
                        .onTertiary
                        .withOpacity(0.1),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search),
                    iconSize: 32,
                    splashRadius: 24,
                    tooltip: 'Search channels',
                    color: Theme.of(context).colorScheme.onTertiary,
                    onPressed: () {
                      Navigator.of(context).pop();
                      showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        builder: (context) {
                          return DraggableScrollableSheet(
                            initialChildSize: 0.8,
                            maxChildSize: 0.9,
                            expand: false,
                            builder: (context, controller) {
                              return ChannelSearchBottomSheetWidget(
                                onChannelSelect: (channel) {
                                  model.activeChannel = channel;
                                },
                                onRaid: userChannel == model.activeChannel &&
                                        userChannel != null
                                    ? (channel) {
                                        ActionsAdapter.instance.send(
                                          userChannel,
                                          "/raid ${channel.displayName}",
                                        );
                                      }
                                    : null,
                                controller: controller,
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}

class Sidebar extends StatefulWidget {
  final Channel channel;

  const Sidebar({required this.channel, Key? key}) : super(key: key);

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      ListTile(
          leading: const Icon(Icons.add_link_sharp),
          title: const Text("Configure quick links"),
          onTap: () =>
              Navigator.of(context).pushNamed("/settings/quick-links")),

      const Divider(),

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
      Consumer<AudioModel>(builder: (context, audioModel, child) {
        if (audioModel.sources.isEmpty) {
          return Container();
        }
        return ListTile(
          leading: const Icon(Icons.cached_outlined),
          title: const Text("Refresh audio sources"),
          onTap: () async {
            final count = await audioModel.refreshAllSources();
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(count == 1
                    ? '1 audio source refreshed'
                    : '$count audio sources refreshed')));
          },
        );
      }),
      ListTile(
        leading: const Icon(Icons.build_outlined),
        title: const Text("Settings"),
        onTap: () async {
          await Navigator.pushNamed(context, "/settings");
        },
      ),
      Consumer<UserModel>(builder: (context, model, child) {
        if (!model.isSignedIn()) {
          return Container();
        }
        return ListTile(
          leading: const Icon(Icons.logout_outlined),
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
                        await Provider.of<UserModel>(context, listen: false)
                            .signOut();
                        if (!mounted) return;
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                );
              },
            );
          },
        );
      }),
    ];
    return Drawer(
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const _DrawerHeader(),

            // quicklinks
            Expanded(child: Builder(builder: (context) {
              final orientation = MediaQuery.of(context).orientation;
              if (orientation == Orientation.portrait) {
                return Column(children: [
                  Expanded(child: ListView(children: [QuicklinksListView()])),
                  ...tiles
                ]);
              } else {
                return ListView(children: [QuicklinksListView(), ...tiles]);
              }
            }))
          ],
        ),
      ),
    );
  }
}
