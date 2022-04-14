import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:rtchat/models/messages/twitch/user.dart';

class TtsMessage {
  final String? messageId;
  final String text;
  final String? author;
  final bool isBot;
  final bool isCommand;

  const TtsMessage(
      {this.messageId,
      required this.text,
      this.author,
      this.isBot = false,
      this.isCommand = false});
}

class TtsModel extends ChangeNotifier {
  final _tts = FlutterTts();
  final _queue = <TtsMessage>[];
  Timer? _evictionTimer;
  var _isBotMuted = false;
  var _isEmoteMuted = false;
  var _speed = 1.0;
  var _pitch = 1.0;
  var _isEnabled = false;
  final Set<TwitchUserModel> _mutedUsers = {};

  bool get enabled {
    return _isEnabled;
  }

  set enabled(bool value) {
    _isEnabled = value;
    say(TtsMessage(text: "Text-to-speech ${value ? "enabled" : "disabled"}"),
        force: true);
    notifyListeners();
  }

  bool get isBotMuted {
    return _isBotMuted;
  }

  set isBotMuted(bool value) {
    _isBotMuted = value;
    notifyListeners();
  }

  bool get isEmoteMuted {
    return _isEmoteMuted;
  }

  set isEmoteMuted(bool value) {
    _isEmoteMuted = value;
    notifyListeners();
  }

  double get speed {
    return _speed;
  }

  set speed(double value) {
    _speed = value;
    notifyListeners();
  }

  double get pitch {
    return _pitch;
  }

  set pitch(double value) {
    _pitch = value;
    notifyListeners();
  }

  bool isMuted(TwitchUserModel user) {
    return _mutedUsers.contains(user);
  }

  void mute(TwitchUserModel model) {
    _mutedUsers.add(model);
    notifyListeners();
  }

  void unmute(TwitchUserModel model) {
    if (_mutedUsers.remove(model)) {
      notifyListeners();
    }
  }

  void say(TtsMessage text, {bool force = false}) {
    if (!enabled && !force) {
      return;
    }
    // we have to manage our own queue here because queueing is not supported on ios.

    // add this text to the queue
    _queue.add(text);

    // start the evictor if it isn't already running
    _evictionTimer ??= _evictNext();
  }

  void unsay(String messageId) {
    // remove this text from the queue if it exists.
    _queue.removeWhere((m) => m.messageId == messageId);
  }

  Timer _evictNext() {
    return Timer(const Duration(milliseconds: 100), () {
      // if the queue is empty, stop the timer
      if (_queue.isEmpty) {
        _evictionTimer = null;
        return;
      }

      // remove the first item from the queue
      final message = _queue.removeAt(0);

      // speak with tts.
      _tts.setSpeechRate(_speed);
      _tts.setPitch(_pitch);
      _tts.speak(message.text);
      _tts.completionHandler = () {
        _evictionTimer = _evictNext();
      };
    });
  }

  TtsModel.fromJson(Map<String, dynamic> json) {
    if (json['isBotMuted'] != null) {
      _isBotMuted = json['isBotMuted'];
    }
    if (json['pitch'] != null) {
      _pitch = json['pitch'];
    }
    if (json['speed'] != null) {
      _speed = json['speed'];
    }
    if (json['isEmoteMuted'] != null) {
      _isEmoteMuted = json['isEmoteMuted'];
    }
    final userJson = json['mutedUsers'];
    if (userJson != null) {
      for (var user in userJson) {
        _mutedUsers.add(TwitchUserModel.fromJson(user));
      }
    }
  }

  Map<String, dynamic> toJson() => {
        "isBotMuted": isBotMuted,
        "isEmoteMuted": isEmoteMuted,
        "pitch": pitch,
        "speed": speed,
        'mutedUsers': _mutedUsers.map((e) => e.toJson()).toList(),
      };
}
