import 'package:flutter/foundation.dart';
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

class TtsMessage {
  final String messageId;
  final String author;
  final String? coalescingHeader;
  final String message;

  const TtsMessage(
      {required this.messageId,
      required this.author,
      required this.message,
      this.coalescingHeader});

  String get spokenMessage {
    if (coalescingHeader != null) {
      return "$coalescingHeader $message";
    }
    return message;
  }
}

class TtsModel extends ChangeNotifier {
  final FlutterTts _tts = FlutterTts();
  final List<TtsMessage> _queue = [];
  bool _enabled = false;
  bool _isBotMuted = false;
  double _speed = 1;
  double _pitch = 1;

  void speak(TtsMessage message, {bool force = false}) {
    if (!_enabled && !force) {
      return;
    }
    if (_isBotMuted && botList.contains(message.author.toLowerCase())) {
      return;
    }
    if (_queue.isEmpty) {
      _tts.setPitch(pitch);
      _tts.setSpeechRate(speed);
      _tts.speak(message.spokenMessage);
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
    notifyListeners();
  }

  bool get isBotMuted {
    return _isBotMuted;
  }

  set isBotMuted(bool value) {
    _isBotMuted = value;
    notifyListeners();
  }

  double get speed {
    return _speed;
  }

  set speed(double value) {
    _speed = value;
    _tts.setSpeechRate(speed);
    notifyListeners();
  }

  double get pitch {
    return _pitch;
  }

  set pitch(double value) {
    _pitch = value;
    _tts.setPitch(pitch);
    notifyListeners();
  }

  TtsModel.fromJson(Map<String, dynamic> json) {
    _tts.setCompletionHandler(() {
      if (_queue.isEmpty) {
        return;
      }
      _queue.removeAt(0);
      if (_queue.isNotEmpty) {
        _tts.speak(_queue.first.spokenMessage);
      }
    });
    if (json['isBotMuted'] != null) {
      _isBotMuted = json['isBotMuted'];
    }
    if (json['pitch'] != null) {
      _pitch = json['pitch'];
    }
    if (json['speed'] != null) {
      _speed = json['speed'];
    }
  }

  Map<String, dynamic> toJson() => {
        "isBotMuted": _isBotMuted,
        "pitch": _pitch,
        "speed": _speed,
      };
}
