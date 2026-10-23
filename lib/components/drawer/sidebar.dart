import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/channel_search_bottom_sheet.dart';
import 'package:rtchat/components/drawer/quicklinks_listview.dart';
import 'package:rtchat/components/in_chat_channels.dart';
import 'package:rtchat/components/image/cross_fade_image.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/accounts.dart';
import 'package:rtchat/models/adapters/actions.dart';
import 'package:rtchat/models/audio.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/layout.dart';
import 'package:rtchat/models/qr_code.dart';
import 'package:rtchat/models/user.dart';
import 'package:rtchat/models/views.dart';
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
                        colorFilter:
                            value.themeMode == ThemeMode.light
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
                        child: Image.asset("assets/muxable.png"),
                      );
                    },
                  ),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Consumer<UserModel>(
                    builder: (context, model, child) {
                      // the user's own channels, which the app opens with.
                      final userChannels = model.userChannels;
                      final userChannel = userChannels.firstOrNull;
                      return _AccountSwitchButton(
                        // account switching logic, should have a dedicated switcher later
                        onTap: () {
                          Provider.of<ViewsModel>(
                            context,
                            listen: false,
                          ).showDefaultChannels();
                          Navigator.of(context).pop();
                        },
                        onLongPress: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pushNamed("/settings/accounts");
                        },
                        child: Row(
                          children: [
                            if (userChannel != null) const SizedBox(width: 16),
                            if (userChannel != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: CrossFadeImage(
                                  placeholder:
                                      userChannel
                                          .profilePicture
                                          .placeholderImage,
                                  image: userChannel.profilePicture,
                                  height: 36,
                                  width: 36,
                                ),
                              ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userChannels.isEmpty
                                        ? AppLocalizations.of(
                                          context,
                                        )!.notSignedIn
                                        : {
                                          for (final channel in userChannels)
                                            channel.displayName,
                                        }.join(", "),
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    userChannels
                                        .map(
                                          (channel) =>
                                              providerName(channel.provider),
                                        )
                                        .join(" · "),
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const VerticalDivider(
                  width: 4,
                  thickness: 2,
                  indent: 8,
                  endIndent: 8,
                ),
                Consumer<UserModel>(
                  builder: (context, model, child) {
                    final account = model.accounts.firstOrNull;
                    if (account == null) {
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
                                      width:
                                          MediaQuery.of(context).orientation ==
                                                  Orientation.landscape
                                              ? MediaQuery.of(
                                                    context,
                                                  ).size.width *
                                                  0.01
                                              : double.infinity,
                                      decoration: BoxDecoration(
                                        gradient: qrModel.currentGradient,
                                        borderRadius:
                                            const BorderRadius.vertical(
                                              top: Radius.circular(25.0),
                                              bottom: Radius.circular(25.0),
                                            ),
                                      ),
                                      child: QRDisplay(account: account),
                                    );
                                  },
                                ),
                              );
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
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
                        name: 'search_channels',
                        parameters: null,
                      );
                      showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                        ),
                        builder: (context) {
                          return DraggableScrollableSheet(
                            initialChildSize: 0.8,
                            maxChildSize: 0.9,
                            expand: false,
                            builder: (context, controller) {
                              final views = Provider.of<ViewsModel>(context);
                              final raider = _raidingAccount(context);
                              return ChannelSearchBottomSheetWidget(
                                onChannelSelect: views.openChannel,
                                onChannelAdd: views.addChannel,
                                channels: views.channels,
                                header: const InChatChannels(),
                                onRaid:
                                    raider == null
                                        ? null
                                        : (channel) =>
                                            ActionsAdapter.forAccount(
                                              raider,
                                            ).raid(raider.channel, channel),
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
        ),
      ),
    );
  }
}

class _AccountSwitchButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _AccountSwitchButton({
    required this.child,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  State<_AccountSwitchButton> createState() => _AccountSwitchButtonState();
}

class _AccountSwitchButtonState extends State<_AccountSwitchButton> {
  bool _showSwitchIcon = false;

  void _resetPressState() {
    if (!_showSwitchIcon) return;

    setState(() {
      _showSwitchIcon = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      splashColor: color.withValues(alpha: 0.18),
      highlightColor: color.withValues(alpha: 0.10),
      onTapDown: (_) {
        setState(() {
          _showSwitchIcon = true;
        });
      },
      onTapUp: (_) => _resetPressState(),
      onTapCancel: _resetPressState,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          AnimatedPadding(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeInOut,
            padding: EdgeInsets.only(right: _showSwitchIcon ? 36 : 0),
            child: widget.child,
          ),
          IgnorePointer(
            child: AnimatedOpacity(
              opacity: _showSwitchIcon ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeInOut,
              child: const Padding(
                padding: EdgeInsets.only(right: 10),
                child: Icon(Icons.switch_account_outlined, size: 22),
              ),
            ),
          ),
        ],
      ),
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
  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      ListTile(
        leading: const Icon(Icons.add_link_sharp),
        title: Text(AppLocalizations.of(context)!.configureQuickLinks),
        onTap: () => Navigator.of(context).pushNamed("/settings/quick-links"),
      ),

      const Divider(),

      // setting
      Consumer<LayoutModel>(
        builder: (context, layoutModel, child) {
          if (!layoutModel.locked) {
            return ListTile(
              leading: const Icon(Icons.thunderstorm),
              title: Text(AppLocalizations.of(context)!.enableRainMode),
              subtitle: Text(
                AppLocalizations.of(context)!.enableRainModeSubtitle,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () async {
                layoutModel.locked = !layoutModel.locked;
                Navigator.pop(context);
              },
            );
          }

          return ListTile(
            leading: const Icon(Icons.thunderstorm),
            title: Text(AppLocalizations.of(context)!.disableRainMode),
            subtitle: Text(
              AppLocalizations.of(context)!.disableRainModeSubtitle,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () async {
              layoutModel.locked = !layoutModel.locked;
              Navigator.pop(context);
            },
          );
        },
      ),

      Consumer<AudioModel>(
        builder: (context, audioModel, child) {
          if (audioModel.sources.isEmpty) {
            return Container();
          }
          return ListTile(
            leading: const Icon(Icons.cached_outlined),
            title: Text(AppLocalizations.of(context)!.refreshAudioSources),
            onTap: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final count = await audioModel.refreshAllSources();
              if (!context.mounted) return;
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text(
                    AppLocalizations.of(
                      context,
                    )!.refreshAudioSourcesCount(count),
                  ),
                ),
              );
            },
          );
        },
      ),

      //raid
      Consumer<UserModel>(
        builder: (context, model, child) {
          final channel = widget.channel;
          final raidingAccount =
              channel.provider == Providers.twitch
                  ? model.accountFor(channel)
                  : null;
          // hide the raid option if this isn't your own twitch channel
          if (raidingAccount == null) {
            return const SizedBox.shrink();
          }
          return ListTile(
            leading: const Icon(Icons.connect_without_contact),
            title: Text(AppLocalizations.of(context)!.raidAChannel),
            onTap: () {
              Navigator.of(context).pop();
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (context) {
                  return DraggableScrollableSheet(
                    initialChildSize: 0.8,
                    maxChildSize: 0.9,
                    expand: false,
                    builder: (context, controller) {
                      final views = Provider.of<ViewsModel>(context);
                      return ChannelSearchBottomSheetWidget(
                        isRaid: true,
                        onChannelSelect: views.openChannel,
                        onChannelAdd: views.addChannel,
                        channels: views.channels,
                        onRaid:
                            (channel) => ActionsAdapter.forAccount(
                              raidingAccount,
                            ).raid(raidingAccount.channel, channel),
                        controller: controller,
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),

      ListTile(
        leading: const Icon(Icons.build_outlined),
        title: Text(AppLocalizations.of(context)!.settings),
        onTap: () async {
          await Navigator.pushNamed(context, "/settings");
        },
      ),
      ListTile(
        leading: const Icon(Icons.manage_accounts_outlined),
        title: Text(AppLocalizations.of(context)!.accounts),
        onTap: () async {
          await Navigator.pushNamed(context, "/settings/accounts");
        },
      ),
      Consumer<UserModel>(
        builder: (context, model, child) {
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
                    content: Text(
                      AppLocalizations.of(context)!.signOutConfirmation,
                    ),
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
                          await Provider.of<UserModel>(
                            context,
                            listen: false,
                          ).signOut();
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
        },
      ),
    ];
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            const _DrawerHeader(),

            // quicklinks
            Expanded(
              child: Builder(
                builder: (context) {
                  final orientation = MediaQuery.of(context).orientation;
                  if (orientation == Orientation.portrait) {
                    return CustomScrollView(
                      shrinkWrap: true,
                      slivers: [
                        const SliverToBoxAdapter(child: QuicklinksListView()),
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: tiles,
                          ),
                        ),
                      ],
                    );
                  } else {
                    return ListView(
                      padding: EdgeInsets.zero,
                      children: [const QuicklinksListView(), ...tiles],
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The account the user can raid as: the one whose channel they're viewing,
/// if it's Twitch (raids are Twitch-only).
Account? _raidingAccount(BuildContext context) {
  final channel =
      Provider.of<ViewsModel>(context, listen: false).primaryChannel;
  if (channel == null || channel.provider != Providers.twitch) {
    return null;
  }
  return Provider.of<UserModel>(context, listen: false).accountFor(channel);
}
