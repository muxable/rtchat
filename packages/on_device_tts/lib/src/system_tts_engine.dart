import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

import 'tts_engine.dart';
import 'tts_voice.dart';

/// Speaks with the platform's own voices through `flutter_tts`.
///
/// On Android, synthesizes a temporary WAV and plays it inside this process,
/// so the app's foreground service covers background audio playback.
/// On iOS speech plays in the playback audio category, mixed with other
/// audio, so it keeps going in the background and doesn't pause music.
class SystemTtsEngine implements TtsEngine {
  final FlutterTts _tts;
  final String? Function() _platformLanguage;
  final Future<Directory> Function() _tempDirectory;
  AudioPlayer? _player;
  _Utterance? _utterance;
  bool _disposed = false;

  // What the platform was last asked to speak with: a voice, else a
  // language, else (both null) its default voice.
  TtsVoice? _voice;
  String? _language;

  /// Creates an engine on [tts], or on a new [FlutterTts] when omitted.
  ///
  /// [platformLanguage] is the language to go back to after speaking in
  /// another one, on platforms where clearing the voice doesn't restore it:
  /// by default the device's language on iOS and macOS, and nothing
  /// elsewhere (Android's default voice carries its language).
  SystemTtsEngine({
    FlutterTts? tts,
    String? Function()? platformLanguage,
    @visibleForTesting AudioPlayer? audioPlayer,
    @visibleForTesting Future<Directory> Function()? tempDirectory,
  })  : _tts = tts ?? FlutterTts(),
        _platformLanguage = platformLanguage ?? _devicePlatformLanguage,
        _player = audioPlayer,
        _tempDirectory = tempDirectory ?? getTemporaryDirectory {
    _tts
      ..setSharedInstance(true)
      ..setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [IosTextToSpeechAudioCategoryOptions.mixWithOthers],
          IosTextToSpeechAudioMode.voicePrompt);
  }

  static String? _devicePlatformLanguage() => switch (defaultTargetPlatform) {
        TargetPlatform.iOS ||
        TargetPlatform.macOS =>
          PlatformDispatcher.instance.locale.toLanguageTag(),
        _ => null,
      };

  /// With a [voice], that voice speaks. Otherwise, with a [language], the
  /// platform's voice for that language speaks: the full tag if the
  /// platform has it, else its primary language (`pt` for `pt-BR`), else
  /// the default voice. Without either, the platform's default voice speaks.
  @override
  Future<void> speak(
    String text, {
    TtsVoice? voice,
    double rate = TtsEngine.normalRate,
    double pitch = TtsEngine.normalPitch,
    String? language,
  }) async {
    if (_disposed) throw StateError('The TTS engine has been disposed');
    final utterance = _Utterance();
    _utterance = utterance;
    try {
      await _speak(text, voice, rate, pitch, language, utterance);
    } on _SpeechCanceled {
      // stop() releases the queue even if the platform never completes synthesis.
    } finally {
      if (identical(_utterance, utterance)) _utterance = null;
    }
  }

  Future<void> _speak(String text, TtsVoice? voice, double rate, double pitch,
      String? language, _Utterance utterance) async {
    await _tts.setSpeechRate(rate);
    await _tts.setPitch(pitch);
    if (voice != null) {
      if (voice != _voice) {
        await _tts.setVoice({'name': voice.id, 'locale': voice.locale});
        _voice = voice;
        _language = null;
      }
    } else if (language != null) {
      if (_voice != null || language != _language) {
        await _setLanguage(language);
        _voice = null;
        _language = language;
      }
    } else if (_voice != null || _language != null) {
      await _useDefaultVoice(restoreLanguage: _language != null);
      _voice = null;
      _language = null;
    }
    utterance.checkCanceled();
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await _speakInProcess(text, utterance);
    } else {
      await _tts.awaitSpeakCompletion(true);
      utterance.checkCanceled();
      await utterance.wait(_tts.speak(text));
    }
  }

  Future<void> _speakInProcess(String text, _Utterance utterance) async {
    final directory = await _tempDirectory();
    utterance.checkCanceled();
    // Unique paths prevent a late platform callback from overwriting later audio.
    final temporary = await directory.createTemp('tts-');
    final file = File('${temporary.path}/speech.wav');
    try {
      await _tts.awaitSynthCompletion(true);
      utterance.checkCanceled();
      Object? result;
      try {
        result = await utterance.wait(_tts
            .synthesizeToFile(text, file.path, true)
            .timeout(const Duration(seconds: 30)));
      } catch (_) {
        // Reset flutter_tts's synthesis state after a timeout or platform error.
        // Cancellation already stops the platform before releasing this wait.
        if (!utterance.canceled) await _tts.stop();
        rethrow;
      }
      if (result != 1) throw StateError('TTS synthesis failed: $result');
      utterance.checkCanceled();
      final player = _player ??= AudioPlayer();
      try {
        final duration = await utterance.wait(
            player.setFilePath(file.path).timeout(const Duration(seconds: 10)));
        utterance.checkCanceled();
        final completed = Completer<void>();
        final subscription = player.processingStateStream.listen((state) {
          if (state == ProcessingState.completed && !completed.isCompleted) {
            completed.complete();
          }
        }, onError: (Object error, StackTrace stack) {
          if (!completed.isCompleted) completed.completeError(error, stack);
        });
        try {
          // play() can complete immediately if the player is already playing.
          // Observe completion separately, and surface errors from either future.
          final playback = Future.wait([
            player.play(),
            completed.future,
          ], eagerError: true);
          await utterance.wait(playback.timeout(
              (duration ?? const Duration(seconds: 30)) +
                  const Duration(seconds: 5)));
        } finally {
          await subscription.cancel();
        }
      } finally {
        await player.stop();
      }
    } finally {
      await temporary.delete(recursive: true);
    }
  }

  Future<void> _setLanguage(String language) async {
    if (await _tts.setLanguage(language) == 1) return;
    final primary = language.replaceAll('_', '-').split('-').first;
    if (primary != language && await _tts.setLanguage(primary) == 1) return;
    await _useDefaultVoice(restoreLanguage: true);
  }

  Future<void> _useDefaultVoice({required bool restoreLanguage}) async {
    await _tts.clearVoice();
    final platformLanguage = restoreLanguage ? _platformLanguage() : null;
    if (platformLanguage != null) {
      await _tts.setLanguage(platformLanguage);
    }
  }

  @override
  Future<void> stop() async {
    final utterance = _utterance;
    utterance?.canceled = true;
    try {
      await Future.wait([
        _tts.stop(),
        if (_player != null) _player!.stop(),
      ]);
    } finally {
      if (utterance != null && !utterance.stopped.isCompleted) {
        utterance.stopped.complete();
      }
    }
  }

  @override
  Future<List<TtsVoice>> voices({String? language}) async {
    final result = await _tts.getVoices;
    final voices = <TtsVoice>[];
    if (result is List) {
      for (final entry in result) {
        if (entry is! Map) continue;
        final name = entry['name'];
        final locale = entry['locale'];
        if (name is! String || locale is! String) continue;
        voices.add(TtsVoice(id: name, name: name, locale: locale));
      }
    }
    if (language == null) {
      return voices;
    }
    return voices.where((voice) => voice.speaks(language)).toList();
  }

  /// The platform's voices live outside the app: nothing to free.
  @override
  Future<void> release() async {}

  @override
  Future<void> dispose() async {
    _disposed = true;
    try {
      await stop();
    } finally {
      await _player?.dispose();
    }
  }
}

class _SpeechCanceled implements Exception {}

class _Utterance {
  bool canceled = false;
  final stopped = Completer<void>();

  void checkCanceled() {
    if (canceled) throw _SpeechCanceled();
  }

  Future<T> wait<T>(Future<T> operation) async {
    try {
      final result = await Future.any([
        operation,
        stopped.future.then<T>((_) => throw _SpeechCanceled()),
      ]);
      checkCanceled();
      return result;
    } catch (_) {
      // A platform operation may fail as stop() interrupts it. Wait until
      // stopping finishes before cleanup, and treat it as cancellation.
      if (canceled) {
        await stopped.future;
        throw _SpeechCanceled();
      }
      rethrow;
    }
  }
}
