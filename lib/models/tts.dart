import 'package:flutter_tts/flutter_tts.dart';

final validateUrl = Uri.https('id.twitch.tv', '/oauth2/validate');

const twitchClientId = "edfnh2q85za8phifif9jxt3ey6t9b9";

const botList = {
  'streamlab',
  'streamlabs',
  'nightbot',
  'xanbot',
  'ankhbot',
  'moobot',
  'wizebot',
  'phantombot',
  'streamelements',
  'streamelement'
};

class TtsModel {
  final FlutterTts _tts = FlutterTts();
  final List<String> _queue = [];
  bool _enabled = false;
  bool _isBotMuted = false;
  double _speed = 1;
  double _pitch = 1;

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

  void speak(String author, String message, {bool force = false}) {
    if (!_enabled && !force) {
      return;
    }
    if (_isBotMuted && botList.contains(author.toLowerCase())) {
      return;
    }
    if (_queue.isEmpty) {
      _tts.setPitch(pitch);
      _tts.setSpeechRate(speed);
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

  bool get isBotMuted {
    return _isBotMuted;
  }

  set isBotMuted(bool value) {
    _isBotMuted = value;
  }

  double get speed {
    return _speed;
  }

  set speed(double value) {
    _speed = value;
    _tts.setSpeechRate(speed);
  }

  double get pitch {
    return _pitch;
  }

  set pitch(double value) {
    _pitch = value;
    _tts.setPitch(pitch);
  }
}
