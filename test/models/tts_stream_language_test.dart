import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/tts.dart';
import 'package:rtchat/models/tts/language.dart';
import 'package:rtchat/models/views.dart';

import '../fakes/fake_tts_engine.dart';
import 'tts_voice_selection_test.dart' show chat;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => initializeDateFormatting('en'));

  final l10n = lookupAppLocalizations(const Locale('en'));
  final spanish = Channel(Providers.twitch, 'es', 'es');
  final chinese = Channel(Providers.kick, 'zh', 'zh');

  late Map<Channel, Completer<String?>> lookups;
  late Map<Channel, int> lookupCounts;
  late DateTime now;
  late FakeTtsEngine system;
  late FakeTtsEngine neural;
  late TtsModel model;
  late ViewsModel views;

  /// Answers [channel]'s pending lookup with [language].
  Future<void> answer(Channel channel, String? language) async {
    lookups.remove(channel)!.complete(language);
    await pumpEventQueue();
  }

  setUp(() async {
    lookups = {};
    lookupCounts = {};
    now = DateTime(2026);
    system = FakeTtsEngine();
    neural = FakeTtsEngine(availableVoices: packVoices(['en', 'es', 'fr']));
    model = TtsModel.fromJson(
      {'language': 'fr'},
      engine: system,
      reportError: (e, _) => fail('$e'),
      clock: () => now,
      lookUpStreamLanguage: (channel) {
        lookupCounts[channel] = (lookupCounts[channel] ?? 0) + 1;
        return (lookups[channel] = Completer<String?>()).future;
      },
    );
    model.neuralEngine = neural;
    model.setMode(l10n, TtsMode.enabled);
    await pumpEventQueue();
    neural.utterances.clear();
    views = ViewsModel()..openChannel(spanish);
  });

  test('reads chat in its stream language once it is known', () async {
    model.update(views);
    await answer(spanish, 'es');

    model.say(l10n, chat('hola', channel: spanish));
    await pumpEventQueue();
    expect(neural.utterances.single.language, 'es');
  });

  test('looks each channel up once, however often the views change', () async {
    model.update(views);
    model.update(views);
    await answer(spanish, 'es');
    views.addChannel(chinese);
    model.update(views);
    model.update(views);
    await answer(chinese, 'zh');
    model.update(views);

    expect(lookupCounts, {spanish: 1, chinese: 1});
  });

  test('looks a channel up again once it is shown again', () async {
    model.update(views);
    await answer(spanish, 'es');
    model.update(views..openChannel(chinese));
    await answer(chinese, 'zh');
    model.update(views..openChannel(spanish));
    expect(lookupCounts[spanish], 2);
  });

  test('ignores a lookup that ends after its channel was closed', () async {
    model.update(views);
    model.update(views..openChannel(chinese));
    await answer(spanish, 'es');

    model.say(l10n, chat('hola', channel: spanish));
    await pumpEventQueue();
    expect(neural.utterances.single.language, 'fr');
  });

  test('unknown languages fall back to the saved language', () async {
    for (final code in [null, '', 'other', 'asl']) {
      expect(TtsModel.streamLanguage(code), isNull, reason: '$code');
    }
    expect(TtsModel.streamLanguage(' ES ')?.languageCode, 'es');

    model.update(views);
    await answer(spanish, 'other');
    model.say(l10n, chat('hola', channel: spanish));
    await pumpEventQueue();

    expect(neural.utterances.single.language, 'fr');
  });

  test('the system voice is only told a known stream language', () async {
    model.neuralEngine = null;
    views.addChannel(chinese);
    model.update(views);
    await answer(spanish, 'asl');
    await answer(chinese, 'zh');

    model.say(l10n, chat('hola', channel: spanish));
    model.say(l10n, chat('ni hao', userId: '2', channel: chinese));
    await pumpEventQueue();
    expect(system.utterances.map((u) => u.language), [null, 'zh']);
  });

  test('a failed lookup is retried after a while, not on every change',
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
    model.say(l10n, chat('hola', channel: spanish));
    await pumpEventQueue();
    expect(neural.utterances.single.language, 'es');
  });

  test('a channel without a language yet is retried after a while', () async {
    model.update(views);
    await answer(spanish, null);
    model.update(views);
    expect(lookupCounts[spanish], 1);

    now = now.add(TtsModel.languageRetryInterval);
    model.update(views);
    expect(lookupCounts[spanish], 2);
  });

  test('a throwing lookup leaves the language unknown', () async {
    final throwing = TtsModel.fromJson({'language': 'fr'},
        engine: system,
        reportError: (e, _) => fail('$e'),
        lookUpStreamLanguage: (_) => throw StateError('no firebase'));
    throwing.update(views);
    await pumpEventQueue();
    expect(throwing.languageFor(chat('hola', channel: spanish)).languageCode,
        'fr');
  });

  test('uses the language a channel was found with until it is looked up',
      () async {
    final found = Channel(Providers.twitch, 'es', 'es', language: 'es');
    model.update(views..openChannel(found));
    expect(model.languageFor(chat('hola', channel: found)).languageCode, 'es');
    await answer(found, 'pt');
    expect(model.languageFor(chat('oi', channel: found)).languageCode, 'pt');
  });

  test('messages without a channel use the first channel\'s language',
      () async {
    model.update(views);
    await answer(spanish, 'es');
    expect(model.languageFor(chat('hola')).languageCode, 'es');
  });

  test('never changes the saved language or saves the settings', () async {
    var notified = 0;
    model.addListener(() => notified++);
    model.update(views);
    await answer(spanish, 'es');

    expect(model.language.languageCode, 'fr');
    expect(model.toJson()['language'], 'fr');
    expect(notified, 0);
  });

  test('the saved language is used without channels', () async {
    model.update(ViewsModel());
    model.say(l10n, chat('bonjour'));
    await pumpEventQueue();
    expect(neural.utterances.single.language, 'fr');
    expect(model.language, isA<Language>());
  });
}
