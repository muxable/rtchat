import 'package:flutter/material.dart';
import 'package:rtchat/components/chat_history/decorated_event.dart';
import 'package:rtchat/models/messages/auxiliary/realtimecash.dart';

class RealtimeCashDonationEventWidget extends StatelessWidget {
  final SimpleRealtimeCashDonationEventModel model;

  const RealtimeCashDonationEventWidget(this.model, {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final boldStyle = Theme.of(context).textTheme.titleSmall;
    return DecoratedEventWidget.avatar(
      avatar: model.image,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text.rich(
          TextSpan(
            children: [
              model.donor != null && model.donor!.isNotEmpty
                  ? TextSpan(
                      text: "${model.donor} donated ",
                    )
                  : const TextSpan(text: "Anonymous donated "),
              TextSpan(
                  text: "${model.value.toString()} ${model.currency}. ",
                  style: boldStyle),
            ],
          ),
        ),
        if (model.message != null && model.message!.isNotEmpty)
          Text.rich(TextSpan(text: model.message),
              style: const TextStyle(fontStyle: FontStyle.italic)),
      ]),
    );
  }
}
