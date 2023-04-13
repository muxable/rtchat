import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rtchat/models/messages/message.dart';

class ChatClearedEventWidget extends StatelessWidget {
  final ChatClearedEventModel model;

  const ChatClearedEventWidget(this.model, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Container(
          color: Theme.of(context).dividerColor,
          width: double.infinity,
          child: Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                AppLocalizations.of(context)!
                    .chatCleared(model.timestamp, model.timestamp),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              )),
        ));
  }
}
