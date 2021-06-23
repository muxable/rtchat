import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:linkify/linkify.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/twitch/badge.dart';
import 'package:rtchat/models/message.dart';
import 'package:rtchat/models/style.dart';
import 'package:url_launcher/url_launcher.dart';

const COLORS = [
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

dynamic tokenize(msg) {
  // find out all parts where the first character is the @ symbol
  var parts = msg.split(new RegExp('\\s+'));
  var tokens = [];
  var allowableSet =
      '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz_@';
  var tags = new Set();
  for (var i = 0; i < parts.length; i++) {
    var part = parts[i];
    if (part.length > 1 && part[0] == '@') {
      // check all char is either a num or a alphabet
      var flag = true;
      for (var j = 1; j < part.length; j++) {
        if (j > 0 && part[j] == '@') {
          flag = false;
          break;
        }
        if (j > 0 && !allowableSet.contains(part[j])) {
          flag = false;
          break;
        }
      }
      if (flag) {
        tags.add(part);
      }
    }
  }
  // print("tags set: $tags");
  var i = 0;
  while (i < msg.length) {
    if (msg[i] == '@') {
      var j = i + 1;
      while (j < msg.length && msg[j] != ' ' && msg[j] != '@') {
        j += 1;
      }
      var cand = msg.substring(i, j);
      if (tags.contains(cand)) {
        tokens.add([cand, 'tag']);
      } else {
        tokens.add([cand, 'regular']);
      }
      i = j;
    } else {
      var j = i + 1;
      while (j < msg.length && msg[j] != '@') {
        j += 1;
      }
      tokens.add([msg.substring(i, j), 'regular']);
      i = j;
    }
  }
  return tokens;
}

Iterable<TextSpan> getTextSpans(dynamic lst, TextStyle tagStyle) sync* {
  for (var i = 0; i < lst.length; i++) {
    var item = lst[i];
    if (lst[1] == 'tag') {
      yield TextSpan(text: item[0], style: tagStyle);
    } else {
      yield TextSpan(text: item[0]); // plain text;
    }
  }
}

Iterable<InlineSpan> parseText(
    String text, TextStyle linkStyle, TextStyle tagStyle) {
  final parsed = linkify(text, options: LinkifyOptions(humanize: false));
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
      var lst = tokenize(element.text);
      print("tokens are: $lst");
      // sample of lst: [[@rippyae, tag], [ fffff, regular]]
      // how to return both TextSpan with a single widget;
      // for (var i = 0; i < lst.length; i++) {
      //   var item = lst[i];
      //   if (lst[1] == 'tag') {
      //     return TextSpan(text: lst[0], style: tagStyle);
      //   } else {
      //     return TextSpan(text: lst[0]); // plain text;
      //   }
      // // }
      return TextSpan(
        text: element.text,
      );
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
  final bool coalesce;

  TwitchMessageWidget(this.model, {this.coalesce = false});

  Color get color {
    final color = model.tags['color'];
    if (color != null) {
      return Color(int.parse("0xff${color.substring(1)}"));
    }
    final n = model.author.codeUnits.first + model.author.codeUnits.last;
    return COLORS[n % COLORS.length];
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

      final tagStyle = Theme.of(context).textTheme.bodyText2!.copyWith(
          fontSize: styleModel.fontSize,
          color: Colors.redAccent,
          fontWeight: FontWeight.bold);

      final List<InlineSpan> children = [];

      if (!styleModel.aggregateSameAuthor || !coalesce) {
        // add badges.
        final badges = parseBadges(model.tags['badges-raw'] ?? "");
        children.addAll(badges.map((badge) => WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
                padding: EdgeInsets.only(right: 5),
                child: TwitchBadgeWidget(
                    channelId: model.tags['room-id'],
                    badge: badge.key,
                    version: badge.version,
                    height: styleModel.fontSize)))));

        // add author.
        children.add(TextSpan(style: authorStyle, text: model.author));
        // print("the text send is: ${model.message}");
        // add demarcator.
        switch (model.tags['message-type']) {
          case "action":
            children.add(TextSpan(text: " "));
            break;
          case "chat":
            children.add(TextSpan(text: ": "));
            break;
        }
      }

      // for (var i = 0; i < tagIndices.length; i++) {
      //   var indices = tagIndices[i];
      //   var a = indices[0];
      //   var b = indices[1];
      //   print("tag: ${model.message.substring(a, b)}");
      // }

      // add text.
      final emotes = model.tags['emotes-raw'];
      if (model.deleted) {
        children.add(TextSpan(text: "<deleted message>"));
      } else if (emotes != null) {
        final parsed = parseEmotes(emotes);

        parsed.sort((a, b) => a.start.compareTo(b.start));

        var index = 0;

        parsed.forEach((child) {
          if (child.start > index) {
            children.addAll(parseText(
              model.message.substring(index, child.start),
              linkStyle,
              tagStyle,
            ));
          }
          final url =
              "https://static-cdn.jtvnw.net/emoticons/v1/${child.key}/4.0";
          children.add(WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Image(
                  image: NetworkImage(url), height: styleModel.fontSize)));
          index = child.end + 1;
        });

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
      return Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: RichText(
            text: TextSpan(style: messageStyle, children: children),
          ));
    });
  }
}
