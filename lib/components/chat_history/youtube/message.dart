import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/chat_history/tokens.dart';
import 'package:rtchat/components/chat_history/twitch/message.dart' show colors;
import 'package:rtchat/models/messages/tokens.dart';
import 'package:rtchat/models/messages/youtube/message.dart';
import 'package:rtchat/models/messages/youtube/user.dart';
import 'package:rtchat/models/style.dart';

// the name colors YouTube uses for owners, moderators and members.
const _ownerColor = Color(0xFFFFD600);
const _moderatorColor = Color(0xFF5E84F1);
const _memberColor = Color(0xFF2BA640);

/// The badges shown before a YouTube author's name.
List<(IconData, String)> youTubeBadges(YouTubeUserModel user) => [
      if (user.isChatOwner) (Icons.videocam, "Owner"),
      if (user.isChatModerator) (Icons.build, "Moderator"),
      if (user.isChatSponsor) (Icons.star, "Member"),
      if (user.isVerified) (Icons.verified, "Verified"),
    ];

class YouTubeMessageWidget extends StatelessWidget {
  final YouTubeMessageModel model;

  const YouTubeMessageWidget(this.model, {super.key});

  Color get color {
    final author = model.author;
    if (author.isChatOwner) {
      return _ownerColor;
    } else if (author.isChatModerator) {
      return _moderatorColor;
    } else if (author.isChatSponsor) {
      return _memberColor;
    }
    final id = author.userId;
    if (id.isEmpty) {
      return colors.first;
    }
    return colors[(id.codeUnits.first + id.codeUnits.last) % colors.length];
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

      return Opacity(
        opacity: model.deleted ? 0.6 : 1.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text.rich(
            TextSpan(children: [
              for (final (icon, label) in youTubeBadges(model.author))
                WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 2),
                      child: Tooltip(
                        message: label,
                        child: Icon(icon,
                            size: styleModel.fontSize,
                            color: Theme.of(context).colorScheme.secondary),
                      ),
                    )),
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
        ),
      );
    });
  }
}
