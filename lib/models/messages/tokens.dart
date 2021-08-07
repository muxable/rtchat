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
