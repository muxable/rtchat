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
              const TextSpan(text: "You received "),
              TextSpan(
                  text: "${model.value.toString()} ${model.assetName}.",
                  style: boldStyle),
              const TextSpan(text: " Your transaction hash: "),
              TextSpan(text: model.hash, style: boldStyle),
            ],
          ),
        ),
      ]),
    );
  }
}
