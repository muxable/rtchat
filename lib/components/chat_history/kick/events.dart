import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/chat_history/decorated_event.dart';
import 'package:rtchat/components/image/resilient_network_image.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/messages/kick/event.dart';
import 'package:rtchat/models/messages/kick/user.dart';
import 'package:rtchat/models/style.dart';
import 'package:styled_text/styled_text.dart';

class _KickEventText extends StatelessWidget {
  final String Function(AppLocalizations l10n, StyleModel styleModel) text;

  const _KickEventText(this.text);

  @override
  Widget build(BuildContext context) {
    return Consumer<StyleModel>(builder: (context, styleModel, child) {
      return StyledText(
        text: text(AppLocalizations.of(context)!, styleModel),
        tags: {
          'b': StyledTextTag(style: Theme.of(context).textTheme.titleSmall),
        },
      );
    });
  }
}

Widget _decorated(KickUserModel? user, IconData icon, Widget child) {
  final picture = user?.profilePictureUrl;
  if (picture != null) {
    return DecoratedEventWidget.avatar(
        avatar: ResilientNetworkImage(Uri.parse(picture)), child: child);
  }
  return DecoratedEventWidget.icon(icon: icon, child: child);
}

class KickFollowEventWidget extends StatelessWidget {
  final KickFollowEventModel model;

  const KickFollowEventWidget(this.model, {super.key});

  @override
  Widget build(BuildContext context) => _decorated(
      model.follower,
      Icons.favorite,
      _KickEventText((l10n, style) =>
          l10n.followingEvent(style.getDisplayName(model.follower))));
}

class KickSubscriptionEventWidget extends StatelessWidget {
  final KickSubscriptionEventModel model;

  const KickSubscriptionEventWidget(this.model, {super.key});

  @override
  Widget build(BuildContext context) =>
      _decorated(model.subscriber, Icons.star, _KickEventText((l10n, style) {
        final name = style.getDisplayName(model.subscriber);
        return model.isRenewal
            ? l10n.kickResubscriptionEvent(name, model.months)
            : l10n.kickSubscriptionEvent(name);
      }));
}

class KickGiftedSubscriptionsEventWidget extends StatelessWidget {
  final KickGiftedSubscriptionsEventModel model;

  const KickGiftedSubscriptionsEventWidget(this.model, {super.key});

  @override
  Widget build(BuildContext context) =>
      _decorated(model.gifter, Icons.card_giftcard,
          _KickEventText((l10n, style) {
        final gifter = model.gifter;
        return l10n.kickGiftedSubscriptionsEvent(
            gifter == null ? l10n.anonymous : style.getDisplayName(gifter),
            model.giftees.length);
      }));
}

class KicksGiftedEventWidget extends StatelessWidget {
  final KicksGiftedEventModel model;

  const KicksGiftedEventWidget(this.model, {super.key});

  @override
  Widget build(BuildContext context) {
    final message = model.message;
    return _decorated(
        model.sender,
        Icons.bolt,
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _KickEventText((l10n, style) => l10n.kicksGiftedEvent(
              style.getDisplayName(model.sender), model.amount)),
          if (message != null) Text(message),
        ]));
  }
}

class KickRewardRedemptionEventWidget extends StatelessWidget {
  final KickRewardRedemptionEventModel model;

  const KickRewardRedemptionEventWidget(this.model, {super.key});

  @override
  Widget build(BuildContext context) =>
      _decorated(model.redeemer, Icons.redeem, _KickEventText((l10n, style) {
        final name = style.getDisplayName(model.redeemer);
        final input = model.userInput;
        return input == null
            ? l10n.channelPointRedemptionWithoutUserInput(
                name, model.rewardTitle, model.cost)
            : l10n.channelPointRedemptionWithUserInput(
                name, model.rewardTitle, model.cost, input);
      }));
}
