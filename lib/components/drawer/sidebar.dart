import 'package:flutter/material.dart';
import 'package:flutter_image/flutter_image.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/drawer/quicklinks_listview.dart';
import 'package:rtchat/models/audio.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/layout.dart';
import 'package:rtchat/models/user.dart';

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        height: 129,
        color: Theme.of(context).primaryColor,
        child: Consumer<UserModel>(
          builder: (context, model, child) {
            final userChannel = model.userChannel;
            return DrawerHeader(
                margin: EdgeInsets.zero,
                child: Row(children: [
                  CircleAvatar(
                      backgroundImage: userChannel != null
                          ? NetworkImageWithRetry(userChannel.profilePictureUrl)
                          : null),
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
                      ]),
                ]));
          },
        ));
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
          leading: const Icon(Icons.add),
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
          leading: const Icon(Icons.refresh_outlined),
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
        leading: const Icon(Icons.settings_outlined),
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
    );
  }
}
