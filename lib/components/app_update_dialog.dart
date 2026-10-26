import 'package:flutter/material.dart';
import 'package:rtchat/models/store_version_search.dart';
import 'package:rtchat/urls.dart';

class AppUpdateDialog extends StatelessWidget {
  const AppUpdateDialog({super.key, required this.update});

  final StoreVersionResult update;

  static Future<void> show(BuildContext context, StoreVersionResult update) {
    return showDialog<void>(
      context: context,
      builder: (_) => AppUpdateDialog(update: update),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.system_update),
      title: const Text('Update available'),
      content: Text(
        'A new version of RTChat is available.\n\n'
        'Installed version: ${update.currentVersion}\n'
        'Latest version: ${update.storeVersion}\n\n'
        'Update now to get the latest improvements and fixes.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Later'),
        ),
        FilledButton(
          onPressed: () {
            openUrl(update.storeUrl);
            Navigator.of(context).pop();
          },
          child: const Text('Update'),
        ),
      ],
    );
  }
}
