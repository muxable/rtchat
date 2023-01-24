import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/channel_search_bottom_sheet.dart';
import 'package:rtchat/components/drawer/quicklinks_listview.dart';
import 'package:rtchat/components/image/cross_fade_image.dart';
import 'package:rtchat/models/adapters/actions.dart';
import 'package:rtchat/models/audio.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/layout.dart';
import 'package:rtchat/models/user.dart';
import 'package:rtchat/urls.dart';

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.tertiary,
      child: SafeArea(
        child: SizedBox(
          height: 146,
          child: DrawerHeader(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  GestureDetector(
                      onTap: () => openUrl(Uri.parse("https://muxable.com")),
                      child: SizedBox(
                          height: 50,
                          child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Image.asset("assets/muxable.png")))),
                  const Divider(),
                  Row(
                    children: [
                      Expanded(
                        child: Consumer<UserModel>(
                            builder: (context, model, child) {
                          final userChannel = model.userChannel;
                          return InkWell(
                            borderRadius: BorderRadius.circular(10.0),
                            onTap: () {
                              if (model.activeChannel != userChannel) {
                                model.activeChannel = userChannel;
                              }
                              Navigator.of(context).pop();
                            },
                            child: Row(children: [
                              if (userChannel != null)
                                const SizedBox(width: 16),
                              if (userChannel != null)
                                ClipRRect(
                                    borderRadius: BorderRadius.circular(24),
                                    child: CrossFadeImage(
                                        placeholder: userChannel
                                            .profilePicture.placeholderImage,
                                        image: userChannel.profilePicture,
                                        height: 36,
                                        width: 36)),
                              const SizedBox(width: 16),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      userChannel?.displayName ??
                                          "Not signed in",
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(color: Colors.white)),
                                  const SizedBox(height: 8),
                                  Text("twitch.tv",
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(color: Colors.white)),
                                ],
                              ),
                            ]),
                          );
                        }),
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
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: IconButton(
                          icon: const Icon(Icons.search),
                          iconSize: 32,
                          splashRadius: 24,
                          tooltip: AppLocalizations.of(context)!.searchChannels,
                          color: Theme.of(context).colorScheme.onTertiary,
                          onPressed: () {
                            Navigator.of(context).pop();
                            FirebaseAnalytics.instance.logEvent(
                                name: 'search_channels', parameters: null);
                            showModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(16)),
                              ),
                              builder: (context) {
                                return DraggableScrollableSheet(
                                  initialChildSize: 0.8,
                                  maxChildSize: 0.9,
                                  expand: false,
                                  builder: (context, controller) {
                                    final model = Provider.of<UserModel>(
                                        context,
                                        listen: false);
                                    final userChannel = model.userChannel;
                                    return ChannelSearchBottomSheetWidget(
                                      onChannelSelect: (channel) {
                                        model.activeChannel = channel;
                                      },
                                      onRaid:
                                          userChannel == model.activeChannel &&
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
                      ),
                    ],
                  ),
                ],
              )),
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
          title: Text(AppLocalizations.of(context)!.configureQuickLinks),
          onTap: () =>
              Navigator.of(context).pushNamed("/settings/quick-links")),

      const Divider(),

      // setting
      Consumer<LayoutModel>(builder: (context, layoutModel, child) {
        if (!layoutModel.locked) {
          return ListTile(
            leading: const Icon(Icons.thunderstorm),
            title: Text(AppLocalizations.of(context)!.enableRainMode),
            subtitle:
                Text(AppLocalizations.of(context)!.enableRainModeSubtitle),
            onTap: () async {
              layoutModel.locked = !layoutModel.locked;
              Navigator.pop(context);
            },
          );
        }
        return ListTile(
          leading: const Icon(Icons.thunderstorm),
          title: Text(AppLocalizations.of(context)!.disableRainMode),
          subtitle: Text(AppLocalizations.of(context)!.disableRainModeSubtitle),
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
          title: Text(AppLocalizations.of(context)!.refreshAudioSources),
          onTap: () async {
            final count = await audioModel.refreshAllSources();
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(AppLocalizations.of(context)!
                    .refreshAudioSourcesCount(count))));
          },
        );
      }),
      ListTile(
        leading: const Icon(Icons.build_outlined),
        title: Text(AppLocalizations.of(context)!.settings),
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
          title: Text(AppLocalizations.of(context)!.signOut),
          onTap: () async {
            await showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text(AppLocalizations.of(context)!.signOut),
                  content:
                      Text(AppLocalizations.of(context)!.signOutConfirmation),
                  actions: [
                    TextButton(
                      child: Text(AppLocalizations.of(context)!.cancel),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    TextButton(
                      child: Text(AppLocalizations.of(context)!.signOut),
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
                  Expanded(
                      child: ListView(
                          padding: EdgeInsets.zero,
                          children: const [QuicklinksListView()])),
                  ...tiles
                ]);
              } else {
                return ListView(
                    padding: EdgeInsets.zero,
                    children: [const QuicklinksListView(), ...tiles]);
              }
            }))
          ],
        ),
      ),
    );
  }
}
