import 'package:flutter/material.dart';

class BackupScreen extends StatefulWidget {
  @override
  _BackupScreenState createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Settings backup and restore")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Cloud backup",
              style: TextStyle(
                color: Theme.of(context).accentColor,
                fontWeight: FontWeight.bold,
              )),
          Text("Last backup: never"),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            ElevatedButton.icon(
                icon: Icon(Icons.cloud_upload),
                label: Text("Back up"),
                onPressed: () {}),
            ElevatedButton.icon(
                icon: Icon(Icons.cloud_download),
                label: Text("Restore"),
                onPressed: () {}),
          ]),
          Divider(),
          Text("Local backup",
              style: TextStyle(
                color: Theme.of(context).accentColor,
                fontWeight: FontWeight.bold,
              )),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            ElevatedButton.icon(
                icon: Icon(Icons.file_download),
                label: Text("Export"),
                onPressed: () {}),
            ElevatedButton.icon(
                icon: Icon(Icons.file_upload),
                label: Text("Import"),
                onPressed: () {}),
          ]),
          Divider(),
        ]),
      ),
    );
  }
}
