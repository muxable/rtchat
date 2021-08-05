import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/models/messages/twitch/message.dart';
import 'package:rtchat/models/messages/twitch/user.dart';

TwitchMessageModel createMessageModel(
    String? badgesRaw, String? emotesRaw, String message) {
  return TwitchMessageModel(
      messageId: "placeholder",
      author: const TwitchUserModel(login: 'muxfd'),
      tags: {
        "message-type": "chat",
        "color": "#800000",
        "badges-raw": badgesRaw,
        "emotes-raw": emotesRaw,
        "room-id": "158394109",
      },
      timestamp: DateTime.now(),
      message: message,
      deleted: false,
      channelId: 'placeholder');
}

void main() {
  group("tokenize", () {
    test('empty text should tokenize', () {
      final model = createMessageModel(null, null, "");
      final tokens = model.tokenize((s) => null); // no third party emotes.

      expect(tokens, orderedEquals(const []));
    });

    test('regular text should tokenize', () {
      final model =
          createMessageModel(null, null, "random    text   moo cows   ");
      final tokens = model.tokenize((s) => null); // no third party emotes.

      expect(tokens,
          orderedEquals(const [TextToken("random    text   moo cows   ")]));
    });

    test('single tag should tokenize', () {
      final model = createMessageModel(null, null, "@muxfd");
      final tokens = model.tokenize((s) => null); // no third party emotes.

      expect(
          tokens,
          orderedEquals(const [
            UserMentionToken("muxfd"),
          ]));
    });

    test('multiple tag should tokenize', () {
      final model = createMessageModel(null, null, "@muxfd @muxfd");
      final tokens = model.tokenize((s) => null); // no third party emotes.

      expect(
          tokens,
          orderedEquals(const [
            UserMentionToken("muxfd"),
            TextToken(" "),
            UserMentionToken("muxfd"),
          ]));
    });

    test('adjacent tags should not tokenize', () {
      final model = createMessageModel(null, null, "@muxfd@muxfd");
      final tokens = model.tokenize((s) => null); // no third party emotes.

      expect(
          tokens,
          orderedEquals(const [
            UserMentionToken("muxfd"),
            TextToken("@muxfd"),
          ]));
    });

    test('text-leading tags should not tokenize', () {
      final model = createMessageModel(null, null, "muxfd@muxfd");
      final tokens = model.tokenize((s) => null); // no third party emotes.

      expect(tokens, orderedEquals(const [TextToken("muxfd@muxfd")]));
    });

    test('links should tokenize', () {
      final model = createMessageModel(
          null, null, "go visit http://moocows.com mooooo cows");
      final tokens = model.tokenize((s) => null); // no third party emotes.

      expect(
          tokens,
          orderedEquals(const [
            TextToken("go visit "),
            LinkToken(url: "http://moocows.com", text: "http://moocows.com"),
            TextToken(" mooooo cows"),
          ]));
    });

    test('multiple links should tokenize', () {
      final model = createMessageModel(null, null,
          "go visit http://moocows.com mooooo http://whatwhat.com cows");
      final tokens = model.tokenize((s) => null); // no third party emotes.

      expect(
          tokens,
          orderedEquals(const [
            TextToken("go visit "),
            LinkToken(url: "http://moocows.com", text: "http://moocows.com"),
            TextToken(" mooooo "),
            LinkToken(url: "http://whatwhat.com", text: "http://whatwhat.com"),
            TextToken(" cows"),
          ]));
    });

    test('third party emotes should token', () {
      final model = createMessageModel(null, null,
          "mooooo asdf mooooo cows mooooocows cowsmooooo mooooomooooo");
      final tokens = model.tokenize((s) {
        if (s == "mooooo") {
          return "3pemote";
        }
      }); // no third party emotes.

      expect(
          tokens,
          orderedEquals(const [
            EmoteToken("3pemote"),
            TextToken(" asdf "),
            EmoteToken("3pemote"),
            TextToken(" cows mooooocows cowsmooooo mooooomooooo"),
          ]));
    });

    test('demo text should tokenize', () {
      final model = createMessageModel(
          "premium/1", "25:36-40", "have you followed @muxfd on twitch? Kappa");
      final tokens = model.tokenize((s) => null); // no third party emotes.

      expect(
          tokens,
          orderedEquals(const [
            TextToken("have you followed "),
            UserMentionToken("muxfd"),
            TextToken(" on twitch? "),
            EmoteToken(
                "https://static-cdn.jtvnw.net/emoticons/v2/25/default/dark/1.0")
          ]));
    });
  });
}
