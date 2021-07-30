import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_image/flutter_image.dart';
import 'package:linkify/linkify.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/chat_history/twitch/badge.dart';
import 'package:rtchat/models/message.dart';
import 'package:rtchat/models/style.dart';
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

class _Emote {
  final int start;
  final int end;
  final String key;

  _Emote(this.key, this.start, this.end);
}

class _Badge {
  final String key;
  final String version;

  _Badge(this.key, this.version);
}

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

Iterable<TextSpan> tokenize(String msg, TextStyle tagStyle) sync* {
  final matches = RegExp(r"@[A-Za-z0-9_]+").allMatches(msg);
  var start = 0;
  for (final match in matches) {
    // before the tag
    var preTag = msg.substring(start, match.start);
    yield TextSpan(text: preTag);
    // the tag
    var tag = msg.substring(match.start, match.end);
    start = match.end;
    yield TextSpan(text: tag, style: tagStyle);
  }

  if (matches.isNotEmpty) {
    var txt = msg.substring(matches.last.end);
    yield TextSpan(text: txt);
  } else {
    yield TextSpan(text: msg);
  }
}

Iterable<InlineSpan> parseText(
    String text, TextStyle linkStyle, TextStyle tagStyle) {
  final parsed = linkify(text, options: const LinkifyOptions(humanize: false));
  return parsed.map<InlineSpan>((element) {
    if (element is LinkableElement) {
      return WidgetSpan(
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Text.rich(
            TextSpan(
              text: element.text,
              style: linkStyle,
              recognizer: (TapGestureRecognizer()
                ..onTap = () => launch(element.url)),
            ),
          ),
        ),
      );
    } else {
      return TextSpan(children: tokenize(element.text, tagStyle).toList());
    }
  });
}

List<_Emote> parseEmotes(String emotes) {
  return emotes.split("/").expand((block) {
    final blockTokens = block.split(':');
    final key = blockTokens[0];
    return blockTokens[1].split(',').map((indices) {
      final indexTokens = indices.split('-');
      final start = int.parse(indexTokens[0]);
      final end = int.parse(indexTokens[1]);
      return _Emote(key, start, end);
    });
  }).toList();
}

List<_Badge> parseBadges(String badges) {
  if (badges.isEmpty) {
    return [];
  }
  return badges.split(",").map((block) {
    final tokens = block.split('/');
    final key = tokens[0];
    final version = tokens[1];
    return _Badge(key, version);
  }).toList();
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
      final badges = parseBadges(model.tags['badges-raw'] ?? "");
      children.addAll(badges.map((badge) => WidgetSpan(
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
          children.add(const TextSpan(text: " "));
          break;
        case "chat":
          children.add(const TextSpan(text: ": "));
          break;
      }

      final emotes = model.tags['emotes-raw'];
      final bttvEmoteProvider =
          Provider.of<ThirdPartyEmoteModel>(context, listen: true);
      if (model.deleted) {
        children.add(const TextSpan(text: "<deleted message>"));
      } else if (emotes != null) {
        final parsed = parseEmotes(emotes);

        parsed.sort((a, b) => a.start.compareTo(b.start));

        var index = 0;

        for (final child in parsed) {
          if (child.start > index) {
            final substring = model.message.substring(index, child.start);
            children.addAll(processText(
                substring, bttvEmoteProvider, styleModel, linkStyle, tagStyle));
          }
          final url =
              "https://static-cdn.jtvnw.net/emoticons/v2/${child.key}/default/dark/1.0";
          children.add(WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Image(
                  image: NetworkImageWithRetry(url),
                  height: styleModel.fontSize)));
          index = child.end + 1;
        }

        if (index < model.message.length) {
          final substring = model.message.substring(index);
          children.addAll(processText(
              substring, bttvEmoteProvider, styleModel, linkStyle, tagStyle));
        }
      } else {
        children.addAll(processText(
            model.message, bttvEmoteProvider, styleModel, linkStyle, tagStyle));
      }

      // if messsage has links and clips, then fetch the first clip link
      // var fetchUrl = getFirstClipLink(model.message);
      // if (fetchUrl != null) {
      //   return (TwitchMessageLinkPreviewWidget(
      //       messageStyle: messageStyle, children: children, url: fetchUrl));
      // }
      return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: RichText(
            text: TextSpan(style: messageStyle, children: children),
          ));
    });
  }

  List<InlineSpan> processText(String message, ThirdPartyEmoteModel bttvEmotes,
      StyleModel styleModel, TextStyle linkStyle, TextStyle tagStyle) {
    final List<InlineSpan> children = [];
    var lastParsedStart = 0;
    for (var start = 0; start < message.length;) {
      final end = message.indexOf(" ", start) + 1;
      final token =
          end == 0 ? message.substring(start) : message.substring(start, end);
      final emote = bttvEmotes.bttvGlobalEmotes[token.trim()] ??
          bttvEmotes.bttvChannelEmotes[token.trim()] ??
          bttvEmotes.ffzEmotes[token.trim()];
      if (emote != null) {
        children.addAll(parseText(
            message.substring(lastParsedStart, start), linkStyle, tagStyle));
        children.add(WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Image(
                image: NetworkImageWithRetry(emote.source),
                height: styleModel.fontSize)));
        start = end == 0 ? message.length : end;
        lastParsedStart = start;
      } else {
        start = end == 0 ? message.length : end;
      }
    }
    if (lastParsedStart != message.length) {
      children.addAll(
          parseText(message.substring(lastParsedStart), linkStyle, tagStyle));
    }
    return children;
  }
}
