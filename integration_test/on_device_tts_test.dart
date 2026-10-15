// Runs the on_device_tts native ONNX Runtime engine on a device with a real
// Supertonic 3 model. It skips itself unless ON_DEVICE_TTS_MODEL_DIR is set,
// so the regular integration run (which has no model) passes over it. See
// packages/on_device_tts/README.md for how to push the model and run it:
//
//     flutter test integration_test/on_device_tts_test.dart -d <device> \
//         --dart-define=ON_DEVICE_TTS_MODEL_DIR=/data/user/0/com.rtirl.chat/files/supertonic-3
//
// With `--dart-define=ON_DEVICE_TTS_REFERENCE_DIR=<dir on the device>`
// holding the output of `packages/on_device_tts/tool/supertonic_reference.py`,
// it also compares the device's audio with the reference implementation's.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:on_device_tts/on_device_tts.dart';

/// The model directory on the device; the tests skip themselves without it.
const modelDir = String.fromEnvironment('ON_DEVICE_TTS_MODEL_DIR');
const referenceDir = String.fromEnvironment('ON_DEVICE_TTS_REFERENCE_DIR');

/// Max abs diff allowed against the reference audio. The fp32 model stays
/// within 1e-3 across ONNX Runtime builds; int8 kernels differ between builds
/// and CPUs, so compare quantized models on the same machine only.
const parityTolerance = String.fromEnvironment('ON_DEVICE_TTS_PARITY_TOLERANCE',
    defaultValue: '1e-3');

double rms(Float32List pcm) {
  var sum = 0.0;
  for (final x in pcm) {
    sum += x * x;
  }
  return sqrt(sum / pcm.length);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  if (modelDir.isEmpty) {
    testWidgets('on-device TTS (needs ON_DEVICE_TTS_MODEL_DIR)', (_) async {},
        skip: true);
    return;
  }

  late OnnxTts tts;

  setUpAll(() async {
    expect(Directory(modelDir).existsSync(), isTrue,
        reason: 'push the model to $modelDir first');
    tts = await OnnxTts.load(modelDir: modelDir);
  });

  tearDownAll(() => tts.unload());

  testWidgets('load fails on a missing model', (_) async {
    await expectLater(
      OnnxTts.load(modelDir: '/data/nonexistent'),
      throwsA(isA<PlatformException>()
          .having((e) => e.code, 'code', 'load_failed')),
    );
  });

  testWidgets('lists the voice styles', (_) async {
    final voices = await tts.voices();
    expect(voices.map((v) => v.id), [
      for (final g in ['F', 'M'])
        for (var i = 1; i <= 5; i++) '$g$i',
    ]);
    expect(voices.every((v) => v.language == null), isTrue);
  });

  testWidgets('synthesizes speech', (_) async {
    final stopwatch = Stopwatch()..start();
    final audio = await tts.synthesize('Hello chat, thanks for the follow!',
        language: 'en', voiceId: 'F1', noiseSeed: 7);
    final elapsed = stopwatch.elapsed;
    expect(audio.sampleRate, 44100);
    expect(audio.duration, greaterThan(const Duration(milliseconds: 1000)));
    expect(audio.duration, lessThan(const Duration(seconds: 5)));
    expect(rms(audio.pcm), greaterThan(0.01));
    expect(audio.pcm.every((x) => x.isFinite && x.abs() <= 1.5), isTrue);
    // ignore: avoid_print
    print('synthesize: ${audio.duration.inMilliseconds} ms of audio in '
        '${elapsed.inMilliseconds} ms, rms ${rms(audio.pcm).toStringAsFixed(3)}');

    final again = await tts.synthesize('Hello chat, thanks for the follow!',
        language: 'en', voiceId: 'F1', noiseSeed: 7);
    expect(again.pcm, audio.pcm, reason: 'same seed, same audio');
    final other = await tts.synthesize('Hello chat, thanks for the follow!',
        language: 'en', voiceId: 'F1', noiseSeed: 8);
    expect(other.pcm.length, audio.pcm.length,
        reason: 'the duration does not depend on the noise');
    expect(other.pcm, isNot(audio.pcm));
  });

  testWidgets('speaks other languages and speeds', (_) async {
    final normal = await tts.synthesize('Привет, чат!',
        language: 'ru', voiceId: 'M1', noiseSeed: 1);
    final fast = await tts.synthesize('Привет, чат!',
        language: 'ru-RU', voiceId: 'M1', noiseSeed: 1, speed: 1.5);
    expect(rms(normal.pcm), greaterThan(0.01));
    expect(fast.pcm.length, lessThan(normal.pcm.length * 0.8));
    // Unsupported languages and characters still make speech.
    final unknown = await tts.synthesize('Hola 👋 chat ❤️',
        language: 'xx', voiceId: 'M1', noiseSeed: 1);
    expect(rms(unknown.pcm), greaterThan(0.01));
  });

  testWidgets('rejects bad arguments', (_) async {
    await expectLater(
      tts.synthesize('hi', language: 'en', voiceId: 'nobody'),
      throwsA(
          isA<PlatformException>().having((e) => e.code, 'code', 'bad_args')),
    );
    await expectLater(
      tts.synthesize('hi', language: 'en', voiceId: 'F1', steps: 0),
      throwsA(
          isA<PlatformException>().having((e) => e.code, 'code', 'bad_args')),
    );
  });

  testWidgets('matches the reference implementation', (_) async {
    final manifestFile = File('$referenceDir/manifest.json');
    if (referenceDir.isEmpty || !manifestFile.existsSync()) {
      markTestSkipped('no SUPERTONIC_REFERENCE_DIR');
      return;
    }
    final manifest =
        jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
    for (final c in manifest['cases'] as List) {
      final reference = File('$referenceDir/${c['pcm']}')
          .readAsBytesSync()
          .buffer
          .asFloat32List();
      final audio = await tts.synthesize(c['text'] as String,
          language: c['lang'] as String,
          voiceId: c['voice'] as String,
          speed: (c['speed'] as num).toDouble(),
          steps: c['steps'] as int,
          noiseSeed: c['seed'] as int);
      expect(audio.pcm.length, reference.length, reason: '${c['name']}');
      var maxDiff = 0.0;
      for (var i = 0; i < reference.length; i++) {
        maxDiff = max(maxDiff, (reference[i] - audio.pcm[i]).abs());
      }
      // ignore: avoid_print
      print('parity ${c['name']}: max abs diff $maxDiff');
      expect(maxDiff, lessThan(double.parse(parityTolerance)),
          reason: '${c['name']}');
    }
  });

  testWidgets('speaks segments and completes after playback', (_) async {
    const segments = [
      'Daisy said,',
      'that was the cleanest clutch I have seen all week,',
      'GG everyone!',
    ];
    // The predicted durations don't depend on the noise, so this is how
    // long the utterance plays.
    var audioLength = Duration.zero;
    for (final s in segments) {
      audioLength +=
          (await tts.synthesize(s, language: 'en', voiceId: 'M2')).duration;
    }

    final events = <OnnxTtsEvent>[];
    final sub = tts.events.listen(events.add);
    final stopwatch = Stopwatch()..start();
    await tts.speak(segments,
        language: 'en', voiceId: 'M2', utteranceId: 'three');
    final elapsed = stopwatch.elapsed;
    await pumpEventQueue();
    await sub.cancel();

    expect(events.map((e) => e.type),
        [OnnxTtsEventType.firstAudio, OnnxTtsEventType.done]);
    expect(events.every((e) => e.utteranceId == 'three'), isTrue);
    final firstAudio = events[0].elapsed;
    final done = events[1].elapsed;
    expect(firstAudio, lessThan(done));
    // Completion follows the playback head, so it can't come before the
    // audio has played.
    expect(done, greaterThan(audioLength - const Duration(milliseconds: 50)));
    expect(
        elapsed, greaterThan(audioLength - const Duration(milliseconds: 50)));
    expect(elapsed, lessThan(audioLength + const Duration(seconds: 10)));
    // ignore: avoid_print
    print('speak: ${audioLength.inMilliseconds} ms of audio, first audio at '
        '${firstAudio.inMilliseconds} ms, done at ${done.inMilliseconds} ms');
  });

  testWidgets('stops mid-utterance', (_) async {
    final segments = List.filled(
        3, 'This is a long segment that keeps talking for quite a while,');
    final events = <OnnxTtsEvent>[];
    final firstAudio = Completer<void>();
    final sub = tts.events.listen((e) {
      events.add(e);
      if (e.type == OnnxTtsEventType.firstAudio) firstAudio.complete();
    });

    final speaking =
        tts.speak(segments, language: 'en', voiceId: 'F3', utteranceId: 'cut');
    await firstAudio.future;

    // Only one utterance at a time.
    await expectLater(
      tts.speak(['hi'], language: 'en', voiceId: 'F3', utteranceId: 'other'),
      throwsA(isA<PlatformException>().having((e) => e.code, 'code', 'busy')),
    );

    await Future<void>.delayed(const Duration(milliseconds: 500));
    final stopwatch = Stopwatch()..start();
    await tts.stop();
    await speaking; // completes normally
    final stopLatency = stopwatch.elapsed;
    await pumpEventQueue();
    await sub.cancel();

    expect(events.map((e) => e.type),
        [OnnxTtsEventType.firstAudio, OnnxTtsEventType.stopped]);
    expect(stopLatency, lessThan(const Duration(milliseconds: 500)));
    // ignore: avoid_print
    print('stop: speak completed ${stopLatency.inMilliseconds} ms after stop, '
        'stopped event at ${events[1].elapsed.inMilliseconds} ms');

    // The engine is free again.
    await tts.speak(['Okay.'], language: 'en', voiceId: 'F3');
  });

  testWidgets('falls back to the CPU for unavailable providers', (_) async {
    final coreml =
        await OnnxTts.load(modelDir: modelDir, provider: OnnxProvider.coreml);
    final audio =
        await coreml.synthesize('Fallback.', language: 'en', voiceId: 'F1');
    expect(rms(audio.pcm), greaterThan(0.01));
    await coreml.unload();
    await expectLater(
      coreml.synthesize('gone', language: 'en', voiceId: 'F1'),
      throwsA(
          isA<PlatformException>().having((e) => e.code, 'code', 'bad_args')),
    );
  });
}
