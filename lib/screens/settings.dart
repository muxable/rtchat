import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/font_size_picker.dart';
import 'package:rtchat/models/layout.dart';

class SettingsScreen extends StatelessWidget {
  void authenticate(BuildContext context) {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings"),
      ),
      body: Consumer<LayoutModel>(builder: (context, layoutModel, child) {
        return Column(children: [
          Padding(padding: EdgeInsets.all(16), child: FontSizePickerWidget()),
          SwitchListTile(
            title: const Text('Show viewer and follower count'),
            value: layoutModel.isStatsVisible,
            onChanged: (value) {
              layoutModel.isStatsVisible = value;
            },
          ),
          SwitchListTile(
            title: const Text('Disable input when layout is locked'),
            subtitle: const Text(
                'Useful for rain streams to avoid triggering the keyboard'),
            value: layoutModel.isInputLockable,
            onChanged: (value) {
              layoutModel.isInputLockable = value;
            },
          ),
          ListTile(
            title: const Text('Twitch badge settings'),
            subtitle: const Text("Control which badges are visible"),
            onTap: () {
              Navigator.pushNamed(context, "/settings/badges");
            },
          ),
        ]);
      }),
    );
  }
}
