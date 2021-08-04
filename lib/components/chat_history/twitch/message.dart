import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_image/flutter_image.dart';
import 'package:linkify/linkify.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/chat_history/twitch/badge.dart';
import 'package:rtchat/models/style.dart';
import 'package:rtchat/models/twitch/message.dart';
import 'package:rtchat/models/twitch/third_party_emote.dart';
import 'package:url_launcher/url_launcher.dart';

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

class TwitchMessageWidget extends StatelessWidget {
  final TwitchMessageModel model;

  const TwitchMessageWidget(this.model, {Key? key}) : super(key: key);

  Color get color {
    final color = model.tags['color'];
    if (color != null) {
      return Color(int.parse("0xff${color.substring(1)}"));
    }
    return model.author.color;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StyleModel>(builder: (context, styleModel, child) {
      if (!styleModel.isDeletedMessagesVisible && model.deleted) {
        return Container();
      }
      var authorStyle = Theme.of(context).textTheme.bodyText2!.copyWith(
          fontSize: styleModel.fontSize,
          fontWeight: FontWeight.w500,
          color: styleModel.applyLightnessBoost(context, color));

      var messageStyle = Theme.of(context)
          .textTheme
          .bodyText2!
          .copyWith(fontSize: styleModel.fontSize);

      final linkStyle = Theme.of(context).textTheme.bodyText2!.copyWith(
          fontSize: styleModel.fontSize, color: Theme.of(context).accentColor);

      final tagStyle = Theme.of(context)
          .textTheme
          .bodyText2!
          .copyWith(fontSize: styleModel.fontSize, fontWeight: FontWeight.bold);

      final List<InlineSpan> children = [];

      // add badges.
      children.addAll(model.badges.map((badge) => WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
              padding: const EdgeInsets.only(right: 5),
              child: TwitchBadgeWidget(
                  channelId: model.tags['room-id'],
                  badge: badge.key,
                  version: badge.version,
                  height: styleModel.fontSize)))));

      // add author.
      children.add(TextSpan(style: authorStyle, text: model.author.display));

      // add demarcator.
      switch (model.tags['message-type']) {
        case "action":
          children.add(TextSpan(text: " ", style: messageStyle));
          break;
        case "chat":
          children.add(TextSpan(text: ": ", style: messageStyle));
          break;
      }
      return Opacity(
        opacity: model.deleted ? 0.6 : 1.0,
        child: Consumer<ThirdPartyEmoteModel>(
            builder: (context, emoteModel, child) {
          final tokens = model.tokenize(emoteModel.resolver);
          return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: RichText(
                text: TextSpan(
                  children: [
                    ...children,
                    ...tokens.map((token) {
                      if (token is TextToken) {
                        return TextSpan(text: token.text, style: messageStyle);
                      } else if (token is EmoteToken) {
                        return WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Image(
                                image: NetworkImageWithRetry(token.url),
                                height: styleModel.fontSize));
                      } else if (token is LinkToken) {
                        return WidgetSpan(
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: Text.rich(
                              TextSpan(
                                text: token.text,
                                style: linkStyle,
                                recognizer: (TapGestureRecognizer()
                                  ..onTap = () => launch(token.url)),
                              ),
                            ),
                          ),
                        );
                      } else if (token is UserMentionToken) {
                        return TextSpan(
                            text: "@${token.username}", style: tagStyle);
                      } else {
                        throw Exception("invalid token");
                      }
                    }).toList(),
                  ],
                ),
              ));
        }),
      );
    });
  }
}
