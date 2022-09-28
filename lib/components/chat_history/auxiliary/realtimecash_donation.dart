import 'package:flutter/material.dart';
import 'package:rtchat/components/chat_history/decorated_event.dart';
import 'package:rtchat/models/messages/auxiliary/realtimecash.dart';

class RealtimeCashDonationEventWidget extends StatelessWidget {
  final SimpleRealtimeCashDonationEventModel model;

  const RealtimeCashDonationEventWidget(this.model, {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final boldStyle = Theme.of(context).textTheme.subtitle2;
    return DecoratedEventWidget.avatar(
      avatar: model.image,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: "${model.donor} donated "),
              TextSpan(
                  text: "${model.value.toString()} ${model.currency}. ",
                  style: boldStyle),
              if (model.message.isNotEmpty)
                TextSpan(text: "message: ${model.message}"),
              const TextSpan(text: " Hash: "),
              TextSpan(text: model.hash, style: boldStyle),
            ],
          ),
        ),
      ]),
    );
  }
}
