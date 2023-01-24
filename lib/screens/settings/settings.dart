import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/layout.dart';
import 'package:rtchat/models/style.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rtchat/urls.dart';

Widget _iconWithText(IconData icon, String text) {
  return Column(children: [
    Padding(
        padding: const EdgeInsets.symmetric(vertical: 4), child: Icon(icon)),
    Text(text),
  ]);
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _versionTapCount = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settings),
      ),
      body: Consumer<LayoutModel>(builder: (context, layoutModel, child) {
        return ListView(children: [
          ListTile(
            title: Text(AppLocalizations.of(context)!.activityFeed),
            subtitle: Text(AppLocalizations.of(context)!.activityFeedSubtitle),
            onTap: () {
              Navigator.pushNamed(context, "/settings/activity-feed");
            },
          ),
          ListTile(
            title: Text(AppLocalizations.of(context)!.audioSources),
            subtitle: Text(AppLocalizations.of(context)!.audioSourcesSubtitle),
            onTap: () {
              Navigator.pushNamed(context, "/settings/audio-sources");
            },
          ),
          ListTile(
            title: Text(AppLocalizations.of(context)!.quickLinks),
            subtitle: Text(AppLocalizations.of(context)!.quickLinksSubtitle),
            onTap: () {
              Navigator.pushNamed(context, "/settings/quick-links");
            },
          ),
          ListTile(
            title: Text(AppLocalizations.of(context)!.chatHistory),
            subtitle: Text(AppLocalizations.of(context)!.chatHistorySubtitle),
            onTap: () {
              Navigator.pushNamed(context, "/settings/chat-history");
            },
          ),
          ListTile(
            title: Text(AppLocalizations.of(context)!.textToSpeech),
            subtitle: Text(AppLocalizations.of(context)!.textToSpeechSubtitle),
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
            subtitle:
                Text(AppLocalizations.of(context)!.thirdPartyServicesSubtitle),
            onTap: () {
              Navigator.pushNamed(context, "/settings/third-party");
            },
          ),
          const Divider(),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Screen orientation",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                        )),
                    const SizedBox(height: 8),
                    ToggleButtons(
                      constraints: BoxConstraints(
                          minWidth:
                              (MediaQuery.of(context).size.width - 36) / 3),
                      borderRadius:
                          const BorderRadius.all(Radius.circular(10.0)),
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
                        _iconWithText(Icons.screen_rotation, "System"),
                        _iconWithText(Icons.screen_lock_portrait, "Portrait"),
                        _iconWithText(Icons.screen_lock_landscape, "Landscape"),
                      ],
                    ),
                  ])),
          const SizedBox(height: 8),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("App theme",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                        )),
                    const SizedBox(height: 8),
                    ToggleButtons(
                      constraints: BoxConstraints(
                          minWidth:
                              (MediaQuery.of(context).size.width - 36) / 3),
                      borderRadius:
                          const BorderRadius.all(Radius.circular(10.0)),
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
                        _iconWithText(Icons.auto_mode, "System"),
                        _iconWithText(Icons.light_mode, "Light mode"),
                        _iconWithText(Icons.dark_mode, "Dark mode"),
                      ],
                    ),
                  ])),
          SwitchListTile.adaptive(
            title: const Text('Show viewer and follower count'),
            value: layoutModel.isStatsVisible,
            onChanged: (value) {
              layoutModel.isStatsVisible = value;
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('RealtimeChat is open source!'),
            subtitle: const Text("Find us on GitHub!"),
            trailing: const Icon(Icons.terminal),
            onTap: () =>
                openUrl(Uri.parse("https://github.com/muxable/rtchat")),
          ),
          ListTile(
            title: const Text('Muxable Discord'),
            subtitle: const Text("Join the Muxable Discord!"),
            trailing: const Icon(Icons.launch),
            onTap: () => openUrl(Uri.parse("https://discord.gg/UKHJMQs74u")),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text("Thanks to all the early testers who sent bug reports!",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                )),
          ),
          Column(
              children: {"wormoSTEEZE", "ThisIsKurrrt", "nezst"}.map((key) {
            final url = "https://twitch.tv/$key";
            return ListTile(
              leading: const Image(
                  width: 24, image: AssetImage('assets/providers/twitch.png')),
              title: Text("/$key"),
              trailing: const Icon(Icons.launch),
              onTap: () => openUrl(Uri.parse(url)),
            );
          }).toList()),
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
                return AboutListTile(
                  icon: const Icon(Icons.info),
                  applicationName: appName,
                  applicationVersion: 'Version $version ($buildNumber)',
                  applicationLegalese: '\u{a9} 2023 Muxable',
                  dense: true,
                  aboutBoxChildren: [
                    const SizedBox(height: 24),
                    InkWell(
                        child: const Text(
                          'Seems legit',
                          textAlign: TextAlign.center,
                        ),
                        onTap: () {
                          setState(() {
                            if (++_versionTapCount == 6) {
                              _versionTapCount = 0;
                              final model = Provider.of<StyleModel>(context,
                                  listen: false);
                              model.isDiscoModeAvailable =
                                  !model.isDiscoModeAvailable;
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: model.isDiscoModeAvailable
                                          ? const Text(
                                              "🕺 Disco mode enabled! :D")
                                          : const Text(
                                              "🕺 Disco mode disabled D:")));
                            }
                          });
                        })
                  ],
                );
              })
        ]);
      }),
    );
  }
}
