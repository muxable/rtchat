import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/layout.dart';

class EventConfigScreen extends StatelessWidget {
  const EventConfigScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Event Configuration Selection"),
      ),
      body: Consumer<LayoutModel>(builder: (context, layoutModel, child) {
        return ListView(children: [
          ListTile(
            title: const Text('Follow event config'),
            subtitle: const Text("Customize your follow event"),
            onTap: () {
              Navigator.pushNamed(context, "/settings/follow-config");
            },
          ),
          ListTile(
            title: const Text('Subscribe event config'),
            subtitle: const Text("Customize your subscription event"),
            onTap: () {
              Navigator.pushNamed(context, "/settings/subscription-config");
            },
          ),
          ListTile(
            title: const Text('Cheer event config'),
            subtitle: const Text("Customize your cheer event"),
            onTap: () {
              Navigator.pushNamed(context, "/settings/cheer-config");
            },
          ),
          ListTile(
            title: const Text('Raid event config'),
            subtitle: const Text("Customize your raid event"),
            onTap: () {
              Navigator.pushNamed(context, "/settings/raid-config");
            },
          ),
          ListTile(
            title: const Text('Hypetrain event config'),
            subtitle: const Text("Customize your hypetrain event"),
            onTap: () {
              Navigator.pushNamed(context, "/settings/hypetrain-config");
            },
          ),
          ListTile(
            title: const Text('Poll event config'),
            subtitle: const Text("Customize your poll event"),
            onTap: () {
              Navigator.pushNamed(context, "/settings/poll-config");
            },
          ),
        ]);
      }),
    );
  }
}
