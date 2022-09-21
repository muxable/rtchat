import 'dart:async';
import 'dart:core';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:rtchat/models/adapters/messages.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/messages/message.dart';
import 'package:rtchat/models/messages/twitch/message.dart';
import 'package:rtchat/models/tts.dart';

class MessagesModel extends ChangeNotifier {
  StreamSubscription<void>? _subscription;
  List<MessageModel> _messages = [];
  Set<int> _separators = {};
  int? _initialMessageCount;
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
    _separators = {};
    _tts?.enabled = false;
    notifyListeners();

    _subscription?.cancel();
    if (channel != null) {
      _initialMessageCount = null;
      _subscription =
          MessagesAdapter.instance.forChannel(channel).listen((event) {
        if (event is AppendDeltaEvent) {
          // check if this event comes after the last message
          if (_messages.isNotEmpty &&
              event.model.timestamp.isBefore(_messages.last.timestamp)) {
            // this message is out of order, so we need to insert it in the right place
            final index = _messages.indexWhere(
                (element) => element.timestamp.isAfter(event.model.timestamp));
            _messages.insert(index, event.model);
          } else {
            _messages.add(event.model);
            _tts?.say(event.model);
          }
          // check to see if we should add a separator
          // always add if it's the first message.
          if (_messages.length == 1) {
            _separators.add(0);
          } else {
            final lastSeparator =
                _separators.isEmpty ? 0 : _separators.reduce(max);
            // add if the last separator was at least 50 away and this was a
            // chat message.
            if (_messages.length - lastSeparator >= 50 &&
                event.model is TwitchMessageModel) {
              _separators.add(_messages.length - 1);
            }
            // add if the difference between this message and the last message
            // is more than 5 minutes.
            final cmp = _messages[_messages.length - 2];
            if (event.model.timestamp.difference(cmp.timestamp).inMinutes > 5) {
              _separators.add(_messages.length - 1);
            }
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
          _separators = {};
          _tts?.stop();
        } else if (event is LiveStateDeltaEvent) {
          _initialMessageCount = _messages.length;
        }
        notifyListeners();
      });
    }
  }

  List<MessageModel> get messages => _messages;

  Set<int> get separators => _separators;

  bool get hasLiveMessages =>
      _initialMessageCount != null && _messages.length > _initialMessageCount!;

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
    if (messages.isEmpty || !hasLiveMessages) {
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
