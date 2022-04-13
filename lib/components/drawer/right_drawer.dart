import 'package:flutter/material.dart';
import 'package:flutter_image/flutter_image.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/drawer/quicklinks_listview.dart';
import 'package:rtchat/models/audio.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/layout.dart';
import 'package:rtchat/models/user.dart';

class RightDrawer extends StatelessWidget {
  final Channel channel;

  const RightDrawer({required this.channel, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Consumer<UserModel>(
            builder: (context, model, child) {
              if (!model.isSignedIn()) {
                return const UserAccountsDrawerHeader(
                    accountName: Text("Not signed in"),
                    accountEmail: Text("twitch.tv"));
              }
              return UserAccountsDrawerHeader(
                  currentAccountPicture: CircleAvatar(
                      backgroundImage: NetworkImageWithRetry(
                          model.userChannel!.profilePictureUrl)),
                  accountName: Text(model.userChannel!.displayName),
                  accountEmail: const Text("twitch.tv"));
            },
          ),

          // quicklinks
          Expanded(child: QuicklinksListView()),

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
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            );
          }),
        ],
      ),
    );
  }
}
