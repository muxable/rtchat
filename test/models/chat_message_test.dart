import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/messages.dart';
import 'package:rtchat/models/messages/kick/event.dart';
import 'package:rtchat/models/messages/kick/user.dart';
import 'package:rtchat/models/messages/twitch/user.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/messages/message.dart';
import 'package:rtchat/models/tts.dart';
import 'package:rtchat/models/tts/language.dart';

import '../fakes/fake_chat.dart';
import '../fakes/fake_tts_engine.dart';

final t0 = DateTime(2024, 1, 1);

FakeChatMessage fakeMessage(
  String text, {
  String id = 'm',
  DateTime? at,
  FakeChatUser? author,
}) => FakeChatMessage(
  messageId: id,
  timestamp: at ?? t0,
  author:
      author ??
      const FakeChatUser(userId: '7', login: 'kicker', displayName: 'Kicker'),
  message: text,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final l10n = lookupAppLocalizations(const Locale('en'));

  test("tts vocalizes chat from any provider", () {
    final model = TtsModel.fromJson({}, engine: FakeTtsEngine());
    expect(
      model.getVocalization(
        l10n,
        fakeMessage("hello"),
        includeAuthorPrelude: true,
      ),
      l10n.saidMessage("Kicker", "hello"),
    );
  });

  test("muting is scoped to the user's provider", () {
    final model = TtsModel.fromJson({}, engine: FakeTtsEngine());
    model.mute(const TwitchUserModel(userId: '1', login: 'kicker'));
    expect(
      model.isMuted(const TwitchUserModel(userId: '1', login: 'kicker')),
      isTrue,
    );
    // same login on another provider is a different person.
    expect(
      model.isMuted(const FakeChatUser(userId: '7', login: 'kicker')),
      isFalse,
    );
  });

  test("separators count chat messages from any provider", () {
    final messages = [
      for (var i = 0; i < 60; i++)
        fakeMessage("m$i", id: "m$i", at: t0.add(Duration(seconds: i))),
    ];
    expect(computeSeparators(messages).toList()..sort(), [0, 49]);
  });

  test("authors include users from any provider", () {
    final model = MessagesModel.fromJson({});
    model.messages.add(fakeMessage("hi"));
    expect(model.authors.single.login, "kicker");
  });

  test("tts announces kick events without markup", () {
    final model = TtsModel.fromJson({}, engine: FakeTtsEngine());
    const kicker = KickUserModel(
      userId: '7',
      login: 'kicker',
      displayName: 'Kicker',
    );
    expect(
      model.getVocalization(
        l10n,
        KickSubscriptionEventModel(
          messageId: 's',
          timestamp: t0,
          subscriber: kicker,
          months: 1,
          isRenewal: false,
        ),
      ),
      "Kicker has subscribed!",
    );
    expect(
      model.getVocalization(
        l10n,
        KicksGiftedEventModel(
          messageId: 'k',
          timestamp: t0,
          sender: kicker,
          amount: 50,
          giftName: 'Hype',
        ),
      ),
      "Kicker sent 50 Kicks!",
    );
  });

  test("messages are read in their channel's language", () {
    final model = TtsModel.fromJson({
      'language': 'en',
    }, engine: FakeTtsEngine());
    final japanese = Channel(Providers.kick, '9', 'jp');
    model.setChannelLanguage(japanese, Language('ja'));
    final fromJapanese = fakeMessage("konnichiwa")..channel = japanese;
    expect(model.languageFor(fromJapanese).languageCode, 'ja');
    // messages from channels without a known language use the default.
    expect(model.languageFor(fakeMessage("hi")).languageCode, 'en');
  });
}
