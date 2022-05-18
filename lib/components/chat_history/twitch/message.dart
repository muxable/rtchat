import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:linkify/linkify.dart';
import 'package:motion_sensors/motion_sensors.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/chat_history/twitch/badge.dart';
import 'package:rtchat/models/messages/tokens.dart';
import 'package:rtchat/models/messages/twitch/message.dart';
import 'package:rtchat/models/style.dart';
import 'package:rtchat/models/user.dart';
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

const contributors = [
  "158394109", // muxfd
  "761248557", //ken0095
];

class TwitchMessageWidget extends StatelessWidget {
  final TwitchMessageModel model;

  const TwitchMessageWidget(this.model, {Key? key}) : super(key: key);

  Color get color {
    final color = model.tags['color'] ?? "";
    if (color.isNotEmpty) {
      return Color(int.parse("0xff${color.substring(1)}"));
    }
    return model.author.color;
  }

  Iterable<InlineSpan> _render(
      BuildContext context, StyleModel styleModel, MessageToken token) sync* {
    final linkStyle = Theme.of(context)
        .textTheme
        .bodyText2!
        .copyWith(color: Theme.of(context).colorScheme.secondary);

    final tagStyleStreamer = TextStyle(
        color: Theme.of(context).brightness == Brightness.light
            ? Colors.white
            : Colors.black,
        backgroundColor: Theme.of(context).brightness == Brightness.light
            ? Colors.black
            : Colors.white);
    //for streamermention

    final tagStyle = TextStyle(
        backgroundColor: Theme.of(context).highlightColor); //for usermention

    final multiplierStyle = Theme.of(context)
        .textTheme
        .caption!
        .copyWith(color: Theme.of(context).colorScheme.secondary);

    if (token is TextToken) {
      yield TextSpan(text: token.text);
    } else if (token is EmoteToken) {
      yield WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          // NetworkImageWithRetry doesn't support animated gifs.
          // https://github.com/flutter/flutter/issues/81664
          child:
              Image.network(token.url.toString(), height: styleModel.fontSize));
    } else if (token is LinkToken) {
      yield WidgetSpan(
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Text.rich(
            TextSpan(
              text: token.text,
              style: linkStyle,
              recognizer: (TapGestureRecognizer()
                ..onTap = () => launchUrl(token.url)),
            ),
          ),
        ),
      );
    } else if (token is UserMentionToken) {
      final userModel = Provider.of<UserModel>(context, listen: false);
      final loginChannel = userModel.userChannel?.displayName;
      if (token.username.toLowerCase() == loginChannel?.toLowerCase()) {
        yield TextSpan(
            // wrap tag with nonbreaking spaces
            text: "\u{00A0}@${token.username}\u{00A0}",
            style: tagStyleStreamer);
      } else {
        yield TextSpan(
            // wrap tag with nonbreaking spaces
            text: "\u{00A0}@${token.username}\u{00A0}",
            style: tagStyle);
      }
    } else if (token is CompactedToken) {
      yield* token.children
          .expand((child) => _render(context, styleModel, child));
      yield TextSpan(text: "×${token.multiplicity}", style: multiplierStyle);
    } else {
      throw Exception("invalid token");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StyleModel>(builder: (context, styleModel, child) {
      if (!styleModel.isDeletedMessagesVisible && model.deleted) {
        return Container();
      }
      var authorStyle = Theme.of(context)
          .textTheme
          .subtitle2!
          .copyWith(color: styleModel.applyLightnessBoost(context, color));

      final List<InlineSpan> children = [];

      // add badges.
      children.addAll(model.badges.map((badge) => WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: TwitchBadgeWidget(
              channelId: model.tags['room-id'],
              badge: badge.key,
              version: badge.version,
              height: styleModel.fontSize))));

      // add author.
      if (contributors.contains(model.author.userId)) {
        children.add(WidgetSpan(
            child: StreamBuilder<AbsoluteOrientationEvent>(
                stream: motionSensors.absoluteOrientation,
                builder: (context, snapshot) {
                  final orientation = snapshot.data;
                  if (orientation == null) {
                    return RichText(
                        text: TextSpan(
                            text: model.author.display, style: authorStyle));
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
                          text: model.author.display,
                          style: authorStyle.copyWith(color: shimmer)));
                })));
      } else {
        children.add(TextSpan(text: model.author.display, style: authorStyle));
      }

      // add demarcator.
      if (model.isAction) {
        children.add(const TextSpan(text: " "));
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
          child: Text.rich(
            TextSpan(
              children: [
                ...children,
                ...tokens
                    .expand((token) => _render(context, styleModel, token))
                    .toList(),
              ],
            ),
          ),
        ),
      );
    });
  }
}
