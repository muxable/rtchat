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
            title: const Text('Stream Statistics'),
            value: layoutModel.isStatsVisible,
            onChanged: (value) {
              layoutModel.isStatsVisible = value;
            },
            secondary: const Icon(Icons.analytics_outlined),
          )
        ]);
      }),
    );
  }
}
