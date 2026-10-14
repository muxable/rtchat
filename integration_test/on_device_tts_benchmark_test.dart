// Benchmarks the on_device_tts native engine on a device: load time, time to
// first audio (TTFA) through `speak`, real-time factor (RTF) and CPU time
// through `synthesize`, over 20 chat-length messages. It skips itself unless
// ON_DEVICE_TTS_MODEL_DIR is set; see packages/on_device_tts/README.md. E.g.
//
//     flutter test integration_test/on_device_tts_benchmark_test.dart \
//         -d <device> --dart-define=PROVIDER=xnnpack --dart-define=THREADS=2 \
//         --dart-define=ON_DEVICE_TTS_MODEL_DIR=/data/user/0/com.rtirl.chat/files/supertonic-3
//
// It prints one `BENCH {...}` JSON line with the results.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:on_device_tts/on_device_tts.dart';

/// The model directory on the device; the benchmark skips itself without it.
const modelDir = String.fromEnvironment('ON_DEVICE_TTS_MODEL_DIR');
const provider = String.fromEnvironment('PROVIDER', defaultValue: 'cpu');
const threads = int.fromEnvironment('THREADS', defaultValue: 2);
const steps = int.fromEnvironment('STEPS', defaultValue: 5);

const englishMessages = [
  'Daisy said POGGERS that clutch was insane',
  'xXslayerXx said what game is this?',
  'NightBot said follow the stream for more content',
  'moonwalker said hello chat, how is everyone doing today?',
  'kappa_king said LUL that was so bad',
  'StreamFan99 said can you play the song from yesterday please',
  'Daisy said thanks for the raid, everyone welcome in!',
  'gamer_girl said I have been watching for three hours and I cannot stop',
  'turbo said GG',
  'Lumberjack said what settings do you use for your mouse sensitivity?',
  'pixel said the boss has a second phase, watch out for the lasers',
  'chatbot said Remember to stay hydrated and take breaks.',
  'Maverick said is this a new keyboard? It sounds really clicky.',
  'sunny said good morning from Germany',
  'Rook said that jump was frame perfect, no way',
  'Ellie said can we get a hype train going?',
  'BigTom said I just subscribed for six months, love the streams',
  'nova said who else is here from the clip on YouTube',
  'shadow said press F to pay respects',
  'Orion said what time do you usually stream on weekends?',
];

const spanishMessages = [
  'Daisy dijo hola a todos, ¿cómo están hoy?',
  'turbo dijo qué jugada tan increíble',
  'luna dijo gracias por el stream de hoy',
  'pixel dijo cuidado con el jefe, tiene una segunda fase',
  'Rook dijo buenos días desde México',
  'Ellie dijo ¿a qué hora empieza el torneo?',
  'BigTom dijo me acabo de suscribir por seis meses',
  'nova dijo esa canción es muy buena',
  'shadow dijo no puedo creer que ganaste',
  'Orion dijo ¿cuál es tu juego favorito?',
];

const russianMessages = [
  'Дейзи сказала привет всем, как дела?',
  'турбо сказал отличная игра',
  'луна сказала спасибо за стрим',
  'пиксель сказал осторожно, у босса вторая фаза',
  'Рук сказал доброе утро из Москвы',
  'Элли спросила, во сколько начинается турнир?',
  'Том сказал я только что подписался на полгода',
  'нова сказала эта песня очень хорошая',
  'тень сказал не могу поверить, что ты выиграл',
  'Орион спросил, какая твоя любимая игра?',
];

/// The language of the messages: en, es or ru.
const language = String.fromEnvironment('LANGUAGE', defaultValue: 'en');
final messages = switch (language) {
  'es' => spanishMessages,
  'ru' => russianMessages,
  _ => englishMessages,
};

/// When set, a directory on the device to write each message's audio to,
/// as `<index>.f32` (raw little-endian float PCM) plus `messages.json`.
const dumpDir = String.fromEnvironment('DUMP_DIR');

/// The clauses of [text], the way the app will segment messages.
List<String> clauses(String text) => RegExp(r'[^,;:.!?]+[,;:.!?]*')
    .allMatches(text)
    .map((m) => m.group(0)!.trim())
    .where((s) => s.isNotEmpty)
    .toList();

/// User + system CPU time of this process, from /proc/self/stat.
Duration cpuTime() {
  final stat = File('/proc/self/stat').readAsStringSync();
  final fields = stat.substring(stat.lastIndexOf(')') + 2).split(' ');
  // utime and stime are fields 14 and 15, in clock ticks (100 Hz on
  // Android).
  final ticks = int.parse(fields[11]) + int.parse(fields[12]);
  return Duration(milliseconds: ticks * 10);
}

double percentile(List<double> values, double p) {
  final sorted = [...values]..sort();
  final index = ((sorted.length - 1) * p).round();
  return sorted[index];
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('on-device TTS benchmark', skip: modelDir.isEmpty, (_) async {
    final loadWatch = Stopwatch()..start();
    final tts = await OnnxTts.load(
      modelDir: modelDir,
      numThreads: threads,
      provider: OnnxProvider.values.byName(provider),
    );
    final loadMs = loadWatch.elapsedMilliseconds;
    // Warm up.
    await tts.synthesize('Warming up the engine.',
        language: 'en', voiceId: 'M1', steps: steps);

    final ttfa = <double>[];
    var synthMs = 0.0;
    var audioMs = 0.0;
    var cpuMs = 0.0;
    final events = StreamController<OnnxTtsEvent>.broadcast();
    final sub = tts.events.listen(events.add);

    for (final (i, message) in messages.indexed) {
      final voice = i.isEven ? 'F1' : 'M1';

      // RTF and CPU time, synthesizing the whole message at once.
      final cpuBefore = cpuTime();
      final watch = Stopwatch()..start();
      final audio = await tts.synthesize(message,
          language: language, voiceId: voice, steps: steps, noiseSeed: i);
      synthMs += watch.elapsedMicroseconds / 1000;
      cpuMs += (cpuTime() - cpuBefore).inMicroseconds / 1000;
      audioMs += audio.duration.inMicroseconds / 1000;
      if (dumpDir.isNotEmpty) {
        Directory(dumpDir).createSync(recursive: true);
        File('$dumpDir/$i.f32').writeAsBytesSync(audio.pcm.buffer
            .asUint8List(audio.pcm.offsetInBytes, audio.pcm.lengthInBytes));
      }

      // TTFA, speaking it clause by clause; stop once audio starts.
      final first = events.stream.firstWhere((e) =>
          e.utteranceId == 'bench-$i' && e.type == OnnxTtsEventType.firstAudio);
      final speaking = tts.speak(clauses(message),
          language: language,
          voiceId: voice,
          steps: steps,
          utteranceId: 'bench-$i');
      final event = await first;
      await tts.stop();
      await speaking;
      ttfa.add(event.elapsed.inMicroseconds / 1000);
    }
    await sub.cancel();
    await tts.unload();
    if (dumpDir.isNotEmpty) {
      File('$dumpDir/messages.json').writeAsStringSync(jsonEncode(
          {'language': language, 'sample_rate': 44100, 'messages': messages}));
    }

    final result = {
      'model': modelDir.split('/').last,
      'language': language,
      'provider': provider,
      'threads': threads,
      'steps': steps,
      'messages': messages.length,
      'load_ms': loadMs,
      'ttfa_median_ms': percentile(ttfa, 0.5),
      'ttfa_p90_ms': percentile(ttfa, 0.9),
      'rtf': synthMs / audioMs,
      'cpu_s_per_audio_s': cpuMs / audioMs,
      'audio_s': audioMs / 1000,
    };
    // ignore: avoid_print
    print('BENCH ${jsonEncode(result)}');
  }, timeout: const Timeout(Duration(minutes: 20)));
}
