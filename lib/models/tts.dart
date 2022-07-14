import 'dart:async';
import 'dart:io';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:rtchat/models/messages/message.dart';
import 'package:rtchat/models/messages/tokens.dart';
import 'package:rtchat/models/messages/twitch/message.dart';
import 'package:rtchat/models/messages/twitch/user.dart';

class TtsModel extends ChangeNotifier {
  final _tts = FlutterTts();
  Future<void> _previousUtterance = Future.value();
  final Set<String> _pending = {};
  var _isRandomVoiceEnabled = false;
  var _isBotMuted = false;
  var _isEmoteMuted = false;
  var _speed = Platform.isAndroid ? 0.8 : 0.395;
  var _pitch = 1.0;
  var _isEnabled = false;
  final Set<TwitchUserModel> _mutedUsers = {};
  // this is used to ignore messages in the past.
  var _lastMessageTime = DateTime.now();

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
    if (value) {
      _lastMessageTime = DateTime.now();
    }
    say(
        SystemMessageModel(
            text: "Text-to-speech ${value ? "enabled" : "disabled"}"),
        force: true);
    notifyListeners();
  }

  bool get isRandomVoiceEnabled {
    return _isRandomVoiceEnabled;
  }

  set isRandomVoiceEnabled(bool value) {
    _isRandomVoiceEnabled = value;
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

  void say(MessageModel model, {bool force = false}) async {
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

    // make sure the message is in the future.
    if (model is! SystemMessageModel) {
      if (model.timestamp.isBefore(_lastMessageTime)) {
        return;
      }
      _lastMessageTime = model.timestamp;
    }

    final vocalization = getVocalization(model);

    // if the vocalization is empty, skip the message
    if (vocalization.isEmpty) {
      return;
    }

    final previous = _previousUtterance;
    final completer = Completer();

    _previousUtterance = completer.future;
    _pending.add(model.messageId);

    await previous;

    if ((_isEnabled || model is SystemMessageModel) &&
        _pending.contains(model.messageId)) {
      try {
        await _tts.setSpeechRate(_speed);
        await _tts.setPitch(_pitch);
        await _tts.awaitSpeakCompletion(true);
        await _tts.speak(vocalization);
      } catch (e, st) {
        FirebaseCrashlytics.instance.recordError(e, st);
      }
    }

    completer.complete();
    _pending.remove(model.messageId);
  }

  void unsay(String messageId) {
    _pending.remove(messageId);
  }

  void stop() {
    _pending.clear();
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
    if (json['isRandomVoiceEnabled'] != null) {
      _isRandomVoiceEnabled = json['isRandomVoiceEnabled'];
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
        "isRandomVoiceEnabled": isRandomVoiceEnabled,
        "pitch": pitch,
        "speed": speed,
        'mutedUsers': _mutedUsers.map((e) => e.toJson()).toList(),
      };
}
