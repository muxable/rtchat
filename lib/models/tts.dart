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
  final bool hasEmote;
  final Map<String, dynamic>? emotes;

  const TtsMessage(
      {required this.messageId,
      required this.author,
      required this.message,
      this.coalescingHeader,
      required this.hasEmote,
      this.emotes});

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
  bool _isEmoteMuted = false;
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
      if (_isEmoteMuted && message.hasEmote) {
        var filterMsg = filterEmotes(message.emotes!, message.message);
        _tts.speak(filterMsg);
      } else {
        _tts.speak(message.spokenMessage);
      }
    }
    _queue.add(message);
  }

  List parseEmotes(Map<String, dynamic> emotes) {
    var ranges = [];
    for (MapEntry e in emotes.entries) {
      for (final str in e.value) {
        final pair = str.split('-');
        final start = int.parse(pair[0]);
        final end = int.parse(pair[1]);
        ranges.add([start, end]);
      }
    }

    ranges.sort((a, b) => a[0].compareTo(b[0]));
    return ranges;
  }

  String filterEmotes(Map<String, dynamic> emotes, String message) {
    var ranges = parseEmotes(emotes);
    var res = "";
    var index = 0;
    for (var i = 0; i < ranges.length; i++) {
      var start = ranges[i][0];
      var end = ranges[i][1];
      if (start > index) {
        res += message.substring(index, start);
      }
      index = end + 1;
    }

    if (index < message.length) {
      res += message.substring(index);
    }
    return res;
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

  bool get isEmoteMuted {
    return _isEmoteMuted;
  }

  set isEmoteMuted(bool value) {
    _isEmoteMuted = value;
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
    if (json['isEmoteMuted'] != null) {
      _isEmoteMuted = json['isEmoteMuted'];
    }
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
        "isEmoteMuted": _isEmoteMuted,
      };
}
