// Flutter entry point for a cold and two warm runs through the native player.
// Stage supertonic-3 in the app's documents directory.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:on_device_tts/on_device_tts.dart';
import 'package:path_provider/path_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dir = await getApplicationDocumentsDirectory();
  final report = File('${dir.path}/playback.jsonl');
  await report.writeAsString('');
  void record(Map<String, Object?> row) {
    report.writeAsStringSync(
      '${jsonEncode(row)}\n',
      mode: FileMode.append,
      flush: true,
    );
  }

  const segments = [
    'Daisy said,',
    'that was the cleanest clutch I have seen all week,',
    'GG everyone!',
  ];
  try {
    final load = Stopwatch()..start();
    final tts = await OnnxTts.load(modelDir: '${dir.path}/supertonic-3');
    record({'load_ms': load.elapsedMilliseconds});
    try {
      final message = segments.join(' ');
      // The last run presents exactly the same words as one model input.
      for (final round in <int?>[1, 2, 3, null]) {
        final id = round == null ? 'unsplit' : 'profile-$round';
        final events = tts.events.where((e) => e.utteranceId == id).take(2);
        final received = events.toList().timeout(const Duration(minutes: 10));
        final clock = Stopwatch()..start();
        if (round == null) {
          await tts.speak(
            [message],
            language: 'en',
            voiceId: 'M2',
            utteranceId: id,
          );
        } else {
          await tts.speakText(
            message,
            language: 'en',
            voiceId: 'M2',
            utteranceId: id,
          );
        }
        final wall = clock.elapsedMilliseconds;
        final playback = await received;
        final first = playback.singleWhere(
          (e) => e.type == OnnxTtsEventType.firstAudio,
        );
        final done = playback.singleWhere(
          (e) => e.type == OnnxTtsEventType.done,
        );
        record({
          if (round == null) 'unsplit': true else 'round': round,
          'first_audio_ms': first.elapsed.inMilliseconds,
          'last_pcm_ready_ms': done.lastPcmReady!.inMilliseconds,
          'done_ms': done.elapsed.inMilliseconds,
          'speak_ms': wall,
        });
      }
      // Measure generation independently of AudioTrack/AVAudioEngine, which
      // deliberately block speak() until all queued samples have played.
      for (var round = 1; round <= 3; round++) {
        var samples = 0;
        var audioSeconds = 0.0;
        final segmentMicros = <int>[];
        final segmentRtf = <double>[];
        final clock = Stopwatch()..start();
        await for (final audio in tts.synthesizeStream(
          message,
          language: 'en',
          voiceId: 'M2',
          noiseSeed: 3 * round,
        )) {
          clock.stop();
          final seconds = audio.pcm.length / audio.sampleRate;
          if (seconds <= 0)
            throw StateError(
              'Empty audio for phrase ${segmentMicros.length + 1}',
            );
          samples += audio.pcm.length;
          audioSeconds += seconds;
          segmentMicros.add(clock.elapsedMicroseconds);
          segmentRtf.add(clock.elapsedMicroseconds / (1e6 * seconds));
          clock.reset();
          clock.start();
        }
        if (segmentMicros.length != segments.length || samples != 297611) {
          throw StateError(
            'Unexpected streaming output: ${segmentMicros.length} phrases, $samples samples',
          );
        }
        final micros = segmentMicros.reduce((a, b) => a + b);
        record({
          'synthesis_round': round,
          'samples': samples,
          'audio_ms': audioSeconds * 1000,
          'synthesis_ms': micros / 1000,
          'rtf': micros / (1e6 * audioSeconds),
          'segment_rtf': segmentRtf,
        });
      }
    } finally {
      await tts.unload();
    }
    record({'complete': true});
  } catch (error, stack) {
    record({'error': error.toString(), 'stack': stack.toString()});
    rethrow;
  }
}
