import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:linkify/linkify.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/layout.dart';
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

class Emote {
  final int _start;
  final int _end;
  final String _key;

  Emote(this._start, this._end, this._key);
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

Iterable<InlineSpan> parseText(String text, TextStyle linkStyle) {
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
                ..onTap = () async {
                  if (await canLaunch(element.url)) {
                    await launch(element.url);
                  } else {
                    throw 'Could not launch $element';
                  }
                }),
            ),
          ),
        ),
      );
    } else {
      return TextSpan(
        text: element.text,
      );
    }
  });
}

class TwitchMessageWidget extends StatelessWidget {
  final String _message;
  final String _type;
  final String _author;
  final String? _emotes;
  final String? _color;

  TwitchMessageWidget(
      {required String? color,
      required String type,
      required String author,
      required String message,
      required String? emotes})
      : _message = message,
        _type = type,
        _author = author,
        _color = color,
        _emotes = emotes;

  Color get color {
    if (_color != null) {
      return Color(int.parse("0xff${_color!.substring(1)}"));
    }
    final n = _author.codeUnits.first + _author.codeUnits.last;
    return COLORS[n % COLORS.length];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LayoutModel>(builder: (context, model, child) {
      var authorColor = color;

      if (Theme.of(context).brightness == Brightness.dark) {
        authorColor = lighten(authorColor, model.lightnessBoost);
      } else if (Theme.of(context).brightness == Brightness.light) {
        authorColor = darken(authorColor, model.lightnessBoost);
      }

      var authorStyle = Theme.of(context)
          .textTheme
          .bodyText2!
          .copyWith(fontSize: model.fontSize, color: authorColor);

      var messageStyle = Theme.of(context)
          .textTheme
          .bodyText2!
          .copyWith(fontSize: model.fontSize);

      final linkStyle = Theme.of(context).textTheme.bodyText2!.copyWith(
          fontSize: model.fontSize, color: Theme.of(context).accentColor);

      final List<InlineSpan> children = [
        TextSpan(style: authorStyle, text: _author),
      ];

      switch (_type) {
        case "action":
          children.add(TextSpan(text: " "));
          break;
        case "chat":
          children.add(TextSpan(text: ": "));
          break;
      }

      if (_emotes != null) {
        final parsed = _emotes!.split("/").expand((block) {
          final blockTokens = block.split(':');
          final key = blockTokens[0];
          return blockTokens[1].split(',').map((indices) {
            final indexTokens = indices.split('-');
            final start = int.parse(indexTokens[0]);
            final end = int.parse(indexTokens[1]);
            return Emote(start, end, key);
          });
        }).toList();

        parsed.sort((a, b) => a._start.compareTo(b._start));

        var index = 0;

        parsed.forEach((child) {
          if (child._start > index) {
            children.addAll(
                parseText(_message.substring(index, child._start), linkStyle));
          }
          final url =
              "https://static-cdn.jtvnw.net/emoticons/v1/${child._key}/4.0";
          children.add(WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Image(image: NetworkImage(url), height: model.fontSize)));
          index = child._end + 1;
        });

        if (index < _message.length) {
          children.addAll(parseText(_message.substring(index), linkStyle));
        }
      } else {
        children.addAll(parseText(_message, linkStyle));
      }
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: RichText(
          text: TextSpan(
            style: messageStyle,
            children: children,
          ),
        ),
      );
    });
  }
}
