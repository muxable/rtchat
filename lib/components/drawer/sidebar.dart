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
import 'package:rtchat/models/qr_code.dart';
import 'package:rtchat/models/quick_links.dart';
import 'package:rtchat/models/user.dart';
import 'package:rtchat/screens/settings/qr.dart';
import 'package:rtchat/urls.dart';

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
                    child: Consumer<LayoutModel>(
                      builder: (context, value, child) {
                        return ColorFiltered(
                            colorFilter: value.themeMode == ThemeMode.light
                                ? const ColorFilter.matrix(<double>[
                                    -1.0, 0.0, 0.0, 0.0, 255.0, //
                                    0.0, -1.0, 0.0, 0.0, 255.0, //
                                    0.0, 0.0, -1.0, 0.0, 255.0, //
                                    0.0, 0.0, 0.0, 1.0, 0.0, //
                                  ])
                                : const ColorFilter.matrix(<double>[
                                    1.0, 0.0, 0.0, 0.0, 0.0, //
                                    0.0, 1.0, 0.0, 0.0, 0.0, //
                                    0.0, 0.0, 1.0, 0.0, 0.0, //
                                    0.0, 0.0, 0.0, 1.0, 0.0, //
                                  ]),
                            child: Image.asset("assets/muxable.png"));
                      },
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child:
                        Consumer<UserModel>(builder: (context, model, child) {
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
                          if (userChannel != null) const SizedBox(width: 16),
                          if (userChannel != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: CrossFadeImage(
                                  placeholder: userChannel
                                      .profilePicture.placeholderImage,
                                  image: userChannel.profilePicture,
                                  height: 36,
                                  width: 36),
                            ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userChannel?.displayName ??
                                      AppLocalizations.of(context)!.notSignedIn,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                const SizedBox(height: 8),
                                Text("twitch.tv",
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        Theme.of(context).textTheme.bodyMedium),
                              ],
                            ),
                          ),
                        ]),
                      );
                    }),
                  ),
                  const VerticalDivider(
                    width: 4,
                    thickness: 2,
                    indent: 8,
                    endIndent: 8,
                  ),
                  Consumer<UserModel>(builder: (context, model, child) {
                    final userChannel = model.userChannel;
                    if (userChannel == null) {
                      return Container();
                    }
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: IconButton(
                        icon: const Icon(Icons.qr_code),
                        onPressed: () {
                          Navigator.of(context).pop();

                          showDialog(
                            context: context,
                            builder: (context) {
                              return Dialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25.0),
                                ),
                                child: Consumer<QRModel>(
                                  builder: (context, qrModel, child) {
                                    return Container(
                                      width: MediaQuery.of(context)
                                                  .orientation ==
                                              Orientation.landscape
                                          ? MediaQuery.of(context).size.width *
                                              0.01
                                          : double.infinity,
                                      decoration: BoxDecoration(
                                        gradient: qrModel.currentGradient,
                                        borderRadius:
                                            const BorderRadius.vertical(
                                                top: Radius.circular(25.0),
                                                bottom: Radius.circular(25.0)),
                                      ),
                                      child: const QRDisplay(),
                                    );
                                  },
                                ),
                              );
                            },
                          );
                        },
                      ),
                    );
                  }),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: IconButton(
                      icon: const Icon(Icons.search),
                      iconSize: 32,
                      splashRadius: 24,
                      tooltip: AppLocalizations.of(context)!.searchChannels,
                      onPressed: () {
                        Navigator.of(context).pop();
                        FirebaseAnalytics.instance.logEvent(
                            name: 'search_channels', parameters: null);
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
                                final model = Provider.of<UserModel>(context,
                                    listen: false);
                                final userChannel = model.userChannel;
                                return ChannelSearchBottomSheetWidget(
                                  onChannelSelect: (channel) {
                                    model.activeChannel = channel;
                                  },
                                  onRaid: userChannel == model.activeChannel &&
                                          userChannel != null
                                      ? (channel) {
                                          final activeChannel =
                                              model.activeChannel;
                                          if (activeChannel == null) {
                                            return;
                                          }
                                          ActionsAdapter.instance
                                              .raid(activeChannel, channel);
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
    );
  }
}

class Sidebar extends StatefulWidget {
  final Channel channel;

  const Sidebar({required this.channel, super.key});

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  Widget _buildActionTile(BuildContext context, String actionId) {
    switch (actionId) {
      case 'rainMode':
        return Consumer<LayoutModel>(builder: (context, layoutModel, _) {
          return ListTile(
            leading: const Icon(Icons.thunderstorm),
            title: Text(layoutModel.locked
                ? AppLocalizations.of(context)!.disableRainMode
                : AppLocalizations.of(context)!.enableRainMode),
            subtitle: Text(
                layoutModel.locked
                    ? AppLocalizations.of(context)!.disableRainModeSubtitle
                    : AppLocalizations.of(context)!.enableRainModeSubtitle,
                overflow: TextOverflow.ellipsis),
            onTap: () {
              layoutModel.locked = !layoutModel.locked;
              Navigator.pop(context);
            },
          );
        });
      case 'refreshAudio':
        return Consumer<AudioModel>(builder: (context, audioModel, _) {
          if (audioModel.sources.isEmpty) return Container();
          return ListTile(
            leading: const Icon(Icons.cached_outlined),
            title: Text(AppLocalizations.of(context)!.refreshAudioSources),
            onTap: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final count = await audioModel.refreshAllSources();
              if (!context.mounted) return;
              scaffoldMessenger.showSnackBar(SnackBar(
                  content: Text(AppLocalizations.of(context)!
                      .refreshAudioSourcesCount(count))));
            },
          );
        });
      case 'raid':
        return Consumer<UserModel>(builder: (context, model, _) {
          return ListTile(
            leading: const Icon(Icons.connect_without_contact),
            title: Text(AppLocalizations.of(context)!.raidAChannel),
            onTap: () {
              Navigator.of(context).pop();
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (context) => _buildRaidBottomSheet(context),
              );
            },
          );
        });
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildRaidBottomSheet(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          child: Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
            ),
            child: Consumer<UserModel>(
              builder: (context, model, _) {
                final userChannel = model.userChannel;
                return ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height * 0.8,
                    maxHeight: MediaQuery.of(context).size.height * 0.9,
                  ),
                  child: ChannelSearchBottomSheetWidget(
                    isRaid: true,
                    onChannelSelect: (channel) {
                      model.activeChannel = channel;
                    },
                    onRaid: userChannel == model.activeChannel &&
                            userChannel != null
                        ? (channel) {
                            final activeChannel = model.activeChannel;
                            if (activeChannel == null) return;
                            ActionsAdapter.instance
                                .raid(activeChannel, channel);
                          }
                        : null,
                    controller: scrollController,
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      ListTile(
          leading: const Icon(Icons.add_link_sharp),
          title: Text(AppLocalizations.of(context)!.configureQuickLinks),
          onTap: () =>
              Navigator.of(context).pushNamed("/settings/quick-links")),
      const Divider(),
      Consumer<QuickLinksModel>(
        builder: (context, model, _) => Column(
          children: QuickLinksModel.availableActions
              .where((action) => model.isActionEnabled(action['id']))
              .map((action) => _buildActionTile(context, action['id']))
              .toList(),
        ),
      ),
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
                        final navigator = Navigator.of(context);
                        await Provider.of<UserModel>(context, listen: false)
                            .signOut();
                        if (!mounted) return;
                        navigator.pop();
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
        child: Column(
          children: [
            const _DrawerHeader(),

            // quicklinks
            Expanded(child: Builder(builder: (context) {
              final orientation = MediaQuery.of(context).orientation;
              if (orientation == Orientation.portrait) {
                return CustomScrollView(shrinkWrap: true, slivers: [
                  const SliverToBoxAdapter(
                    child: QuicklinksListView(),
                  ),
                  SliverFillRemaining(
                      hasScrollBody: false,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: tiles,
                      ))
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
