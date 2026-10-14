// Reads chat aloud through a real TtsModel queue with the real
// NeuralTtsEngine (on_device_tts) and a Supertonic 3 model on a device, and
// measures time to first audio with and without clause splitting. It skips
// itself unless ON_DEVICE_TTS_MODEL_DIR is set, so the regular integration
// run (which has no model) passes over it. See
// packages/on_device_tts/README.md for how to push the model, then:
//
//     flutter test integration_test/neural_tts_engine_test.dart -d <device> \
//         --dart-define=ON_DEVICE_TTS_MODEL_DIR=/data/user/0/com.rtirl.chat/files/supertonic-3
//
// It prints one `TTFA {...}` JSON line with the measurements.
//
// The mixed-language test also reads with the platform's own voices (Google
// TTS on the emulator) for the language Supertonic doesn't speak.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:on_device_tts/on_device_tts.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/messages/message.dart';
import 'package:rtchat/models/messages/twitch/message.dart';
import 'package:rtchat/models/messages/twitch/user.dart';
import 'package:rtchat/models/tts.dart';
import 'package:rtchat/models/tts/language.dart';

/// The model directory on the device; the tests skip themselves without it.
const modelDir = String.fromEnvironment('ON_DEVICE_TTS_MODEL_DIR');

/// One utterance as the TTS queue spoke it.
class Spoken {
  final String text;
  final Duration start;
  final TtsVoice? voice;
  final String? language;
  Duration? end;

  Spoken(this.text, this.start, {this.voice, this.language});
}

/// Passes speech on to [inner] and logs when each utterance starts and ends.
class LoggingEngine implements TtsEngine {
  final TtsEngine inner;
  final Stopwatch clock;
  final spoken = <Spoken>[];

  LoggingEngine(this.inner, this.clock);

  @override
  Future<void> speak(String text,
      {TtsVoice? voice,
      double rate = TtsEngine.normalRate,
      double pitch = TtsEngine.normalPitch,
      String? language}) async {
    final entry = Spoken(text, clock.elapsed, voice: voice, language: language);
    spoken.add(entry);
    try {
      await inner.speak(text,
          voice: voice, rate: rate, pitch: pitch, language: language);
    } finally {
      entry.end = clock.elapsed;
    }
  }

  @override
  Future<void> stop() => inner.stop();

  @override
  Future<List<TtsVoice>> voices({String? language}) =>
      inner.voices(language: language);

  /// The neural engine is shared between tests; dispose it in tearDownAll.
  @override
  Future<void> dispose() async {}
}

/// Records what the system voice would have said: nothing, if the neural
/// engine never fails.
class SilentSystemEngine implements TtsEngine {
  final spoken = <String>[];

  @override
  Future<void> speak(String text,
      {TtsVoice? voice,
      double rate = TtsEngine.normalRate,
      double pitch = TtsEngine.normalPitch,
      String? language}) async {
    spoken.add(text);
  }

  @override
  Future<void> stop() async {}

  @override
  Future<List<TtsVoice>> voices({String? language}) async => const [];

  @override
  Future<void> dispose() async {}
}

TwitchMessageModel chat(String text, int i, {int? userId}) =>
    TwitchMessageModel(
        messageId: 'm$i-${DateTime.now().microsecondsSinceEpoch}',
        author: TwitchUserModel(
            userId: '${userId ?? i}',
            login: 'user${userId ?? i}',
            displayName: 'Chatter${userId ?? i}'),
        tags: const {},
        annotations: const TwitchMessageAnnotationsModel(
            isAction: false, isFirstTimeChatter: false, announcement: null),
        thirdPartyEmotes: const [],
        timestamp: DateTime.now(),
        message: text,
        deleted: false,
        channelId: 'placeholder');

Future<void> waitFor(bool Function() condition,
    {Duration timeout = const Duration(seconds: 60)}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('timed out after $timeout');
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

int median(List<int> values) {
  final sorted = [...values]..sort();
  return sorted[sorted.length ~/ 2];
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  if (modelDir.isEmpty) {
    testWidgets('neural TTS (needs ON_DEVICE_TTS_MODEL_DIR)', (_) async {},
        skip: true);
    return;
  }

  final l10n = lookupAppLocalizations(const Locale('en'));
  late NeuralTtsEngine engine;
  final events = <OnnxTtsEvent>[];
  late StreamSubscription<OnnxTtsEvent> eventSub;

  setUpAll(() async {
    await initializeDateFormatting('en');
    expect(Directory(modelDir).existsSync(), isTrue,
        reason: 'push the model to $modelDir first');
    // The pack exactly as the bundled catalog describes it, so the engine
    // finds the model through the catalog's config paths.
    final catalogPack =
        VoicePackCatalog.parse(bundledVoicePackCatalogJson).packs.singleWhere(
              (pack) => pack.id == 'supertonic-3',
            );
    engine = NeuralTtsEngine(InstalledVoicePack(
      pack: catalogPack,
      directory: modelDir,
      catalogVersion: 1,
      sizeOnDisk: 0,
      installedAt: DateTime.now(),
    ));
    eventSub = engine.events.listen(events.add);
    final stopwatch = Stopwatch()..start();
    await engine.load();
    // ignore: avoid_print
    print('load: ${stopwatch.elapsedMilliseconds} ms');
  });

  tearDownAll(() async {
    await eventSub.cancel();
    await engine.dispose();
  });

  setUp(events.clear);

  testWidgets('reads chat through the TtsModel queue in order, one at a time',
      (tester) async {
    final clock = Stopwatch()..start();
    final logging = LoggingEngine(engine, clock);
    final system = SilentSystemEngine();
    final errors = <Object>[];
    final tts = TtsModel.fromJson({'language': 'en'},
        engine: system, reportError: (e, _) => errors.add(e));
    tts.neuralEngine = logging;

    const messages = [
      'hello chat, how is everyone doing today?',
      'POGGERS that clutch was insane',
      'the patch is 3.5 now... I think, check example.com for the notes',
      'GG!!!',
      'can you play the song from yesterday please',
    ];
    tts.setMode(l10n, TtsMode.enabled);
    for (var i = 0; i < messages.length; i++) {
      tts.say(l10n, chat(messages[i], i));
    }
    final expected = messages.length + 1; // and "Text to speech enabled"
    await waitFor(() =>
        events.where((e) => e.type == OnnxTtsEventType.done).length ==
        expected);
    await pumpEventQueue();

    expect(errors, isEmpty);
    expect(system.spoken, isEmpty, reason: 'no fallback to the system voice');
    expect(logging.spoken.map((s) => s.text), [
      'Text to speech enabled',
      for (var i = 0; i < messages.length; i++)
        l10n.saidMessage('Chatter$i', messages[i]),
    ]);
    // No overlap: each utterance ends before the next starts.
    for (var i = 1; i < logging.spoken.length; i++) {
      expect(logging.spoken[i].start,
          greaterThanOrEqualTo(logging.spoken[i - 1].end!));
    }
    // A firstAudio for each utterance, each before its done, in order.
    final ids = <String>[];
    for (final event in events) {
      if (!ids.contains(event.utteranceId)) ids.add(event.utteranceId);
    }
    expect(ids, hasLength(expected));
    for (final id in ids) {
      expect(events.where((e) => e.utteranceId == id).map((e) => e.type),
          [OnnxTtsEventType.firstAudio, OnnxTtsEventType.done]);
    }
    final order = events.map((e) => '${e.utteranceId}:${e.type.name}');
    expect(order, [
      for (final id in ids) ...['$id:firstAudio', '$id:done'],
    ]);
    // ignore: avoid_print
    print('queue: ${[
      for (final s in logging.spoken) '${(s.end! - s.start).inMilliseconds} ms',
    ]}, first audio at ${[
      for (final e in events)
        if (e.type == OnnxTtsEventType.firstAudio) e.elapsed.inMilliseconds,
    ]} ms');
    // TtsModel notifies its listeners after the next frame.
    await tester.pump();
    tts.dispose();
  });

  testWidgets(
      'routes a mixed-language queue: Supertonic for en and es, the system '
      'voice for zh, a voice per chatter', (tester) async {
    final clock = Stopwatch()..start();
    final neural = LoggingEngine(engine, clock);
    final platform = SystemTtsEngine();
    final system = LoggingEngine(platform, clock);
    final errors = <Object>[];
    final tts = TtsModel.fromJson({'language': 'en'},
        engine: system, reportError: (e, _) => errors.add(e));
    tts.neuralEngine = neural;
    final english = Channel(Providers.twitch, 'en', 'en');
    final spanish = Channel(Providers.twitch, 'es', 'es');
    final chinese = Channel(Providers.kick, 'zh', 'zh');
    tts.setChannelLanguage(english, Language('en'));
    tts.setChannelLanguage(spanish, Language('es'));
    tts.setChannelLanguage(chinese, Language('zh'));

    // (text, channel, chatter): chatters 1, 2 and 4 hash to M1, F5 and F3.
    final messages = [
      ('hello chat, how is everyone doing today?', english, 1),
      ('hola a todos, ¿cómo están hoy?', spanish, 2),
      ('大家好，今天怎么样？', chinese, 3),
      ('that clutch was insane', english, 4),
      ('qué buena jugada, de verdad', spanish, 1),
      ('谢谢大家', chinese, 2),
    ];
    tts.setMode(l10n, TtsMode.enabled);
    for (final (i, (text, channel, user)) in messages.indexed) {
      tts.say(l10n, chat(text, i, userId: user)..channel = channel);
    }
    final total = messages.length + 1; // and "Text to speech enabled"
    await waitFor(
        () =>
            [...neural.spoken, ...system.spoken]
                .where((s) => s.end != null)
                .length ==
            total,
        timeout: const Duration(seconds: 120));
    await pumpEventQueue();

    expect(errors, isEmpty);
    final all = [...neural.spoken, ...system.spoken]
      ..sort((a, b) => a.start.compareTo(b.start));
    // In order, whichever engine read each one.
    String said((String, Channel, int) m) =>
        l10n.saidMessage('Chatter${m.$3}', m.$1);
    expect(all.map((s) => s.text), [
      'Text to speech enabled',
      for (final m in messages) said(m),
    ]);
    // No overlap, across both engines.
    for (var i = 1; i < all.length; i++) {
      expect(all[i].start, greaterThanOrEqualTo(all[i - 1].end!),
          reason: '"${all[i].text}" started before "${all[i - 1].text}" '
              'ended');
    }
    // Supertonic for en and es, in that language.
    expect(neural.spoken.map((s) => (s.text, s.language)), [
      ('Text to speech enabled', 'en'),
      (said(messages[0]), 'en'),
      (said(messages[1]), 'es'),
      (said(messages[3]), 'en'),
      (said(messages[4]), 'es'),
    ]);
    // The system voice for zh, told the language.
    expect(system.spoken.map((s) => (s.text, s.language)), [
      (said(messages[2]), 'zh'),
      (said(messages[5]), 'zh'),
    ]);
    // A voice per chatter: chatter 1 keeps theirs across languages, and
    // chatters 1, 2 and 4 each have their own.
    final voices = [for (final s in neural.spoken.skip(1)) s.voice?.id];
    expect(voices, ['M1', 'F5', 'F3', 'M1']);
    // And Supertonic played each of its utterances, one after the other.
    final ids = <String>[];
    for (final event in events) {
      if (!ids.contains(event.utteranceId)) ids.add(event.utteranceId);
    }
    expect(ids, hasLength(neural.spoken.length));
    expect(events.map((e) => '${e.utteranceId}:${e.type.name}'), [
      for (final id in ids) ...['$id:firstAudio', '$id:done'],
    ]);
    final zhVoices = await platform.voices(language: 'zh');
    // ignore: avoid_print
    print('mixed: ${[
      for (final s in all)
        '${neural.spoken.contains(s) ? 'neural' : 'system'}'
            '/${s.language}/${s.voice?.id ?? '-'} '
            '${(s.end! - s.start).inMilliseconds} ms',
    ]}, system zh voices: ${zhVoices.length}');
    // TtsModel notifies its listeners after the next frame.
    await tester.pump();
    tts.dispose();
    await platform.dispose();
  });

  testWidgets('the backlog cutoff cuts the neural voice off', (tester) async {
    final clock = Stopwatch()..start();
    final logging = LoggingEngine(engine, clock);
    final system = SilentSystemEngine();
    final tts = TtsModel.fromJson({'language': 'en'},
        engine: system, reportError: (e, _) => fail('$e'));
    tts.neuralEngine = logging;

    tts.setMode(l10n, TtsMode.enabled);
    tts.say(
        l10n,
        chat(
            'this is a long message that keeps talking, and talking, and '
            'talking for quite a while, so the backlog has time to pile up',
            0));
    // Wait until the long message is playing.
    await waitFor(() =>
        events.where((e) => e.type == OnnxTtsEventType.firstAudio).length == 2);
    final cutoff = clock.elapsed;
    for (var i = 1; i <= 25; i++) {
      tts.say(l10n, chat('message number $i', i));
    }
    expect(tts.mode, TtsMode.disabled);
    await waitFor(() => events.any((e) => e.type == OnnxTtsEventType.stopped));
    final stoppedAfter = clock.elapsed - cutoff;
    // Then it says why it stopped.
    await waitFor(
        () => events.where((e) => e.type == OnnxTtsEventType.done).length == 2);
    await pumpEventQueue();

    expect(stoppedAfter, lessThan(const Duration(milliseconds: 500)));
    expect(logging.spoken.map((s) => s.text), [
      'Text to speech enabled',
      startsWith('Chatter0 said:'),
      l10n.textToSpeechTooManyMessages,
    ]);
    for (var i = 1; i < logging.spoken.length; i++) {
      expect(logging.spoken[i].start,
          greaterThanOrEqualTo(logging.spoken[i - 1].end!));
    }
    expect(system.spoken, isEmpty);
    // ignore: avoid_print
    print('backlog: stopped ${stoppedAfter.inMilliseconds} ms after the '
        'cutoff');
    // TtsModel notifies its listeners after the next frame.
    await tester.pump();
    tts.dispose();
  });

  testWidgets('stop cuts the utterance off at once', (_) async {
    final speaking = engine
        .speak('This message goes on, and on, and on, for a good long while, '
            'until somebody finally stops it.');
    await waitFor(
        () => events.any((e) => e.type == OnnxTtsEventType.firstAudio));
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final stopwatch = Stopwatch()..start();
    await engine.stop();
    await speaking;
    expect(stopwatch.elapsed, lessThan(const Duration(milliseconds: 500)));
    await waitFor(() => events.any((e) => e.type == OnnxTtsEventType.stopped));
    // ignore: avoid_print
    print('stop: speak completed ${stopwatch.elapsedMilliseconds} ms after '
        'stop');
  });

  testWidgets('time to first audio, with and without clause splitting',
      (_) async {
    // What TtsModel passes for chat: "<author> said: <text>".
    const cases = {
      'single clause, short': 'Daisy said POGGERS that clutch was insane',
      'single clause, long':
          'gamer girl said I have been watching this stream for three hours '
              'straight and I still cannot believe how good that last run was',
      'multi clause': 'Muxfd said: hello chat, thanks for the raid everyone! '
          'welcome in, grab a seat, and enjoy the stream.',
      'multi clause, long': 'Lumberjack said: what settings do you use for '
          'your mouse sensitivity? I keep overshooting every flick, and my '
          'aim feels terrible lately, so any tips would help a lot.',
    };
    const runs = 3;
    const splitter = ClauseSplitter();
    // The same model without clause splitting. Only one model stays loaded
    // at a time; they take turns.
    final unsplit = NeuralTtsEngine(engine.pack, splitClauses: false);
    final unsplitEvents = unsplit.events.listen(events.add);
    final results = <String, Object>{};
    for (final MapEntry(key: name, value: text) in cases.entries) {
      for (final split in [false, true]) {
        final segments = split ? splitter.split(text) : [text];
        await (split ? unsplit : engine).release();
        await (split ? engine : unsplit).load();
        final ttfa = <int>[];
        final dartTtfa = <int>[];
        // Run 0 warms the freshly loaded model up and isn't counted.
        for (var run = 0; run <= runs; run++) {
          events.clear();
          final stopwatch = Stopwatch()..start();
          int? firstAudioDart;
          final sub = (split ? engine : unsplit).events.listen((e) {
            if (e.type == OnnxTtsEventType.firstAudio) {
              firstAudioDart = stopwatch.elapsedMilliseconds;
            }
          });
          await (split ? engine : unsplit).speak(text, language: 'en');
          await pumpEventQueue();
          await sub.cancel();
          final first =
              events.singleWhere((e) => e.type == OnnxTtsEventType.firstAudio);
          if (run == 0) continue;
          ttfa.add(first.elapsed.inMilliseconds);
          dartTtfa.add(firstAudioDart!);
        }
        results['$name, ${split ? 'split' : 'unsplit'}'] = {
          'segments': segments.length,
          'first_segment': segments.first,
          'ttfa_native_ms': ttfa,
          'ttfa_native_median_ms': median(ttfa),
          'ttfa_dart_median_ms': median(dartTtfa),
        };
      }
    }
    await unsplitEvents.cancel();
    await unsplit.dispose();
    // ignore: avoid_print
    print('TTFA ${jsonEncode(results)}');
  });
}
