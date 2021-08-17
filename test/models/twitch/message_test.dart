import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/models/messages/tokens.dart';
import 'package:rtchat/models/messages/twitch/message.dart';
import 'package:rtchat/models/messages/twitch/emote.dart';
import 'package:rtchat/models/messages/twitch/user.dart';

TwitchMessageModel createMessageModel(String? badgesRaw, String? emotesRaw,
    List<Emote> thirdPartyEmotes, String message) {
  return TwitchMessageModel(
      messageId: "placeholder",
      author: const TwitchUserModel(userId: 'muxfd', login: 'muxfd'),
      tags: {
        "message-type": "chat",
        "color": "#800000",
        "badges-raw": badgesRaw,
        "emotes-raw": emotesRaw,
        "room-id": "158394109",
      },
      thirdPartyEmotes: thirdPartyEmotes,
      timestamp: DateTime.now(),
      message: message,
      deleted: false,
      channelId: 'placeholder');
}

void main() {
  group("tokenize", () {
    test('empty text should tokenize', () {
      final model = createMessageModel(null, null, [], "");

      expect(model.tokenized, orderedEquals(const []));
    });

    test('regular text should tokenize', () {
      final model =
          createMessageModel(null, null, [], "random    text   moo cows   ");

      expect(model.tokenized,
          orderedEquals(const [TextToken("random    text   moo cows   ")]));
    });

    test('single tag should tokenize', () {
      final model = createMessageModel(null, null, [], "@muxfd");

      expect(
          model.tokenized,
          orderedEquals(const [
            UserMentionToken("muxfd"),
          ]));
    });

    test('multiple tag should tokenize', () {
      final model = createMessageModel(null, null, [], "@muxfd @muxfd");

      expect(
          model.tokenized,
          orderedEquals(const [
            UserMentionToken("muxfd"),
            TextToken(" "),
            UserMentionToken("muxfd"),
          ]));
    });

    test('adjacent tags should not tokenize', () {
      final model = createMessageModel(null, null, [], "@muxfd@muxfd");

      expect(
          model.tokenized,
          orderedEquals(const [
            UserMentionToken("muxfd"),
            TextToken("@muxfd"),
          ]));
    });

    test('text-leading tags should not tokenize', () {
      final model = createMessageModel(null, null, [], "muxfd@muxfd");

      expect(model.tokenized, orderedEquals(const [TextToken("muxfd@muxfd")]));
    });

    test('links should tokenize', () {
      final model = createMessageModel(
          null, null, [], "go visit http://moocows.com mooooo cows");

      expect(
          model.tokenized,
          orderedEquals([
            const TextToken("go visit "),
            LinkToken(
                url: Uri.parse("http://moocows.com"),
                text: "http://moocows.com"),
            const TextToken(" mooooo cows"),
          ]));
    });

    test('multiple links should tokenize', () {
      final model = createMessageModel(null, null, [],
          "go visit http://moocows.com mooooo http://whatwhat.com cows");

      expect(
          model.tokenized,
          orderedEquals([
            const TextToken("go visit "),
            LinkToken(
                url: Uri.parse("http://moocows.com"),
                text: "http://moocows.com"),
            const TextToken(" mooooo "),
            LinkToken(
                url: Uri.parse("http://whatwhat.com"),
                text: "http://whatwhat.com"),
            const TextToken(" cows"),
          ]));
    });

    test('third party emotes should token', () {
      final source = Uri.parse("https://3pemote");
      const code = "mooooo";

      final model = createMessageModel(
          null,
          null,
          [Emote(id: "", code: code, source: source)],
          "mooooo asdf mooooo cows mooooocows cowsmooooo mooooomooooo");

      expect(
          model.tokenized,
          orderedEquals([
            EmoteToken(url: source, code: code),
            const TextToken(" asdf "),
            EmoteToken(url: source, code: code),
            const TextToken(" cows mooooocows cowsmooooo mooooomooooo"),
          ]));
    });

    test('demo text should tokenize', () {
      final model = createMessageModel("premium/1", "25:36-40", [],
          "have you followed @muxfd on twitch? Kappa");

      expect(
          model.tokenized,
          orderedEquals([
            const TextToken("have you followed "),
            const UserMentionToken("muxfd"),
            const TextToken(" on twitch? "),
            EmoteToken(
                url: Uri.parse(
                    "https://static-cdn.jtvnw.net/emoticons/v2/25/default/dark/1.0"),
                code: "Kappa")
          ]));
    });
  });

  test('detect actions and commands', () {
    const author = TwitchUserModel(userId: 'muxfd', login: 'muxfd');

    final chatMessage = TwitchMessageModel(
        messageId: "placeholder",
        author: author,
        tags: {
          "message-type": "chat",
          "color": "#800000",
          "room-id": "158394109",
        },
        thirdPartyEmotes: [],
        timestamp: DateTime.now(),
        message: "moooo",
        deleted: false,
        channelId: 'placeholder');

    final chatCommand = TwitchMessageModel(
        messageId: "placeholder",
        author: author,
        tags: {
          "message-type": "chat",
          "color": "#800000",
          "room-id": "158394109",
        },
        thirdPartyEmotes: [],
        timestamp: DateTime.now(),
        message: "!moooo",
        deleted: false,
        channelId: 'placeholder');

    final actionMessage = TwitchMessageModel(
        messageId: "placeholder",
        author: author,
        tags: {
          "message-type": "action",
          "color": "#800000",
          "room-id": "158394109",
        },
        thirdPartyEmotes: [],
        timestamp: DateTime.now(),
        message: "mooooo",
        deleted: false,
        channelId: 'placeholder');

    final actionCommand = TwitchMessageModel(
        messageId: "placeholder",
        author: author,
        tags: {
          "message-type": "action",
          "color": "#800000",
          "room-id": "158394109",
        },
        thirdPartyEmotes: [],
        timestamp: DateTime.now(),
        message: "!mooooo",
        deleted: false,
        channelId: 'placeholder');

    expect(chatMessage.isAction, equals(false));
    expect(actionMessage.isAction, equals(true));
    expect(chatCommand.isAction, equals(false));
    expect(actionCommand.isAction, equals(true));

    expect(chatMessage.isCommand, equals(false));
    expect(actionMessage.isCommand, equals(false));
    expect(chatCommand.isCommand, equals(true));
    expect(actionCommand.isCommand, equals(false));
  });
}
