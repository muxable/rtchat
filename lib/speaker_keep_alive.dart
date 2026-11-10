import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Records an error that didn't stop the app, e.g. to Crashlytics.
typedef KeepAliveErrorReporter = void Function(Object error, StackTrace stack);

void _recordToCrashlytics(Object error, StackTrace stack) =>
    FirebaseCrashlytics.instance.recordError(error, stack);

/// Plays an inaudible clip every [interval] so that Bluetooth speakers which
/// power down after a few idle minutes are still connected for the next
/// alert.
///
/// The clip is synthesized in memory instead of shipped as an asset: an
/// asset is copied to the cache directory first, which Android may clear at
/// any time, and the player then fails with `FileNotFoundException` when it
/// opens the copy. On Android the bytes go straight to `MediaPlayer`, so no
/// file is involved; on iOS audioplayers writes them out again on every
/// play, so a missing file is rewritten instead of failing.
class SpeakerKeepAlive {
  final AudioPlayer _player;
  final KeepAliveErrorReporter _onError;
  late final Timer _timer;

  SpeakerKeepAlive({
    AudioPlayer? player,
    Duration interval = const Duration(minutes: 5),
    KeepAliveErrorReporter onError = _recordToCrashlytics,
  }) : _player = player ?? AudioPlayer(),
       _onError = onError {
    _timer = Timer.periodic(interval, (_) => ping());
  }

  /// Plays the clip once. Never throws: a speaker that isn't kept awake is
  /// not worth crashing over, so failures go to the error reporter.
  Future<void> ping() async {
    try {
      await _player.play(
        BytesSource(keepAliveClip, mimeType: "audio/wav"),
        ctx:
            AudioContextConfig(
              focus: AudioContextConfigFocus.mixWithOthers,
            ).build(),
      );
    } catch (error, stack) {
      _onError(error, stack);
    }
  }

  Future<void> dispose() async {
    _timer.cancel();
    await _player.dispose();
  }
}

/// Half a second of 8 kHz, 16-bit mono PCM holding only ±1 LSB of dither
/// (about -90 dBFS), as a WAV file.
///
/// Digital zeros would do for the Bluetooth link, but some speakers also
/// power down when their input carries no signal; the dither keeps a signal
/// present while staying far below what a speaker can reproduce audibly.
final Uint8List keepAliveClip = _ditheredSilenceWav(
  sampleRate: 8000,
  samples: 4000,
);

Uint8List _ditheredSilenceWav({required int sampleRate, required int samples}) {
  const headerSize = 44;
  const bytesPerSample = 2;
  final dataSize = samples * bytesPerSample;
  final wav = ByteData(headerSize + dataSize);

  void ascii(int offset, String text) {
    for (var i = 0; i < text.length; i++) {
      wav.setUint8(offset + i, text.codeUnitAt(i));
    }
  }

  ascii(0, "RIFF");
  wav.setUint32(4, headerSize - 8 + dataSize, Endian.little);
  ascii(8, "WAVE");
  ascii(12, "fmt ");
  wav.setUint32(16, 16, Endian.little); // fmt chunk size
  wav.setUint16(20, 1, Endian.little); // PCM
  wav.setUint16(22, 1, Endian.little); // mono
  wav.setUint32(24, sampleRate, Endian.little);
  wav.setUint32(28, sampleRate * bytesPerSample, Endian.little); // byte rate
  wav.setUint16(32, bytesPerSample, Endian.little); // block align
  wav.setUint16(34, 16, Endian.little); // bits per sample
  ascii(36, "data");
  wav.setUint32(40, dataSize, Endian.little);

  // triangular dither from two bits of a xorshift generator, seeded so the
  // clip is the same on every launch.
  var state = 0x2545F491;
  for (var i = 0; i < samples; i++) {
    state ^= (state << 13) & 0xFFFFFFFF;
    state ^= state >> 17;
    state ^= (state << 5) & 0xFFFFFFFF;
    final sample = (state & 1) + ((state >> 1) & 1) - 1;
    wav.setInt16(headerSize + i * bytesPerSample, sample, Endian.little);
  }
  return wav.buffer.asUint8List();
}
