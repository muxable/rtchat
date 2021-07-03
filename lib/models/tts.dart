import 'package:flutter_tts/flutter_tts.dart';

final validateUrl = Uri.https('id.twitch.tv', '/oauth2/validate');

const twitchClientId = "edfnh2q85za8phifif9jxt3ey6t9b9";

final BOT_LIST = [
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
].toSet();

class TtsModel {
  final FlutterTts _tts = FlutterTts();
  final List<String> _queue = [];
  bool _enabled = false;
  bool _isBotMuted = false;

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

  String getMsgAuthor(String message) {
    final parts = message.split(' ');
    return parts[0];
  }

  void speak(String message) {
    if (!_enabled) {
      return;
    }
    var author = getMsgAuthor(message).toLowerCase();
    if (_isBotMuted && BOT_LIST.contains(author)) {
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

  bool get isBotMuted {
    return _isBotMuted;
  }

  set isBotMuted(bool value) {
    _isBotMuted = value;
  }
}
