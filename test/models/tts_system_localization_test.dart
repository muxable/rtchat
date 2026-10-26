import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/messages/twitch/user.dart';
import 'package:rtchat/models/tts.dart';
import 'package:rtchat/models/views.dart';

import '../fakes/fake_tts_engine.dart';
import 'tts_model_test.dart' show createMessage;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final english = lookupAppLocalizations(const Locale('en'));
  final german = lookupAppLocalizations(const Locale('de'));

  test(
    'mode announcements use reading-language text and a matching system voice',
    () async {
      final engine = FakeTtsEngine();
      final model = TtsModel.fromJson({'language': 'de'}, engine: engine);
      addTearDown(model.dispose);
      for (final mode in [
        TtsMode.enabled,
        TtsMode.alertsOnly,
        TtsMode.disabled,
      ]) {
        model.setMode(english, mode);
        await pumpEventQueue();
      }
      expect(engine.spoken, [
        german.textToSpeechEnabled,
        german.alertsEnabled,
        german.textToSpeechDisabled,
      ]);
      expect(engine.utterances.map((u) => u.language), ['de', 'de', 'de']);
    },
  );

  test(
    'announcements follow the primary stream language instead of the UI',
    () async {
      final engine = FakeTtsEngine();
      final model = TtsModel.fromJson(
        {'language': 'en'},
        engine: engine,
        lookUpStreamLanguage: (_) async => 'ja',
      );
      addTearDown(model.dispose);
      model.update(
        ViewsModel()..openChannel(Channel(Providers.twitch, '1', 'stream')),
      );
      await pumpEventQueue();
      model.setMode(english, TtsMode.enabled);
      await pumpEventQueue();
      expect(
        engine.spoken.single,
        lookupAppLocalizations(const Locale('ja')).textToSpeechEnabled,
      );
      expect(engine.utterances.single.language, 'ja');
    },
  );

  test(
    'regional language tags select their translated parent locale',
    () async {
      final engine = FakeTtsEngine();
      final model = TtsModel.fromJson({'language': 'pt-BR'}, engine: engine);
      addTearDown(model.dispose);
      model.setMode(english, TtsMode.enabled);
      await pumpEventQueue();
      expect(
        engine.spoken.single,
        lookupAppLocalizations(const Locale('pt')).textToSpeechEnabled,
      );
      expect(engine.utterances.single.language, 'pt');
    },
  );

  test(
    'untranslated languages keep the UI text and its matching voice',
    () async {
      final engine = FakeTtsEngine();
      final model = TtsModel.fromJson({'language': 'fi'}, engine: engine);
      addTearDown(model.dispose);
      model.setMode(german, TtsMode.enabled);
      await pumpEventQueue();
      expect(engine.spoken.single, german.textToSpeechEnabled);
      expect(engine.utterances.single.language, 'de');
    },
  );

  test('backlog announcement uses the same localized speech policy', () async {
    final engine = FakeTtsEngine()..holdSpeech = true;
    final model = TtsModel.fromJson({'language': 'de'}, engine: engine);
    addTearDown(() {
      engine.finishSpeaking();
      model.dispose();
    });
    model.setMode(english, TtsMode.enabled);
    await pumpEventQueue();
    for (var i = 0; i < 25; i++) {
      model.say(
        english,
        createMessage(
          'message $i',
          messageId: 'localized-$i',
          author: TwitchUserModel(userId: '$i', login: 'user$i'),
        ),
      );
    }
    await pumpEventQueue();
    expect(model.mode, TtsMode.disabled);
    expect(engine.spoken.last, german.textToSpeechTooManyMessages);
    expect(engine.utterances.last.language, 'de');
  });
}
