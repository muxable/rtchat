import 'package:flutter_tts/flutter_tts.dart';

final validateUrl = Uri.https('id.twitch.tv', '/oauth2/validate');

const twitchClientId = "edfnh2q85za8phifif9jxt3ey6t9b9";

class TtsModel {
  final FlutterTts _tts = FlutterTts();
  final List<String> _queue = [];
  bool _enabled = false;

  TtsModel() {
    _tts.setCompletionHandler(() {
      if (_queue.isEmpty) {
        return;
      }
      _queue.removeAt(0);
      if (_queue.isNotEmpty) {
        _tts.speak(_queue.first);
      }
    });
  }

  void speak(String message) {
    if (!_enabled) {
      return;
    }
    if (_queue.isEmpty) {
      _tts.speak(message);
    }
    _queue.add(message);
  }

  bool get enabled {
    return _enabled;
  }

  set enabled(bool value) {
    _enabled = value;
    if (!value) {
      _queue.clear();
      _tts.stop();
    }
  }
}
