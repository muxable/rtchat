import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rtchat/components/chat_history/decorated_event.dart';
import 'package:rtchat/components/image/resilient_network_image.dart';
import 'package:rtchat/models/messages/twitch/event.dart';
import 'package:styled_text/styled_text.dart';

class TwitchHostEventWidget extends StatelessWidget {
  final TwitchHostEventModel model;

  const TwitchHostEventWidget(this.model, {super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedEventWidget.avatar(
      avatar: ResilientNetworkImage(model.from.profilePictureUrl),
      child: StyledText(
        text: AppLocalizations.of(context)!.hostEventMessage(
            model.from.displayName ?? AppLocalizations.of(context)!.anonymous,
            model.viewers),
        tags: {
          'b': StyledTextTag(
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
        },
      ),
    );
  }
}
