import 'package:flutter/material.dart';
import 'package:linkify/linkify.dart';
import 'package:dchs_motion_sensors/dchs_motion_sensors.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/chat_history/tokens.dart';
import 'package:rtchat/components/chat_history/twitch/badge.dart';
import 'package:rtchat/models/messages/tokens.dart';
import 'package:rtchat/models/messages/twitch/message.dart';
import 'package:rtchat/models/messages/twitch/user.dart';
import 'package:rtchat/models/style.dart';

const colors = [
  Color(0xFFFF0000),
  Color(0xFF0000FF),
  Color(0xFF00FF00),
  Color(0xFFB22222),
  Color(0xFFFF7F50),
  Color(0xFF9ACD32),
  Color(0xFFFF4500),
  Color(0xFF2E8B57),
  Color(0xFFDAA520),
  Color(0xFFD2691E),
  Color(0xFF5F9EA0),
  Color(0xFF1E90FF),
  Color(0xFFFF69B4),
  Color(0xFF8A2BE2),
  Color(0xFF00FF7F),
];

String? getFirstClipLink(String text) {
  final parsed = linkify(text, options: const LinkifyOptions(humanize: false));
  for (final element in parsed) {
    if (element is LinkableElement && isTwitchClip(element.url)) {
      return element.url;
    }
  }
  return null;
}

bool isTwitchClip(String url) {
  const twitchBaseUrl = 'twitch.tv';
  const clipStr = 'clip';
  const clipsStr = 'clips';
  const videosStr = 'videos';
  return url.contains(twitchBaseUrl) &&
      (url.contains(clipStr) ||
          url.contains(clipsStr) ||
          url.contains(videosStr));
}

const contributors = [
  "158394109", // muxfd
  "761248557", //ken0095
];

class TwitchMessageWidget extends StatelessWidget {
  final TwitchMessageModel model;

  const TwitchMessageWidget(this.model, {super.key});

  Color get color {
    final color = model.tags['color'] ?? "";
    if (color.isNotEmpty) {
      return Color(int.parse("0xff${color.substring(1)}"));
    }
    return model.author.color;
  }

  Widget authorWidget(
      TwitchUserModel author, StyleModel styleModel, TextStyle authorStyle) {
    if (contributors.contains(model.author.userId)) {
      return StreamBuilder<AbsoluteOrientationEvent>(
          stream: motionSensors.absoluteOrientation,
          builder: (context, snapshot) {
            final orientation = snapshot.data;
            if (orientation == null) {
              return RichText(
                  text: TextSpan(
                      text: styleModel.getDisplayName(model.author),
                      style: authorStyle));
            }
            final hslColor = HSLColor.fromColor(
                styleModel.applyLightnessBoost(context, color));
            final deg =
                (orientation.pitch + orientation.roll + orientation.yaw) *
                    180 /
                    3.1415;
            final shimmer =
                hslColor.withHue((hslColor.hue - deg) % 360).toColor();
            return RichText(
                text: TextSpan(
                    text: styleModel.getDisplayName(model.author),
                    style: authorStyle.copyWith(color: shimmer)));
          });
    }
    return RichText(text: authorSpan(author, styleModel, authorStyle));
  }

  InlineSpan authorSpan(
      TwitchUserModel author, StyleModel styleModel, TextStyle authorStyle) {
    if (contributors.contains(model.author.userId)) {
      return WidgetSpan(child: authorWidget(author, styleModel, authorStyle));
    }
    return TextSpan(
        text: styleModel.getDisplayName(model.author), style: authorStyle);
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

      final List<InlineSpan> children = [];

      // add badges.
      children.addAll(model.badges.map((badge) => WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: TwitchBadgeWidget(
              badgeSetId: badge.key,
              version: badge.version,
              height: styleModel.fontSize))));

      // add author.
      // add a party hat if first time chatter.
      if (model.annotations.isFirstTimeChatter) {
        children.add(WidgetSpan(
            child: Stack(
          children: [
            authorWidget(model.author, styleModel, authorStyle),
            SizedBox(
                width: styleModel.fontSize,
                height: styleModel.fontSize,
                child: Transform.translate(
                    offset: Offset(
                        -styleModel.fontSize / 2, -styleModel.fontSize / 4),
                    child: const Image(image: AssetImage("assets/hat.png")))),
          ],
        )));
      } else {
        children.add(authorSpan(model.author, styleModel, authorStyle));
      }

      // add demarcator.
      if (model.isAction) {
        children.add(const TextSpan(text: " "));
      } else if (model.reply != null) {
        // when removing '@username' from a reply's message, a space is left at the beginning
        children.add(const TextSpan(text: ":"));
      } else {
        children.add(const TextSpan(text: ": "));
      }

      final tokens = styleModel.compactMessages == CompactMessages.none
          ? model.tokenized
          : model.tokenized.compacted;

      return Opacity(
        opacity: model.deleted ? 0.6 : 1.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (model.reply != null)
                Text.rich(
                  TextSpan(children: [
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: styleModel.fontSize / 3,
                          right: 5,
                        ),
                        child: Icon(
                          Icons.shortcut_rounded,
                          size: styleModel.fontSize,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    ),
                    TextSpan(
                        text:
                            '${model.reply?.author.displayName}: ${model.reply?.message}'),
                  ]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.apply(
                        color: Theme.of(context).hintColor,
                        fontSizeFactor: 0.75,
                      ),
                ),
              Text.rich(
                TextSpan(
                  children: [
                    ...children,
                    ...tokens.expand((token) {
                      return renderToken(context, styleModel, token);
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
