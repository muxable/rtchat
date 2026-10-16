// Reads chat aloud through the app's TtsModel queue with the real
// NeuralTtsEngine and a Supertonic 3 model on a device. It skips itself
// unless ON_DEVICE_TTS_MODEL_DIR is set, so the regular integration run
// (which has no model) passes over it. Push the model with
// packages/on_device_tts/tool/push_model.sh, then:
//
//     flutter test integration_test/neural_tts_engine_test.dart -d <device> \
//         --dart-define=ON_DEVICE_TTS_MODEL_DIR=/data/user/0/com.rtirl.chat/files/supertonic-3

import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:on_device_tts/on_device_tts.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/messages/message.dart';
import 'package:rtchat/models/tts.dart';
import 'package:rtchat/models/tts/language.dart';

import '../test/fakes/fake_chat.dart';
import '../test/fakes/fake_tts_engine.dart';

const modelDir = String.fromEnvironment('ON_DEVICE_TTS_MODEL_DIR');

FakeChatMessage chat(String text, int i) => FakeChatMessage(
    messageId: 'm$i-${DateTime.now().microsecondsSinceEpoch}',
    timestamp: DateTime.now(),
    author: FakeChatUser(userId: '$i', login: 'user$i'),
    message: text);

Future<void> waitFor(bool Function() condition) async {
  final deadline = DateTime.now().add(const Duration(seconds: 90));
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) fail('timed out');
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  if (modelDir.isEmpty) {
    testWidgets('neural TTS (needs ON_DEVICE_TTS_MODEL_DIR)', (_) async {},
        skip: true);
    return;
  }

  final l10n = lookupAppLocalizations(const Locale('en'));
  final events = <OnnxTtsEvent>[];
  late StreamSubscription<OnnxTtsEvent> eventSub;
  late NeuralTtsEngine engine;
  late FakeTtsEngine system;
  late TtsModel tts;

  List<OnnxTtsEventType> eventsOf(OnnxTtsEventType type) => [
        for (final e in events)
          if (e.type == type) e.type
      ];

  setUpAll(() => initializeDateFormatting('en'));

  setUp(() {
    expect(Directory(modelDir).existsSync(), isTrue,
        reason: 'push the model to $modelDir first');
    // the pack as the bundled catalog describes it, installed in modelDir.
    engine = NeuralTtsEngine(InstalledVoicePack(
      pack: bundledVoicePacks.singleWhere((p) => p.id == 'supertonic-3'),
      directory: modelDir,
      sizeOnDisk: 0,
      installedAt: DateTime.now(),
    ));
    events.clear();
    eventSub = engine.events.listen(events.add);
    system = FakeTtsEngine();
    tts = TtsModel.fromJson({'language': 'en'},
        engine: system, reportError: (e, _) => fail('$e'))
      ..neuralEngine = engine;
  });

  tearDown(() async {
    expect(system.spoken, isEmpty, reason: 'no fallback to the system voice');
    await eventSub.cancel();
    tts.dispose(); // and the engine with it
  });

  testWidgets('reads the queue in order, one utterance at a time',
      (tester) async {
    const messages = [
      'hello chat, how is everyone doing today?',
      'the patch is 3.5 now... check example.com for the notes',
      'GG!!!',
    ];
    tts.setMode(l10n, TtsMode.enabled);
    for (final (i, text) in messages.indexed) {
      tts.say(l10n, chat(text, i));
    }
    final expected = messages.length + 1; // and "Text to speech enabled"
    await waitFor(() => eventsOf(OnnxTtsEventType.done).length == expected);

    // a firstAudio then a done per utterance, each before the next starts.
    final ids = events.map((e) => e.utteranceId).toSet().toList();
    expect(ids, hasLength(expected));
    expect(events.map((e) => '${e.utteranceId}:${e.type.name}'), [
      for (final id in ids) ...['$id:firstAudio', '$id:done']
    ]);
    await tester.pump(); // TtsModel notifies after the next frame.
  });

  testWidgets(
      'routes a mixed-language queue: Supertonic for en and es, the '
      'system voice for zh', (tester) async {
    final spanish = Channel(Providers.twitch, 'es', 'es');
    final chinese = Channel(Providers.kick, 'zh', 'zh');
    tts
      ..setChannelLanguage(spanish, Language('es'))
      ..setChannelLanguage(chinese, Language('zh'))
      ..setMode(l10n, TtsMode.enabled);
    tts.say(l10n, chat('hello chat, how is everyone doing today?', 1));
    tts.say(l10n, chat('hola a todos, ¿cómo están hoy?', 2)..channel = spanish);
    tts.say(l10n, chat('大家好，今天怎么样？', 3)..channel = chinese);
    tts.say(l10n, chat('qué buena jugada, de verdad', 1)..channel = spanish);
    await waitFor(() => eventsOf(OnnxTtsEventType.done).length == 4);
    await pumpEventQueue();

    expect(system.utterances.map((u) => (u.text, u.language)),
        [('user3 said: 大家好，今天怎么样？', 'zh')]);
    system.utterances.clear();
    await tester.pump(); // TtsModel notifies after the next frame.
  });

  testWidgets('stop cuts the utterance off at once', (_) async {
    final speaking = engine.speak('This message goes on, and on, and on, for '
        'a good long while, until somebody finally stops it.');
    await waitFor(() => eventsOf(OnnxTtsEventType.firstAudio).isNotEmpty);
    final stopwatch = Stopwatch()..start();
    await engine.stop();
    await speaking;
    expect(stopwatch.elapsed, lessThan(const Duration(milliseconds: 500)));
    await waitFor(() => eventsOf(OnnxTtsEventType.stopped).isNotEmpty);
  });

  testWidgets('the backlog cutoff cuts the neural voice off', (tester) async {
    tts.setMode(l10n, TtsMode.enabled);
    tts.say(
        l10n,
        chat(
            'this is a long message that keeps talking, and talking, and '
            'talking for quite a while, so the backlog has time to pile up',
            0));
    await waitFor(() => eventsOf(OnnxTtsEventType.firstAudio).length == 2);
    for (var i = 1; i <= 25; i++) {
      tts.say(l10n, chat('message number $i', i));
    }
    expect(tts.mode, TtsMode.disabled);
    await waitFor(() => eventsOf(OnnxTtsEventType.stopped).isNotEmpty);
    // then it says why it stopped, and nothing else.
    await waitFor(() => eventsOf(OnnxTtsEventType.done).length == 2);
    await Future<void>.delayed(const Duration(seconds: 1));
    expect(eventsOf(OnnxTtsEventType.firstAudio), hasLength(3));
    await tester.pump(); // TtsModel notifies after the next frame.
  });
}
