import 'package:flutter/material.dart';
import 'package:rtchat/components/font_size_picker.dart';

class SettingsScreen extends StatelessWidget {
  void authenticate(BuildContext context) {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Settings"),
        ),
        body: Column(children: [
          Padding(padding: EdgeInsets.all(16), child: FontSizePicker()),
        ]));
  }
}
