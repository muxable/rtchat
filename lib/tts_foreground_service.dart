import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/tts.dart';

/// Runs an Android foreground service while text to speech is on. Without it
/// Android freezes the app shortly after it's backgrounded (and mutes its
/// audio), so chat stops being read out mid-stream.
class TtsForegroundService {
  static const channel = MethodChannel('com.rtirl.chat/tts_service');

  final TtsModel model;
  final AppLocalizations Function() localizations;
  final bool enabled;
  TtsMode _mode = TtsMode.disabled;

  bool get _running => _mode != TtsMode.disabled;

  TtsForegroundService(this.model, this.localizations, {bool? enabled})
    : enabled =
          enabled ??
          (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    if (!this.enabled) {
      return;
    }
    channel.setMethodCallHandler((call) async {
      // the notification's "turn off" button.
      if (call.method == 'turnOff') {
        model.setMode(localizations(), TtsMode.disabled);
      }
    });
    model.addListener(_sync);
    _sync();
  }

  void _sync() {
    if (model.mode == _mode) {
      return;
    }
    _mode = model.mode;
    // starting again while running just updates the notification.
    if (_running) {
      final l10n = localizations();
      channel
          .invokeMethod('start', {
            'title': l10n.textToSpeech,
            'text':
                model.mode == TtsMode.alertsOnly
                    ? l10n.alertsEnabled
                    : l10n.textToSpeechEnabled,
            'turnOff': l10n.turnOffTextToSpeech,
          })
          .catchError((e) => debugPrint('failed to start tts service: $e'));
    } else {
      channel
          .invokeMethod('stop')
          .catchError((e) => debugPrint('failed to stop tts service: $e'));
    }
  }

  void dispose() {
    if (!enabled) {
      return;
    }
    model.removeListener(_sync);
    channel.setMethodCallHandler(null);
    if (_running) {
      _mode = TtsMode.disabled;
      channel.invokeMethod('stop').catchError((_) => null);
    }
  }
}
