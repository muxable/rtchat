import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/chat_history/decorated_event.dart';
import 'package:rtchat/components/chat_history/twitch/poll_indicator.dart';
import 'package:rtchat/components/image/resilient_network_image.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/messages/twitch/event.dart' show PollChoiceModel;
import 'package:rtchat/models/messages/youtube/event.dart';
import 'package:rtchat/models/messages/youtube/user.dart';
import 'package:rtchat/models/style.dart';
import 'package:styled_text/styled_text.dart';

// YouTube colors Super Chats and Super Stickers by tier, lowest first: blue,
// light blue, green, yellow, orange, magenta, red.
const youTubeTierColors = [
  Color(0xFF1E88E5),
  Color(0xFF00E5FF),
  Color(0xFF1DE9B6),
  Color(0xFFFFCA28),
  Color(0xFFF57C00),
  Color(0xFFE91E63),
  Color(0xFFE62117),
];

/// The color of a Super Chat or Super Sticker in [tier], which starts at 1.
Color youTubeTierColor(int tier) =>
    youTubeTierColors[(tier - 1).clamp(0, youTubeTierColors.length - 1)];

class _YouTubeEventText extends StatelessWidget {
  final String Function(AppLocalizations l10n, StyleModel styleModel) text;

  const _YouTubeEventText(this.text);

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

Widget _decorated(YouTubeUserModel user, IconData icon, Widget child,
    {Color? accentColor}) {
  final decoration = accentColor == null
      ? const BoxDecoration()
      : BoxDecoration(color: accentColor.withValues(alpha: 0.2));
  final picture = user.profileImageUrl;
  if (picture != null) {
    return DecoratedEventWidget.avatar(
        avatar: ResilientNetworkImage(Uri.parse(picture)),
        accentColor: accentColor,
        decoration: decoration,
        child: child);
  }
  return DecoratedEventWidget.icon(
      icon: icon,
      accentColor: accentColor,
      decoration: decoration,
      child: child);
}

/// The event's text, with the viewer's comment below it if they left one.
Widget _withComment(Widget text, String? comment) {
  if (comment == null) {
    return text;
  }
  return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [text, Text(comment)]);
}

class YouTubeSuperChatEventWidget extends StatelessWidget {
  final YouTubeSuperChatEventModel model;

  const YouTubeSuperChatEventWidget(this.model, {super.key});

  @override
  Widget build(BuildContext context) => _decorated(
      model.author,
      Icons.paid,
      _withComment(
          _YouTubeEventText((l10n, style) => l10n.youtubeSuperChatEvent(
              style.getDisplayName(model.author), model.amountDisplayString)),
          model.comment),
      accentColor: youTubeTierColor(model.tier));
}

class YouTubeSuperStickerEventWidget extends StatelessWidget {
  final YouTubeSuperStickerEventModel model;

  const YouTubeSuperStickerEventWidget(this.model, {super.key});

  @override
  Widget build(BuildContext context) {
    final altText = model.altText;
    return _decorated(
        model.author,
        Icons.emoji_emotions,
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _YouTubeEventText((l10n, style) => l10n.youtubeSuperStickerEvent(
              style.getDisplayName(model.author), model.amountDisplayString)),
          if (altText != null)
            Text(altText, style: const TextStyle(fontStyle: FontStyle.italic)),
        ]),
        accentColor: youTubeTierColor(model.tier));
  }
}

class YouTubeNewMemberEventWidget extends StatelessWidget {
  final YouTubeNewMemberEventModel model;

  const YouTubeNewMemberEventWidget(this.model, {super.key});

  @override
  Widget build(BuildContext context) =>
      _decorated(model.member, Icons.star, _YouTubeEventText((l10n, style) {
        final name = style.getDisplayName(model.member);
        return model.isUpgrade && model.levelName.isNotEmpty
            ? l10n.youtubeMemberUpgradeEvent(name, model.levelName)
            : l10n.youtubeNewMemberEvent(name);
      }));
}

class YouTubeMemberMilestoneEventWidget extends StatelessWidget {
  final YouTubeMemberMilestoneEventModel model;

  const YouTubeMemberMilestoneEventWidget(this.model, {super.key});

  @override
  Widget build(BuildContext context) => _decorated(
      model.member,
      Icons.star,
      _withComment(
          _YouTubeEventText((l10n, style) => l10n.youtubeMemberMilestoneEvent(
              style.getDisplayName(model.member), model.months)),
          model.comment));
}

class YouTubeMembershipGiftingEventWidget extends StatelessWidget {
  final YouTubeMembershipGiftingEventModel model;

  const YouTubeMembershipGiftingEventWidget(this.model, {super.key});

  @override
  Widget build(BuildContext context) => _decorated(
      model.gifter,
      Icons.card_giftcard,
      _YouTubeEventText((l10n, style) => l10n.youtubeMembershipGiftingEvent(
          style.getDisplayName(model.gifter), model.count)));
}

class YouTubeGiftMembershipReceivedEventWidget extends StatelessWidget {
  final YouTubeGiftMembershipReceivedEventModel model;

  const YouTubeGiftMembershipReceivedEventWidget(this.model, {super.key});

  @override
  Widget build(BuildContext context) => _decorated(
      model.recipient,
      Icons.redeem,
      _YouTubeEventText((l10n, style) =>
          l10n.youtubeGiftMembershipReceivedEvent(
              style.getDisplayName(model.recipient))));
}

class YouTubeGiftEventWidget extends StatelessWidget {
  final YouTubeGiftEventModel model;

  const YouTubeGiftEventWidget(this.model, {super.key});

  @override
  Widget build(BuildContext context) =>
      _decorated(model.sender, Icons.diamond, _YouTubeEventText((l10n, style) {
        final text = l10n.youtubeGiftEvent(
            style.getDisplayName(model.sender), model.giftName, model.jewels);
        return model.comboCount > 1 ? "$text ×${model.comboCount}" : text;
      }));
}

class YouTubePollEventWidget extends StatelessWidget {
  final YouTubePollEventModel model;

  const YouTubePollEventWidget(this.model, {super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedEventWidget(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(model.question,
                style: Theme.of(context).textTheme.titleSmall)),
        for (final (index, option) in model.options.indexed)
          PollChoiceWidget(
              data: PollChoiceModel(
                  id: "$index",
                  title: option.text,
                  bitVotes: 0,
                  channelPointVotes: 0,
                  votes: option.tally),
              isCompleted: model.isClosed,
              maxVotes: model.maxVotes,
              totalVotes: model.totalVotes),
      ]),
    );
  }
}

class YouTubeMembersOnlyModeEventWidget extends StatelessWidget {
  final YouTubeMembersOnlyModeEventModel model;

  const YouTubeMembersOnlyModeEventWidget(this.model, {super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DecoratedEventWidget.icon(
        icon: model.isEnabled ? Icons.lock : Icons.lock_open,
        child: Text(model.isEnabled
            ? l10n.youtubeMembersOnlyModeOn
            : l10n.youtubeMembersOnlyModeOff));
  }
}

class YouTubeChatEndedEventWidget extends StatelessWidget {
  final YouTubeChatEndedEventModel model;

  const YouTubeChatEndedEventWidget(this.model, {super.key});

  @override
  Widget build(BuildContext context) => DecoratedEventWidget.icon(
      icon: Icons.stop_circle,
      child: Text(AppLocalizations.of(context)!.youtubeChatEnded));
}
