import 'package:flutter/material.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/messages/message.dart';

class StreamStateEventWidget extends StatelessWidget {
  final StreamStateEventModel model;

  const StreamStateEventWidget(this.model, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: SizedBox(
          width: double.infinity,
          child: Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                model.isOnline
                    ? AppLocalizations.of(context)!
                        .streamOnline(model.timestamp, model.timestamp)
                    : AppLocalizations.of(context)!
                        .streamOffline(model.timestamp, model.timestamp),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              )),
        ));
  }
}
