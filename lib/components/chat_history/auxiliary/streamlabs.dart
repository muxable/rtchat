import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rtchat/components/chat_history/decorated_event.dart';
import 'package:rtchat/models/messages/auxiliary/streamlabs.dart';
import 'package:styled_text/styled_text.dart';

class StreamlabsDonationEventWidget extends StatelessWidget {
  final StreamlabsDonationEventModel model;

  const StreamlabsDonationEventWidget(this.model, {super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedEventWidget.avatar(
      avatar: const AssetImage("assets/streamlabs.png"),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StyledText(
              text: AppLocalizations.of(context)!
                  .streamlabsTipEventMessage(model.name, model.formattedAmount),
              tags: {
                'b': StyledTextTag(
                    style: Theme.of(context).textTheme.titleSmall),
              },
            ),
            if (model.message != null && model.message!.isNotEmpty)
              Text(model.message!,
                  style: const TextStyle(fontStyle: FontStyle.italic)),
          ]),
    );
  }
}
