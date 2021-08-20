abstract class MessageToken {
  const MessageToken();
}

class UserMentionToken extends MessageToken {
  final String username;

  const UserMentionToken(this.username);

  @override
  bool operator ==(other) =>
      other is UserMentionToken && username == other.username;

  @override
  int get hashCode => username.hashCode;

  @override
  String toString() => "@$username";
}

class TextToken extends MessageToken {
  final String text;

  const TextToken(this.text);

  @override
  bool operator ==(other) => other is TextToken && text == other.text;

  @override
  int get hashCode => text.hashCode;

  @override
  String toString() => text;
}

class LinkToken extends MessageToken {
  final Uri url;
  final String text;

  const LinkToken({required this.url, required this.text});

  @override
  bool operator ==(other) =>
      other is LinkToken && other.url == url && other.text == text;

  @override
  int get hashCode => url.hashCode ^ text.hashCode;

  @override
  String toString() => text;
}

class EmoteToken extends MessageToken {
  final Uri url;
  final String code;

  const EmoteToken({required this.url, required this.code});

  @override
  bool operator ==(other) => other is EmoteToken && url == other.url;

  @override
  int get hashCode => url.hashCode;

  @override
  String toString() => code;
}

class _CompactionResult {
  final Iterable<MessageToken> tokens;
  final int multiplicity;

  const _CompactionResult(this.tokens, this.multiplicity);
}

extension IterableMessageToken<T extends MessageToken> on Iterable<T> {
  /// Returns the shortest repeating tokenization.
  _CompactionResult get compacted {
    final list = toList();
    for (var length = 1; length <= list.length / 2; length++) {
      if (list.length % length != 0) {
        // must be a divisor of the list length.
        continue;
      }
      var repeating = true;
      for (var index = length; index < list.length; index++) {
        if (list[index] != list[index % length]) {
          repeating = false;
          break;
        }
      }
      if (repeating) {
        return _CompactionResult(
            list.sublist(0, length), list.length ~/ length);
      }
    }
    return _CompactionResult(list, 1);
  }
}
