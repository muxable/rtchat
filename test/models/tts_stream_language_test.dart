import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/messages/message.dart';
import 'package:rtchat/models/messages/twitch/user.dart';
import 'package:rtchat/models/tts.dart';
import 'package:rtchat/models/views.dart';

import '../fakes/fake_tts_engine.dart';
import 'tts_model_test.dart' show createMessage;

var _messages = 0;

MessageModel chat(String text, {String userId = '1', Channel? channel}) =>
    createMessage(
      text,
      messageId: 'm${_messages++}',
      author: TwitchUserModel(userId: userId, login: 'user$userId'),
    )..channel = channel;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => initializeDateFormatting('en'));

  final l10n = lookupAppLocalizations(const Locale('en'));
  final spanish = Channel(Providers.twitch, 'es', 'es');
  final chinese = Channel(Providers.kick, 'zh', 'zh');

  late Map<Channel, Completer<String?>> lookups;
  late Map<Channel, int> lookupCounts;
  late DateTime now;
  late FakeTtsEngine engine;
  late TtsModel model;
  late ViewsModel views;

  /// Answers [channel]'s pending lookup with [language].
  Future<void> answer(Channel channel, String? language) async {
    lookups.remove(channel)!.complete(language);
    await pumpEventQueue();
  }

  String languageOf(Channel channel) =>
      model.languageFor(chat('hi', channel: channel)).languageCode;

  setUp(() async {
    lookups = {};
    lookupCounts = {};
    now = DateTime(2026);
    engine = FakeTtsEngine();
    model = TtsModel.fromJson(
      {'language': 'fr'},
      engine: engine,
      clock: () => now,
      lookUpStreamLanguage: (channel) {
        lookupCounts[channel] = (lookupCounts[channel] ?? 0) + 1;
        return (lookups[channel] = Completer<String?>()).future;
      },
    );
    views = ViewsModel()..openChannel(spanish);
  });

  test('looks each channel up once, however often the views change', () async {
    model.update(views);
    model.update(views);
    await answer(spanish, 'es');
    model.update(views..addChannel(chinese));
    model.update(views);
    await answer(chinese, 'zh');
    model.update(views);

    expect(lookupCounts, {spanish: 1, chinese: 1});
    expect(languageOf(spanish), 'es');
    expect(languageOf(chinese), 'zh');
  });

  test('looks a channel up again once it is shown again', () async {
    model.update(views);
    await answer(spanish, 'es');
    model.update(views..openChannel(chinese));
    model.update(views..openChannel(spanish));
    expect(lookupCounts[spanish], 2);
  });

  test('ignores a lookup that ends after its channel was closed', () async {
    model.update(views);
    model.update(views..openChannel(chinese));
    await answer(spanish, 'es');
    expect(languageOf(spanish), 'fr');
  });

  test('unknown languages fall back to the saved language', () async {
    for (final code in [null, '', 'other', 'asl']) {
      expect(TtsModel.streamLanguage(code), isNull, reason: '$code');
    }
    expect(TtsModel.streamLanguage(' ES ')?.languageCode, 'es');

    model.update(views);
    await answer(spanish, 'other');
    expect(languageOf(spanish), 'fr');
  });

  test(
    'an unknown language is retried after a while, not on every change',
    () async {
      model.update(views);
      lookups.remove(spanish)!.completeError(StateError('offline'));
      await pumpEventQueue();

      now = now.add(const Duration(minutes: 1));
      model.update(views);
      expect(lookupCounts[spanish], 1);

      now = now.add(TtsModel.languageRetryInterval);
      model.update(views);
      expect(lookupCounts[spanish], 2);
      await answer(spanish, 'es');
      expect(languageOf(spanish), 'es');
    },
  );

  test('never changes the saved language or saves the settings', () async {
    var notified = 0;
    model.addListener(() => notified++);
    model.update(views);
    await answer(spanish, 'es');

    expect(model.language.languageCode, 'fr');
    expect(model.toJson()['language'], 'fr');
    expect(notified, 0);
  });

  test('the system voice is only told a known stream language', () async {
    model.setMode(l10n, TtsMode.enabled);
    await pumpEventQueue();
    engine.utterances.clear();
    model.update(views..addChannel(chinese));
    await answer(spanish, 'asl');
    await answer(chinese, 'zh');

    model.say(l10n, chat('hola', channel: spanish));
    model.say(l10n, chat('ni hao', userId: '2', channel: chinese));
    await pumpEventQueue();
    expect(engine.utterances.map((u) => u.language), [null, 'zh']);
  });
}
