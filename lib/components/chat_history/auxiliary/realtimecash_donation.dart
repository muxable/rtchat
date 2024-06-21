import 'package:flutter/material.dart';
import 'package:rtchat/components/chat_history/decorated_event.dart';
import 'package:rtchat/models/messages/auxiliary/realtimecash.dart';
import 'package:styled_text/styled_text.dart';

class RealtimeCashDonationEventWidget extends StatelessWidget {
  final SimpleRealtimeCashDonationEventModel model;

  const RealtimeCashDonationEventWidget(this.model, {super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedEventWidget.avatar(
      avatar: model.image,
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StyledText(
              text: model.donor != null && model.donor!.isNotEmpty
                  ? '<b>${model.donor}</b> donated <b>${model.value.toString()} ${model.currency}</b>. '
                  : 'Anonymous donated <b>${model.value.toString()} ${model.currency}</b>. ',
              tags: {
                'b': StyledTextTag(style: Theme.of(context).textTheme.titleSmall),
              },
            ),
            if (model.message != null && model.message!.isNotEmpty)
              Text(model.message!,
                  style: const TextStyle(fontStyle: FontStyle.italic)),
          ]),
    );
  }
}
