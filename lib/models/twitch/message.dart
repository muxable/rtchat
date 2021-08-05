import 'package:linkify/linkify.dart';
import 'package:rtchat/models/message.dart';
import 'package:rtchat/models/messages/tokens.dart';
import 'package:rtchat/models/twitch/user.dart';

class _EmoteData {
  final int start;
  final int end;
  final String key;

  const _EmoteData(this.key, this.start, this.end);
}

class _BadgeData {
  final String key;
  final String version;

  const _BadgeData(this.key, this.version);
}

Iterable<MessageToken> tokenizeTags(Iterable<MessageToken> tokens) sync* {
  for (final token in tokens) {
    if (token is TextToken) {
      final matches = RegExp(r"(^|\W)@[A-Za-z0-9_]+").allMatches(token.text);
      var start = 0;
      for (final match in matches) {
        // before the tag
        var preTag =
            token.text.substring(start, match.start == 0 ? 0 : match.start + 1);
        yield TextToken(preTag);
        // the tag
        var tag = token.text
            .substring(match.start == 0 ? 1 : match.start + 2, match.end);
        start = match.end;
        yield UserMentionToken(tag);
      }

      if (matches.isNotEmpty) {
        var txt = token.text.substring(matches.last.end);
        if (txt.isNotEmpty) {
          yield TextToken(txt);
        }
      } else {
        yield TextToken(token.text);
      }
    } else {
      yield token;
    }
  }
}

Iterable<MessageToken> tokenizeLinks(Iterable<MessageToken> tokens) sync* {
  for (final token in tokens) {
    if (token is TextToken) {
      final elements =
          linkify(token.text, options: const LinkifyOptions(humanize: false));
      for (final element in elements) {
        if (element is LinkableElement) {
          yield LinkToken(url: element.url, text: element.text);
        } else {
          yield TextToken(element.text);
        }
      }
    } else {
      yield token;
    }
  }
}

Iterable<MessageToken> tokenizeEmotes(Iterable<MessageToken> tokens,
    String? Function(String) emoteResolver) sync* {
  for (final token in tokens) {
    if (token is TextToken) {
      var lastParsedStart = 0;
      final message = token.text;
      for (var start = 0; start < message.length;) {
        final end = message.indexOf(" ", start);
        final token = end == -1
            ? message.substring(start)
            : message.substring(start, end);
        final emote = emoteResolver(token.trim());
        if (emote != null) {
          if (lastParsedStart != start) {
            yield TextToken(message.substring(lastParsedStart, start));
          }
          yield EmoteToken(emote);
          lastParsedStart = end == -1 ? message.length : end;
        }
        start = end == -1 ? message.length : end + 1;
      }
      if (lastParsedStart != message.length) {
        yield TextToken(message.substring(lastParsedStart));
      }
    } else {
      yield token;
    }
  }
}

List<_EmoteData> parseEmotes(String emotes) {
  return emotes.split("/").expand((block) {
    final blockTokens = block.split(':');
    final key = blockTokens[0];
    return blockTokens[1].split(',').map((indices) {
      final indexTokens = indices.split('-');
      final start = int.parse(indexTokens[0]);
      final end = int.parse(indexTokens[1]);
      return _EmoteData(key, start, end);
    });
  }).toList();
}

List<_BadgeData> parseBadges(String badges) {
  if (badges.isEmpty) {
    return [];
  }
  return badges.split(",").map((block) {
    final tokens = block.split('/');
    final key = tokens[0];
    final version = tokens[1];
    return _BadgeData(key, version);
  }).toList();
}

Iterable<MessageToken> rootEmoteTokenizer(String message, String emotes) sync* {
  if (emotes.isNotEmpty) {
    final parsed = parseEmotes(emotes);
    parsed.sort((a, b) => a.start.compareTo(b.start));

    var index = 0;
    for (final child in parsed) {
      if (child.start > index) {
        final substring = message.substring(index, child.start);
        yield TextToken(substring);
      }
      final url =
          "https://static-cdn.jtvnw.net/emoticons/v2/${child.key}/default/dark/1.0";
      yield EmoteToken(url);
      index = child.end + 1;
    }

    if (index < message.length) {
      yield TextToken(message.substring(index));
    }
  } else {
    yield TextToken(message);
  }
}

class TwitchMessageModel extends MessageModel {
  final TwitchUserModel author;
  final String message;
  final Map<String, dynamic> tags;
  final DateTime timestamp;
  final bool deleted;
  final String channelId;

  TwitchMessageModel(
      {required String messageId,
      required this.author,
      required this.message,
      required this.tags,
      required this.timestamp,
      required this.deleted,
      required this.channelId})
      : super(messageId: messageId, pinned: null);

  bool get emoteOnly {
    return tags['emote-only'] == true;
  }

  bool get hasEmote {
    return tags['emotes'] != null ? true : false;
  }

  List<_BadgeData> get badges =>
      _badges ??= parseBadges(tags['badges-raw'] ?? "");
  List<_BadgeData>? _badges;

  List<MessageToken> tokenize(String? Function(String) emoteResolver) {
    Iterable<MessageToken> tokens =
        rootEmoteTokenizer(message, tags['emotes-raw'] ?? "");
    tokens = tokenizeLinks(tokens);
    tokens = tokenizeTags(tokens);
    tokens = tokenizeEmotes(tokens, emoteResolver);

    return tokens.toList();
  }
}
