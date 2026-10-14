// Soak test for neural TTS in the background (#1507): feeds chat-like
// messages through a real TtsModel, NeuralTtsEngine and Supertonic 3 model
// for SOAK_MINUTES (30 by default) with the TTS foreground service running,
// the way the app reads chat with the phone in a pocket. It skips itself
// unless ON_DEVICE_TTS_MODEL_DIR is set, so the regular integration run
// passes over it.
//
// Run it with integration_test/neural_tts_soak.sh, which pushes the model,
// turns the screen off and sends the app to the background once the test
// starts, samples memory and CPU, and sends memory warnings mid-run.
//
// The test checks that every message was read by the neural voice (none
// dropped, none fallen back to the system voice), in order, without errors;
// that the model was released when idle (SOAK_IDLE_SECONDS) and on memory
// pressure, and loaded again for the next message. It prints `SOAK ...`
// progress lines and a final `SOAK_RESULT {...}` JSON line.

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:on_device_tts/on_device_tts.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/messages/twitch/message.dart';
import 'package:rtchat/models/messages/twitch/user.dart';
import 'package:rtchat/models/tts.dart';
import 'package:rtchat/tts_foreground_service.dart';

const modelDir = String.fromEnvironment('ON_DEVICE_TTS_MODEL_DIR');
const minutes = int.fromEnvironment('SOAK_MINUTES', defaultValue: 30);
const idleSeconds = int.fromEnvironment('SOAK_IDLE_SECONDS', defaultValue: 60);

/// Seconds after the start to stop chatting for longer than the idle
/// timeout, so the model is released for being idle.
const quietAt = int.fromEnvironment('SOAK_QUIET_AT', defaultValue: 900);

// ignore: avoid_print
void log(String line) => print('SOAK $line');

/// User + system CPU time of this process, from /proc/self/stat.
Duration cpuTime() {
  final stat = File('/proc/self/stat').readAsStringSync();
  final fields = stat.substring(stat.lastIndexOf(')') + 2).split(' ');
  final ticks = int.parse(fields[11]) + int.parse(fields[12]);
  return Duration(milliseconds: ticks * 10);
}

/// Resident memory of this process, from /proc/self/status.
int rssKb() {
  final line = File('/proc/self/status')
      .readAsLinesSync()
      .firstWhere((line) => line.startsWith('VmRSS:'));
  return int.parse(line.split(RegExp(r'\s+'))[1]);
}

/// Passes speech to the neural engine, loading the model first (and timing
/// it) when it was released.
class MeasuringEngine implements TtsEngine {
  final NeuralTtsEngine inner;
  final Stopwatch clock;
  final spoken = <String>[];
  final loads = <({int atS, int ms})>[];

  MeasuringEngine(this.inner, this.clock);

  @override
  Future<void> speak(String text,
      {TtsVoice? voice,
      double rate = TtsEngine.normalRate,
      double pitch = TtsEngine.normalPitch,
      String? language}) async {
    if (!inner.isLoaded) {
      final watch = Stopwatch()..start();
      await inner.load();
      loads.add((atS: clock.elapsed.inSeconds, ms: watch.elapsedMilliseconds));
      log('load at ${clock.elapsed.inSeconds} s took '
          '${watch.elapsedMilliseconds} ms');
    }
    await inner.speak(text,
        voice: voice, rate: rate, pitch: pitch, language: language);
    spoken.add(text);
  }

  @override
  Future<void> stop() => inner.stop();

  @override
  Future<void> release() async {
    final wasLoaded = inner.isLoaded;
    await inner.release();
    if (wasLoaded) log('released at ${clock.elapsed.inSeconds} s');
  }

  @override
  Future<List<TtsVoice>> voices({String? language}) =>
      inner.voices(language: language);

  @override
  Future<void> dispose() => inner.dispose();
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
  Future<void> release() async {}

  @override
  Future<List<TtsVoice>> voices({String? language}) async => const [];

  @override
  Future<void> dispose() async {}
}

const _words = [
  'hello',
  'chat',
  'that',
  'was',
  'insane',
  'clutch',
  'what',
  'game',
  'is',
  'this',
  'play',
  'the',
  'song',
  'from',
  'yesterday',
  'please',
  'GG',
  'LUL',
  'boss',
  'has',
  'a',
  'second',
  'phase',
  'watch',
  'out',
  'for',
  'lasers',
  'good',
  'morning',
  'from',
  'Germany',
  'hype',
  'train',
  'when',
  'do',
  'you',
  'stream',
  'on',
  'weekends',
  'new',
  'keyboard',
  'sounds',
  'clicky',
  'POG',
  'raid',
  'incoming',
  'welcome',
  'in',
  'everyone',
  'hydrate',
  'now',
];

/// A chat-like message of 1 to 18 words, with some punctuation.
String chatLine(Random random) {
  final count = 1 + random.nextInt(18);
  final buffer = StringBuffer();
  for (var i = 0; i < count; i++) {
    if (i > 0) buffer.write(random.nextInt(8) == 0 ? ', ' : ' ');
    buffer.write(_words[random.nextInt(_words.length)]);
  }
  buffer.write(const ['', '!', '?', '.', '!!!'][random.nextInt(5)]);
  return buffer.toString();
}

TwitchMessageModel chat(String text, int i, int user) => TwitchMessageModel(
    messageId: 'soak-$i',
    author: TwitchUserModel(
        userId: '$user', login: 'user$user', displayName: 'Chatter$user'),
    tags: const {},
    annotations: const TwitchMessageAnnotationsModel(
        isAction: false, isFirstTimeChatter: false, announcement: null),
    thirdPartyEmotes: const [],
    timestamp: DateTime.now(),
    message: text,
    deleted: false,
    channelId: 'placeholder');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('neural TTS soak in the background', skip: modelDir.isEmpty,
      (tester) async {
    await initializeDateFormatting('en');
    final l10n = lookupAppLocalizations(const Locale('en'));
    expect(Directory(modelDir).existsSync(), isTrue,
        reason: 'push the model to $modelDir first');
    final catalogPack = VoicePackCatalog.parse(bundledVoicePackCatalogJson)
        .packs
        .singleWhere((pack) => pack.id == 'supertonic-3');
    final engine = NeuralTtsEngine(InstalledVoicePack(
      pack: catalogPack,
      directory: modelDir,
      catalogVersion: 1,
      sizeOnDisk: 0,
      installedAt: DateTime.now(),
    ));
    final clock = Stopwatch()..start();
    final neural = MeasuringEngine(engine, clock);
    final system = SilentSystemEngine();
    final errors = <Object>[];
    final tts = TtsModel.fromJson({'language': 'en'}, engine: system,
        reportError: (e, st) {
      errors.add(e);
      log('error at ${clock.elapsed.inSeconds} s: $e');
    }, neuralIdleTimeout: const Duration(seconds: idleSeconds));
    tts.neuralEngine = neural;
    // as in the app: the foreground service while TTS is on, and memory
    // warnings release the model.
    final service = TtsForegroundService(tts, () => l10n);
    final monitor = MemoryPressureMonitor(tts.releaseNeuralModels)..start();
    final events = <OnnxTtsEvent>[];
    final eventSub = engine.events.listen(events.add);

    tts.setMode(l10n, TtsMode.enabled);
    // TtsModel tells its listeners, and so the service, after a frame.
    await tester.pump();
    var isServiceRunning = false;
    for (var i = 0; i < 50 && !isServiceRunning; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      isServiceRunning =
          await TtsForegroundService.channel.invokeMethod<bool>('isRunning') ??
              false;
    }
    expect(isServiceRunning, isTrue,
        reason: 'the foreground service keeps the process going');
    final random = Random(1507);
    final expected = <String>[l10n.textToSpeechEnabled];
    // the text of each, which is read alone (without "X said") when the
    // queue falls 10 messages behind.
    final bare = <String>[l10n.textToSpeechEnabled];
    final cpuStart = cpuTime();
    final end = Duration(minutes: minutes);
    var sent = 0;
    var quiet = false;
    var nextReport = 0;
    // the host script turns the screen off and backgrounds the app now.
    log('started minutes=$minutes idle=$idleSeconds pid=$pid');

    while (clock.elapsed < end) {
      final now = clock.elapsed.inSeconds;
      if (now >= nextReport) {
        log('t=$now sent=$sent spoken=${neural.spoken.length} '
            'system=${system.spoken.length} loaded=${engine.isLoaded} '
            'rss=${rssKb()} kB cpu=${(cpuTime() - cpuStart).inSeconds} s');
        nextReport += 60;
      }
      if (!quiet && now >= quietAt) {
        quiet = true;
        log('quiet for ${idleSeconds + 30} s at $now s');
        await Future<void>.delayed(Duration(seconds: idleSeconds + 30));
        continue;
      }
      // mostly one message every 3 to 9 s, sometimes a burst of three.
      final burst = random.nextInt(10) == 0 ? 3 : 1;
      for (var b = 0; b < burst; b++) {
        // 40 chatters in turn: one never follows themself in the queue,
        // which would leave out "X said".
        final user = sent % 40;
        final text = chatLine(random);
        tts.say(l10n, chat(text, sent, user));
        expected.add(l10n.saidMessage('Chatter$user', text));
        bare.add(text);
        sent++;
      }
      await Future<void>.delayed(
          Duration(milliseconds: 3000 + random.nextInt(6000)));
    }

    // let the queue drain.
    final deadline = DateTime.now().add(const Duration(minutes: 3));
    while (neural.spoken.length + system.spoken.length < expected.length &&
        DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    final spoken = List.of(neural.spoken);
    final fellBack = List.of(system.spoken);
    final cpu = cpuTime() - cpuStart;
    final elapsed = clock.elapsed;
    final firstAudio = [
      for (final e in events)
        if (e.type == OnnxTtsEventType.firstAudio) e.elapsed.inMilliseconds,
    ]..sort();
    final reloads = neural.loads.skip(1).map((l) => l.ms).toList();
    final result = {
      'minutes': elapsed.inSeconds / 60,
      'messages_sent': sent,
      'utterances_expected': expected.length,
      'read_without_prelude': [
        for (var i = 0; i < spoken.length && i < bare.length; i++)
          if (spoken[i] == bare[i] && bare[i] != expected[i]) i,
      ].length,
      'spoken_neural': neural.spoken.length,
      'spoken_system': system.spoken.length,
      'errors': errors.length,
      'mode_at_end': tts.mode.name,
      'loads': neural.loads.length,
      'first_load_ms': neural.loads.firstOrNull?.ms,
      'reload_ms': reloads,
      'reloads_at_s': neural.loads.skip(1).map((l) => l.atS).toList(),
      'ttfa_median_ms':
          firstAudio.isEmpty ? null : firstAudio[firstAudio.length ~/ 2],
      'ttfa_p90_ms':
          firstAudio.isEmpty ? null : firstAudio[(firstAudio.length * 9) ~/ 10],
      'cpu_s': cpu.inMilliseconds / 1000,
      'cpu_percent_of_one_core':
          100 * cpu.inMilliseconds / elapsed.inMilliseconds,
      'rss_kb_end': rssKb(),
    };
    // ignore: avoid_print
    print('SOAK_RESULT ${jsonEncode(result)}');

    // turning TTS off reads "disabled", then releases the model.
    await eventSub.cancel();
    tts.setMode(l10n, TtsMode.disabled);
    final released = DateTime.now().add(const Duration(seconds: 30));
    while (engine.isLoaded && DateTime.now().isBefore(released)) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    final releasedWhenOff = !engine.isLoaded;
    monitor.dispose();
    service.dispose();
    tts.dispose();

    expect(errors, isEmpty);
    expect(tts.neuralFallback, isNull);
    expect(fellBack, isEmpty, reason: 'nothing fell back');
    expect(spoken, hasLength(expected.length), reason: 'nothing dropped');
    for (var i = 0; i < expected.length; i++) {
      expect(spoken[i], anyOf(expected[i], bare[i]), reason: 'in order');
    }
    expect(releasedWhenOff, isTrue, reason: 'released once TTS was off');
    expect(neural.loads.length, greaterThanOrEqualTo(2),
        reason: 'released (idle or memory pressure) and loaded again');
  }, timeout: const Timeout(Duration(minutes: minutes + 20)));
}
