import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rtchat/components/chat_history/decorated_event.dart';
import 'package:rtchat/models/messages/twitch/hype_train_event.dart';
import 'package:styled_text/styled_text.dart';

class TwitchHypeTrainEventWidget extends StatelessWidget {
  final TwitchHypeTrainEventModel model;

  const TwitchHypeTrainEventWidget(this.model, {super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return DecoratedEventWidget.icon(
      icon: Icons.train,
      child: Builder(builder: (context) {
        if (model.hasEnded) {
          return StyledText(
            text: loc.hypeTrainEventEnded(model.level.toString(), model.isSuccessful ? loc.successful : loc.notSuccessful),
            tags: {
              'b': StyledTextTag(style: Theme.of(context).textTheme.titleSmall),
            },
          );
        } else {
          return StyledText(
            text: loc.hypeTrainEventProgress(model.level.toString(), ((model.progress * 100) ~/ model.goal).toString()),
            tags: {
              'b': StyledTextTag(style: Theme.of(context).textTheme.titleSmall),
            },
          );
        }
      }),
    );
  }
}
