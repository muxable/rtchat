import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:linkify/linkify.dart';
import 'package:metadata_fetch/metadata_fetch.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/chat_history/twitch/badge.dart';
import 'package:rtchat/models/message.dart';
import 'package:rtchat/models/style.dart';
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

class _TwtichClipData {
  final imgUrl;
  final url;
  final title;
  final description;

  _TwtichClipData(this.imgUrl, this.url, this.title, this.description);
}

class _MessageLink {
  final url;
  final hasLink;

  _MessageLink(this.url, this.hasLink);

  bool isTwitchClip() {
    const twitchBaseUrl = 'www.twitch.tv';
    const clipStr = 'clip';
    if (url.contains(twitchBaseUrl) && url.contains(clipStr)) {
      return true;
    }
    return false;
  }
}

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

Color darken(Color color, [double amount = .1]) {
  assert(amount >= 0 && amount <= 1);

  final hsl = HSLColor.fromColor(color);
  final hslDark = hsl.withLightness((hsl.lightness) * (1 - amount));

  return hslDark.toColor();
}

Color lighten(Color color, [double amount = .1]) {
  assert(amount >= 0 && amount <= 1);

  final hsl = HSLColor.fromColor(color);
  final hslLight = hsl.withLightness((hsl.lightness) * (1 - amount) + amount);

  return hslLight.toColor();
}

_MessageLink hasLink(String text) {
  final parsed = linkify(text, options: const LinkifyOptions(humanize: false));
  for (final element in parsed) {
    if (element is LinkableElement) {
      return _MessageLink(element.url, true);
    }
  }
  return _MessageLink('', false);
}

Future<_TwtichClipData> fetchClipData(String url) async {
  var data = await MetadataFetch.extract(url);
  return _TwtichClipData(data!.image, data.url, data.title, data.description);
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
    final n = model.author.codeUnits.first + model.author.codeUnits.last;
    return colors[n % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StyleModel>(builder: (context, styleModel, child) {
      var authorColor = color;

      if (Theme.of(context).brightness == Brightness.dark) {
        authorColor = lighten(authorColor, styleModel.lightnessBoost);
      } else if (Theme.of(context).brightness == Brightness.light) {
        authorColor = darken(authorColor, styleModel.lightnessBoost);
      }

      var authorStyle = Theme.of(context).textTheme.bodyText2!.copyWith(
          fontSize: styleModel.fontSize,
          fontWeight: FontWeight.w500,
          color: authorColor);

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
      children.add(TextSpan(style: authorStyle, text: model.author));

      // add demarcator.
      switch (model.tags['message-type']) {
        case "action":
          children.add(const TextSpan(text: " "));
          break;
        case "chat":
          children.add(const TextSpan(text: ": "));
          break;
      }

      // add text.
      final emotes = model.tags['emotes-raw'];
      if (model.deleted) {
        children.add(const TextSpan(text: "<deleted message>"));
      } else if (emotes != null) {
        final parsed = parseEmotes(emotes);

        parsed.sort((a, b) => a.start.compareTo(b.start));

        var index = 0;

        for (final child in parsed) {
          if (child.start > index) {
            children.addAll(parseText(
              model.message.substring(index, child.start),
              linkStyle,
              tagStyle,
            ));
          }
          final url =
              "https://static-cdn.jtvnw.net/emoticons/v1/${child.key}/1.0";
          children.add(WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Image(
                  image: NetworkImage(url), height: styleModel.fontSize)));
          index = child.end + 1;
        }

        if (index < model.message.length) {
          children.addAll(parseText(
            model.message.substring(index),
            linkStyle,
            tagStyle,
          ));
        }
      } else {
        children.addAll(parseText(
          model.message,
          linkStyle,
          tagStyle,
        ));
      }

      // if messsage has link and link is a twitch clip
      var messageLink = hasLink(model.message);
      if (messageLink.hasLink && messageLink.isTwitchClip()) {
        return (Column(
          children: [
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: RichText(
                  text: TextSpan(style: messageStyle, children: children),
                )),
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: FutureBuilder(
                    future: fetchClipData(messageLink.url),
                    builder: (BuildContext context, AsyncSnapshot snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        return Card(
                          child: ListTile(
                            leading: Image.network(snapshot.data.imgUrl),
                            title: Text(snapshot.data.title),
                            subtitle: Text(snapshot.data.description),
                            isThreeLine: true,
                          ),
                        );
                      } else {
                        return const Card(child: CircularProgressIndicator());
                      }
                    }))
          ],
        ));
      }
      return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: RichText(
            text: TextSpan(style: messageStyle, children: children),
          ));
    });
  }
}
