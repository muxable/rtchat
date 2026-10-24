import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/layout.dart';
import 'package:rtchat/models/style.dart';
import 'package:rtchat/urls.dart';

Widget _iconWithText(IconData icon, String text) {
  return Column(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Icon(icon),
      ),
      Text(text, overflow: TextOverflow.fade),
    ],
  );
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.settings)),
      body: Consumer<LayoutModel>(
        builder: (context, layoutModel, child) {
          return ListView(
            children: [
              ListTile(
                title: Text(AppLocalizations.of(context)!.accounts),
                subtitle: Text(AppLocalizations.of(context)!.accountsSubtitle),
                onTap: () {
                  Navigator.pushNamed(context, "/settings/accounts");
                },
              ),
              ListTile(
                title: Text(AppLocalizations.of(context)!.activityFeed),
                subtitle: Text(
                  AppLocalizations.of(context)!.activityFeedSubtitle,
                ),
                onTap: () {
                  Navigator.pushNamed(context, "/settings/activity-feed");
                },
              ),
              ListTile(
                title: Text(AppLocalizations.of(context)!.audioSources),
                subtitle: Text(
                  AppLocalizations.of(context)!.audioSourcesSubtitle,
                ),
                onTap: () {
                  Navigator.pushNamed(context, "/settings/audio-sources");
                },
              ),
              ListTile(
                title: Text(AppLocalizations.of(context)!.quickLinks),
                subtitle: Text(
                  AppLocalizations.of(context)!.quickLinksSubtitle,
                ),
                onTap: () {
                  Navigator.pushNamed(context, "/settings/quick-links");
                },
              ),
              ListTile(
                title: Text(AppLocalizations.of(context)!.chatHistory),
                subtitle: Text(
                  AppLocalizations.of(context)!.chatHistorySubtitle,
                ),
                onTap: () {
                  Navigator.pushNamed(context, "/settings/chat-history");
                },
              ),
              ListTile(
                title: Text(AppLocalizations.of(context)!.textToSpeech),
                subtitle: Text(
                  AppLocalizations.of(context)!.textToSpeechSubtitle,
                ),
                onTap: () {
                  Navigator.pushNamed(context, "/settings/text-to-speech");
                },
              ),
              ListTile(
                title: Text(AppLocalizations.of(context)!.events),
                subtitle: Text(AppLocalizations.of(context)!.eventsSubtitle),
                onTap: () {
                  Navigator.pushNamed(context, "/settings/events");
                },
              ),
              ListTile(
                title: Text(AppLocalizations.of(context)!.thirdPartyServices),
                subtitle: Text(
                  AppLocalizations.of(context)!.thirdPartyServicesSubtitle,
                ),
                onTap: () {
                  Navigator.pushNamed(context, "/settings/third-party");
                },
              ),
              SwitchListTile.adaptive(
                title: Text(
                  AppLocalizations.of(context)!.showViewerAndFollowerCount,
                ),
                value: layoutModel.isStatsVisible,
                onChanged: (value) {
                  layoutModel.isStatsVisible = value;
                },
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.screenOrientation,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ToggleButtons(
                      constraints: BoxConstraints(
                        minWidth: (MediaQuery.of(context).size.width - 36) / 3,
                      ),
                      borderRadius: const BorderRadius.all(
                        Radius.circular(10.0),
                      ),
                      onPressed: (index) {
                        switch (index) {
                          case 0:
                            layoutModel.preferredOrientation =
                                PreferredOrientation.system;
                            break;
                          case 1:
                            layoutModel.preferredOrientation =
                                PreferredOrientation.portrait;
                            break;
                          case 2:
                            layoutModel.preferredOrientation =
                                PreferredOrientation.landscape;
                            break;
                        }
                      },
                      isSelected: [
                        layoutModel.preferredOrientation ==
                            PreferredOrientation.system,
                        layoutModel.preferredOrientation ==
                            PreferredOrientation.portrait,
                        layoutModel.preferredOrientation ==
                            PreferredOrientation.landscape,
                      ],
                      selectedColor: Theme.of(context).colorScheme.secondary,
                      children: [
                        _iconWithText(
                          Icons.screen_rotation,
                          AppLocalizations.of(context)!.systemDefault,
                        ),
                        _iconWithText(
                          Icons.screen_lock_portrait,
                          AppLocalizations.of(context)!.portrait,
                        ),
                        _iconWithText(
                          Icons.screen_lock_landscape,
                          AppLocalizations.of(context)!.landscape,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.appTheme,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ToggleButtons(
                      constraints: BoxConstraints(
                        minWidth: (MediaQuery.of(context).size.width - 36) / 3,
                      ),
                      borderRadius: const BorderRadius.all(
                        Radius.circular(10.0),
                      ),
                      onPressed: (index) {
                        switch (index) {
                          case 0:
                            layoutModel.themeMode = ThemeMode.system;
                            break;
                          case 1:
                            layoutModel.themeMode = ThemeMode.light;
                            break;
                          case 2:
                            layoutModel.themeMode = ThemeMode.dark;
                            break;
                        }
                      },
                      isSelected: [
                        layoutModel.themeMode == ThemeMode.system,
                        layoutModel.themeMode == ThemeMode.light,
                        layoutModel.themeMode == ThemeMode.dark,
                      ],
                      selectedColor: Theme.of(context).colorScheme.secondary,
                      children: [
                        _iconWithText(
                          Icons.auto_mode,
                          AppLocalizations.of(context)!.systemDefault,
                        ),
                        _iconWithText(
                          Icons.light_mode,
                          AppLocalizations.of(context)!.lightTheme,
                        ),
                        _iconWithText(
                          Icons.dark_mode,
                          AppLocalizations.of(context)!.darkTheme,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(),
              ListTile(
                title: Text(AppLocalizations.of(context)!.openSourceTitle),
                subtitle: Text(
                  AppLocalizations.of(context)!.openSourceSubtitle,
                ),
                trailing: const Icon(Icons.terminal),
                onTap:
                    () =>
                        openUrl(Uri.parse("https://github.com/muxable/rtchat")),
              ),
              ListTile(
                title: const Text('Muxable Discord'),
                subtitle: Text(AppLocalizations.of(context)!.discordSubtitle),
                trailing: const Icon(Icons.launch),
                onTap:
                    () => openUrl(Uri.parse("https://discord.gg/UKHJMQs74u")),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  AppLocalizations.of(context)!.earlyTestersThanks,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Column(
                children:
                    {"wormoSTEEZE", "ThisisKurtIRL", "nezst"}.map((key) {
                      final url = "https://twitch.tv/$key";
                      return ListTile(
                        leading: const Image(
                          width: 24,
                          image: AssetImage('assets/providers/twitch.png'),
                        ),
                        title: Text("/$key"),
                        trailing: const Icon(Icons.launch),
                        onTap: () => openUrl(Uri.parse(url)),
                      );
                    }).toList(),
              ),
              FutureBuilder(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Container();
                  }
                  final packageInfo = snapshot.data as PackageInfo;
                  final appName = packageInfo.appName;
                  final version = packageInfo.version;
                  final buildNumber = packageInfo.buildNumber;
                  return ListTile(
                    title: Text(appName),
                    subtitle: Text('$version ($buildNumber)'),
                    onTap: () {
                      showLicensePage(
                        context: context,
                        applicationName: appName,
                        applicationVersion: 'Version $version ($buildNumber)',
                        applicationLegalese: '\u{a9} 2026 Muxable',
                      );
                    },
                    onLongPress: () {
                      final model = Provider.of<StyleModel>(
                        context,
                        listen: false,
                      );
                      model.isDiscoModeAvailable = !model.isDiscoModeAvailable;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              model.isDiscoModeAvailable
                                  ? Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.discoModeEnabled,
                                  )
                                  : Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.discoModeDisabled,
                                  ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
