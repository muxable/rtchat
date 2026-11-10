import 'package:flutter/material.dart';
import 'package:rtchat/l10n/app_localizations.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settingsBackupTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.cloudBackup,
              style: TextStyle(
                color: Theme.of(context).colorScheme.secondary,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(AppLocalizations.of(context)!.lastBackupNever),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.cloud_upload),
                  label: Text(AppLocalizations.of(context)!.backUp),
                  onPressed: () {},
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.cloud_download),
                  label: Text(AppLocalizations.of(context)!.restore),
                  onPressed: () {},
                ),
              ],
            ),
            const Divider(),
            Text(
              AppLocalizations.of(context)!.localBackup,
              style: TextStyle(
                color: Theme.of(context).colorScheme.secondary,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.file_download),
                  label: Text(AppLocalizations.of(context)!.exportSettings),
                  onPressed: () {},
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.file_upload),
                  label: Text(AppLocalizations.of(context)!.importSettings),
                  onPressed: () {},
                ),
              ],
            ),
            const Divider(),
          ],
        ),
      ),
    );
  }
}
