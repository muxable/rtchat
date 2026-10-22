import 'package:flutter/material.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/messages/message.dart';

class ChatClearedEventWidget extends StatelessWidget {
  final ChatClearedEventModel model;

  const ChatClearedEventWidget(this.model, {super.key});

  @override
  Widget build(BuildContext context) {
    final provider = model.channel == null
        ? 'Unknown'
        : providerName(model.channel!.provider);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        color: Theme.of(context).dividerColor,
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        child: Text(
          '($provider) ${AppLocalizations.of(context)!.chatCleared(model.timestamp, model.timestamp)}',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
}
