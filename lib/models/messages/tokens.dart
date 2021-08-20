import 'package:flutter/foundation.dart';

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

  bool get isWhitespace => text.trim().isEmpty;

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

class CompactedToken extends MessageToken {
  final List<MessageToken> children;
  final int multiplicity;

  const CompactedToken(this.children, this.multiplicity);

  @override
  bool operator ==(other) =>
      other is CompactedToken && listEquals(children, other.children);

  @override
  int get hashCode =>
      children.map((child) => child.hashCode).reduce((a, b) => a ^ b);

  @override
  String toString() => children.toString();
}

extension IterableMessageToken<T extends MessageToken> on Iterable<T> {
  /// Returns the shortest repeating tokenization.
  Iterable<MessageToken> get compacted sync* {
    // TODO: We can be more clever around partial compactions.
    final list = toList();
    for (var length = 1; length <= list.length / 2; length++) {
      final last = list[length - 1];
      final isSpaceDelimited = last is TextToken && last.isWhitespace;
      if ((list.length + (isSpaceDelimited ? 1 : 0)) % length != 0) {
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
        yield CompactedToken(
            list.sublist(0, length - (isSpaceDelimited ? 1 : 0)),
            (list.length + (isSpaceDelimited ? 1 : 0)) ~/ length);
        return;
      }
    }
    yield* list;
  }
}
