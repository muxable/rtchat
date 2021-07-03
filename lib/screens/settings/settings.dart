import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/font_size_picker.dart';
import 'package:rtchat/components/tts_options_panel.dart';
import 'package:rtchat/models/layout.dart';
import 'package:url_launcher/url_launcher.dart';

const discordUrl = "https://discord.gg/UKHJMQs74u";

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  void authenticate(BuildContext context) {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      body: Consumer<LayoutModel>(builder: (context, layoutModel, child) {
        return ListView(children: [
          ListTile(
            title: const Text('Activity feed'),
            subtitle: const Text("Customize your activity feed"),
            onTap: () {
              Navigator.pushNamed(context, "/settings/activity-feed");
            },
          ),
          ListTile(
            title: const Text('Audio sources'),
            subtitle: const Text("Add web sources for alert sounds"),
            onTap: () {
              Navigator.pushNamed(context, "/settings/audio-sources");
            },
          ),
          ListTile(
            title: const Text('Quick links'),
            subtitle: const Text("Add shortcuts to commonly-used tools"),
            onTap: () {
              Navigator.pushNamed(context, "/settings/quick-links");
            },
          ),
          const Divider(),
          SwitchListTile.adaptive(
            title: const Text('Show viewer and follower count'),
            value: layoutModel.isStatsVisible,
            onChanged: (value) {
              layoutModel.isStatsVisible = value;
            },
          ),
          const FontSizePickerWidget(),
          const Divider(),
          TtsOptionsWidget(),
          const Divider(),
          SwitchListTile.adaptive(
            title: const Text('Disable input when layout is locked'),
            subtitle: const Text(
                'Useful for rain streams to avoid triggering the keyboard'),
            value: layoutModel.isInputLockable,
            onChanged: (value) {
              layoutModel.isInputLockable = value;
            },
          ),
          const Divider(),
          // ListTile(
          //   title: const Text('Settings backup and restore'),
          //   subtitle: const Text('Upload your settings to the ~cloud~'),
          //   onTap: () {
          //     Navigator.pushNamed(context, "/settings/backup");
          //   },
          // ),
          FutureBuilder(
              future: canLaunch(discordUrl),
              builder: (context, snapshot) {
                if (!snapshot.hasData || !(snapshot.data as bool)) {
                  return Container();
                }

                return ListTile(
                  title: const Text('RealtimeIRL Discord'),
                  subtitle: const Text("Join the RealtimeIRL Discord!"),
                  trailing: const Icon(Icons.launch),
                  onTap: () => launch(discordUrl),
                );
              }),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text("Thanks to all the testers who sent bug reports!",
                style: TextStyle(
                  color: Theme.of(context).accentColor,
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
              onTap: () => launch(url),
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
                return ListTile(
                  title: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [Text('$appName v$version ($buildNumber)')]),
                  dense: true,
                );
              })
        ]);
      }),
    );
  }
}
