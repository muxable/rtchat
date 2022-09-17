import 'dart:async';
import 'dart:core';

import 'package:audioplayers/audioplayers.dart';
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
  final _player = AudioPlayer();

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
            } else if (_messages.last is TwitchMessageModel &&
                delta.compareTo(const Duration(minutes: 1)) > 0) {
              // this message is more than one minute after the last message
              // if the previous message is also a chat message, then we need to insert a separator with a timestamp
              // and play an alert sound.
              _messages.add(SeparatorModel(event.model.timestamp));
              _player.play('assets/message-sound.wav');
              _messages.add(event.model);
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
