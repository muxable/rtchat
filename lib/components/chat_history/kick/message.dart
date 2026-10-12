import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/chat_history/tokens.dart';
import 'package:rtchat/components/chat_history/twitch/message.dart' show colors;
import 'package:rtchat/models/messages/kick/message.dart';
import 'package:rtchat/models/messages/kick/user.dart';
import 'package:rtchat/models/messages/tokens.dart';
import 'package:rtchat/models/style.dart';

const _badgeIcons = {
  "broadcaster": Icons.videocam,
  "moderator": Icons.shield,
  "vip": Icons.diamond,
  "og": Icons.workspace_premium,
  "founder": Icons.workspace_premium,
  "verified": Icons.verified,
  "subscriber": Icons.star,
  "sub_gifter": Icons.card_giftcard,
};

class KickMessageWidget extends StatelessWidget {
  final KickMessageModel model;

  const KickMessageWidget(this.model, {super.key});

  Color get color {
    final color = model.author.color;
    if (color != null) {
      return color;
    }
    final login = model.author.login;
    if (login.isEmpty) {
      return colors.first;
    }
    return colors[
        (login.codeUnits.first + login.codeUnits.last) % colors.length];
  }

  Widget _badge(BuildContext context, KickBadge badge, double size) {
    return Padding(
      padding: const EdgeInsets.only(right: 2),
      child: Tooltip(
        message:
            badge.count == null ? badge.text : "${badge.text} (${badge.count})",
        child: Icon(_badgeIcons[badge.type] ?? Icons.label,
            size: size, color: Theme.of(context).colorScheme.secondary),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StyleModel>(builder: (context, styleModel, child) {
      if (!styleModel.isDeletedMessagesVisible && model.deleted) {
        return const SizedBox();
      }
      final authorStyle = Theme.of(context)
          .textTheme
          .titleSmall!
          .copyWith(color: styleModel.applyLightnessBoost(context, color));
      final tokens = styleModel.compactMessages == CompactMessages.none
          ? model.tokenized
          : model.tokenized.compacted;
      final reply = model.reply;

      return Opacity(
        opacity: model.deleted ? 0.6 : 1.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (reply != null)
                Text.rich(
                  TextSpan(children: [
                    const WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: Icon(Icons.reply, size: 14),
                      ),
                    ),
                    TextSpan(
                        text: "@${styleModel.getDisplayName(reply.author)}: ",
                        style: Theme.of(context).textTheme.bodySmall),
                    TextSpan(
                        text: reply.content,
                        style: Theme.of(context).textTheme.bodySmall),
                  ]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              Text.rich(
                TextSpan(children: [
                  for (final badge in model.author.badges)
                    WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: _badge(context, badge, styleModel.fontSize)),
                  TextSpan(
                      text: styleModel.getDisplayName(model.author),
                      style: authorStyle),
                  const TextSpan(text: ": "),
                  for (final token in tokens)
                    ...renderToken(context, styleModel, token),
                ]),
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium!
                    .copyWith(fontSize: styleModel.fontSize),
              ),
            ],
          ),
        ),
      );
    });
  }
}
