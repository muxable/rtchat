import 'dart:async';
import 'dart:core';

import 'package:flutter/foundation.dart';
import 'package:rtchat/models/adapters/messages.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/messages/message.dart';
import 'package:rtchat/models/messages/twitch/message.dart';
import 'package:rtchat/models/tts.dart';

class MessagesModel extends ChangeNotifier {
  StreamSubscription<void>? _subscription;
  List<MessageModel> _messages = [];
  int _initialMessageCount = 0;
  Channel? _channel;

  // it's a bit odd to have this here, but tts only cares about the delta events
  // so it's easier to wire this way.
  TtsModel? _tts;

  set channel(Channel? channel) {
    // ignore if no update
    if (channel == _channel) {
      return;
    }
    _channel = channel;
    _messages = [];
    _tts?.enabled = false;
    notifyListeners();

    _subscription?.cancel();
    if (channel != null) {
      _subscription =
          MessagesAdapter.instance.forChannel(channel).listen((event) {
        if (event is AppendDeltaEvent) {
          // check if this event comes after the last message
          if (_messages.isNotEmpty) {
            final delta =
                event.model.timestamp.difference(_messages.last.timestamp);
            if (delta.isNegative) {
              // this message is out of order, so we need to insert it in the right place
              final index = _messages.indexWhere((element) =>
                  element.timestamp.isAfter(event.model.timestamp));
              _messages.insert(index, event.model);
            } else if (delta.compareTo(const Duration(minutes: 1)) > 0) {
              // this message is more than one minute after the last message so
              // insert a timestamp.
              _messages.add(SeparatorModel(event.model.timestamp));
              _messages.add(event.model);
              _tts?.say(event.model);
            } else {
              // this message is in order, so we can just append it
              _messages.add(event.model);
              _tts?.say(event.model);
            }
          } else {
            _messages.add(event.model);
            _tts?.say(event.model);
          }
        } else if (event is UpdateDeltaEvent) {
          for (var i = 0; i < _messages.length; i++) {
            final message = _messages[i];
            if (message.messageId == event.messageId) {
              _messages[i] = event.update(message);
              if (message is TwitchMessageModel && message.deleted) {
                _tts?.unsay(message.messageId);
              }
            }
          }
        } else if (event is ClearDeltaEvent) {
          _messages = [
            ChatClearedEventModel(
              messageId: event.messageId,
              timestamp: event.timestamp,
            )
          ];
          _tts?.stop();
        } else if (event is LiveStateDeltaEvent) {
          _initialMessageCount = _messages.length;
        }
        notifyListeners();
      });
    }
  }

  List<MessageModel> get messages => _messages;

  bool get hasLiveMessages => _messages.length > _initialMessageCount;

  set tts(TtsModel? tts) {
    // ignore if no update
    if (tts == _tts) {
      return;
    }
    _tts = tts;
    tts?.enabled = false;
    notifyListeners();
  }

  TtsModel? get tts => _tts;

  Duration _announcementPinDuration = const Duration(seconds: 10);

  set announcementPinDuration(Duration duration) {
    _announcementPinDuration = duration;
    notifyListeners();
  }

  Duration get announcementPinDuration => _announcementPinDuration;

  Duration _pingMinGapDuration = const Duration(minutes: 1);

  set pingMinGapDuration(Duration duration) {
    _pingMinGapDuration = duration;
    notifyListeners();
  }

  Duration get pingMinGapDuration => _pingMinGapDuration;

  bool shouldPing() {
    if (messages.isEmpty) {
      return false;
    }
    if (messages.length == 1) {
      return messages.last.timestamp
          .isAfter(DateTime.now().subtract(const Duration(seconds: 1)));
    }
    final lastMessage = messages.last;
    final secondLastMessage = messages[messages.length - 2];
    final delta = lastMessage.timestamp.difference(secondLastMessage.timestamp);
    return delta.compareTo(_pingMinGapDuration) > 0;
  }

  MessagesModel.fromJson(Map<String, dynamic> json) {
    if (json['announcementPinDuration'] != null) {
      _announcementPinDuration =
          Duration(seconds: json['announcementPinDuration'].toInt());
    }
    if (json['pingMinGapDuration'] != null) {
      _pingMinGapDuration =
          Duration(seconds: json['pingMinGapDuration'].toInt());
    }
  }

  Map<String, dynamic> toJson() => {
        "announcementPinDuration": _announcementPinDuration.inSeconds.toInt(),
        "pingMinGapDuration": _pingMinGapDuration.inSeconds.toInt(),
      };
}
