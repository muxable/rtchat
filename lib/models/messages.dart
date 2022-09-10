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
          if (_messages.isNotEmpty &&
              _messages.last.timestamp.isAfter(event.model.timestamp)) {
            // this message is out of order, so we need to insert it in the right place
            final index = _messages.indexWhere(
                (element) => element.timestamp.isAfter(event.model.timestamp));
            _messages.insert(index, event.model);
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
        }
        notifyListeners();
      });
    }
  }

  List<MessageModel> get messages => _messages;

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
}
