import 'package:flutter/material.dart';
import 'package:rtchat/models/messages/twitch/emote.dart';

class EmoteTextEditingController extends TextEditingController {
  final List<Emote> emotes = [];

  void addEmote(Emote emote) {
    emotes.add(emote);

    final textParts = text.split(' ');
    textParts.removeLast();
    final newText = '${textParts.join(' ')} ${emote.code} ';

    value = value.copyWith(
      text: newText,
      selection:
          TextSelection.fromPosition(TextPosition(offset: newText.length)),
      composing: TextRange.empty,
    );
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final text = this.text;
    final textSpans = <InlineSpan>[];

    final words = text.split(' ');
    for (var word in words) {
      final emote = emotes.firstWhere(
        (emote) => emote.code == word,
        orElse: () =>
            Emote(provider: '', category: '', id: '', code: '', imageUrl: ''),
      );

      if (emote.code.isNotEmpty && emote.imageUrl.isNotEmpty) {
        textSpans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Image.network(
            emote.imageUrl,
            width: 24,
            height: 24,
          ),
        ));
      } else {
        textSpans.add(TextSpan(
          text: '$word ',
          style: style,
        ));
      }
    }

    return TextSpan(children: textSpans, style: style);
  }
}
