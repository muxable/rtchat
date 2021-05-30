import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/font_size_picker.dart';
import 'package:rtchat/models/layout.dart';
import 'package:url_launcher/url_launcher.dart';

final discordUrl = "https://discord.gg/UKHJMQs74u";

class SettingsScreen extends StatelessWidget {
  void authenticate(BuildContext context) {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings"),
      ),
      body: Consumer<LayoutModel>(builder: (context, layoutModel, child) {
        return ListView(children: [
          Padding(padding: EdgeInsets.all(16), child: FontSizePickerWidget()),
          SwitchListTile.adaptive(
            title: const Text('Show viewer and follower count'),
            value: layoutModel.isStatsVisible,
            onChanged: (value) {
              layoutModel.isStatsVisible = value;
            },
          ),
          ListTile(
            title: const Text('Twitch badge settings'),
            subtitle: const Text("Control which badges are visible"),
            onTap: () {
              Navigator.pushNamed(context, "/settings/badges");
            },
          ),
          SwitchListTile.adaptive(
            title: const Text('Disable input when layout is locked'),
            subtitle: const Text(
                'Useful for rain streams to avoid triggering the keyboard'),
            value: layoutModel.isInputLockable,
            onChanged: (value) {
              layoutModel.isInputLockable = value;
            },
          ),
          SwitchListTile.adaptive(
            title: const Text('Speaker disconnect prevention'),
            subtitle: const Text('Plays an inaudible sound every 5 minutes'),
            value: layoutModel.isSpeakerDisconnectPreventionEnabled,
            onChanged: (value) {
              layoutModel.isSpeakerDisconnectPreventionEnabled = value;
            },
          ),
          Divider(),
          FutureBuilder(
              future: canLaunch(discordUrl),
              builder: (context, snapshot) {
                if (!snapshot.hasData || !(snapshot.data as bool)) {
                  return Container();
                }

                return ListTile(
                  title: const Text('RealtimeIRL Discord'),
                  subtitle: const Text("Join the RealtimeIRL Discord!"),
                  trailing: Icon(Icons.launch),
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
                  width: 24,
                  image: AssetImage('assets/TwitchGlitchPurple.png')),
              title: Text("/$key"),
              trailing: Icon(Icons.launch),
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
