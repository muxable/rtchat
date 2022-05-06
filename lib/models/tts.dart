import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:rtchat/models/messages/message.dart';
import 'package:rtchat/models/messages/tokens.dart';
import 'package:rtchat/models/messages/twitch/message.dart';
import 'package:rtchat/models/messages/twitch/user.dart';

class TtsModel extends ChangeNotifier {
  final _tts = FlutterTts();
  final _queue = <MessageModel>[];
  Timer? _evictionTimer;
  var _isBotMuted = false;
  var _isEmoteMuted = false;
  var _speed = Platform.isAndroid ? 0.8 : 0.395;
  var _pitch = 1.0;
  var _isEnabled = false;
  final Set<TwitchUserModel> _mutedUsers = {};

  String getVocalization(MessageModel model) {
    if (model is TwitchMessageModel) {
      final text = model.tokenized
          .where((token) =>
              token is TextToken ||
              (!_isEmoteMuted && token is EmoteToken) ||
              token is UserMentionToken ||
              token is LinkToken)
          .map((token) {
        if (token is TextToken) {
          return token.text;
        } else if (token is EmoteToken) {
          return token.code;
        } else if (token is UserMentionToken) {
          return token.username.replaceAll("_", " ");
        } else if (token is LinkToken) {
          return token.url.host;
        }
      }).join("");
      if (text.trim().isEmpty) {
        return "";
      }
      final author = model.author.displayName ?? model.author.login;
      return model.isAction ? "$author $text" : "$author said $text";
    } else if (model is StreamStateEventModel) {
      return model.isOnline ? "Stream is online" : "Stream is offline";
    } else if (model is SystemMessageModel) {
      return model.text;
    }
    return "";
  }

  bool get enabled {
    return _isEnabled;
  }

  set enabled(bool value) {
    if (value == _isEnabled) {
      return;
    }
    _isEnabled = value;
    if (!value) {
      _queue.clear();
      _evictionTimer?.cancel();
      _evictionTimer = null;
    }
    say(
        SystemMessageModel(
            text: "Text-to-speech ${value ? "enabled" : "disabled"}"),
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

  void say(MessageModel model, {bool force = false}) {
    if (!enabled && !force) {
      return;
    }
    // we have to manage our own queue here because queueing is not supported on ios.

    if (model is TwitchMessageModel) {
      if (_mutedUsers.any((user) =>
          user.displayName?.toLowerCase() ==
          model.author.displayName?.toLowerCase())) {
        return;
      }

      if ((_isBotMuted && model.author.isBot) || model.isCommand) {
        return;
      }
    }

    final vocalization = getVocalization(model);

    // if the vocalization is empty, skip the message
    if (vocalization.isEmpty) {
      return;
    }

    // add this text to the queue
    _queue.add(model);

    // start the evictor if it isn't already running
    _evictionTimer ??= _evictNext();
  }

  void unsay(String messageId) {
    // remove this text from the queue if it exists.
    _queue.removeWhere((m) => m.messageId == messageId);
  }

  Timer _evictNext() {
    return Timer(const Duration(milliseconds: 100), () async {
      // if the queue is empty, stop the evictor
      if (_queue.isEmpty) {
        _evictionTimer = null;
        return;
      }

      // remove the first item from the queue
      final message = _queue.removeAt(0);

      // speak with tts.
      _tts.setCompletionHandler(() {
        _evictionTimer = _evictNext();
      });
      await _tts.setSpeechRate(_speed);
      await _tts.setPitch(_pitch);
      await _tts.speak(getVocalization(message));
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
