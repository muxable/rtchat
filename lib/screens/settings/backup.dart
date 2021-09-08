import 'package:flutter/material.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({Key? key}) : super(key: key);

  @override
  _BackupScreenState createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings backup and restore")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Cloud backup",
              style: TextStyle(
                color: Theme.of(context).colorScheme.secondary,
                fontWeight: FontWeight.bold,
              )),
          const Text("Last backup: never"),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            ElevatedButton.icon(
                icon: const Icon(Icons.cloud_upload),
                label: const Text("Back up"),
                onPressed: () {}),
            ElevatedButton.icon(
                icon: const Icon(Icons.cloud_download),
                label: const Text("Restore"),
                onPressed: () {}),
          ]),
          const Divider(),
          Text("Local backup",
              style: TextStyle(
                color: Theme.of(context).colorScheme.secondary,
                fontWeight: FontWeight.bold,
              )),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            ElevatedButton.icon(
                icon: const Icon(Icons.file_download),
                label: const Text("Export"),
                onPressed: () {}),
            ElevatedButton.icon(
                icon: const Icon(Icons.file_upload),
                label: const Text("Import"),
                onPressed: () {}),
          ]),
          const Divider(),
        ]),
      ),
    );
  }
}
