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

  TtsMessage? toTtsMessage(MessageModel model) {
    if (model is TwitchMessageModel) {
      return TtsMessage(
        messageId: model.messageId,
        author: model.author.display,
        text: "${model.author.display} said ${model.tokenized.join("")}",
        isBot: model.author.isBot,
        isCommand: model.isCommand,
      );
    } else if (model is StreamStateEventModel) {
      return TtsMessage(
        messageId: model.messageId,
        author: "RealtimeChat",
        text: model.isOnline ? "Stream is online" : "Stream is offline",
      );
    }
    return null;
  }

  set channel(Channel? channel) {
    // ignore if no update
    if (channel == _channel) {
      return;
    }
    _channel = channel;
    _messages = [];
    notifyListeners();

    _subscription?.cancel();
    if (channel != null) {
      _subscription =
          MessagesAdapter.instance.forChannel(channel).listen((event) {
        if (event is AppendDeltaEvent) {
          _messages.add(event.model);
          final ttsMessage = toTtsMessage(event.model);
          if (ttsMessage != null) {
            _tts?.say(ttsMessage);
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
    notifyListeners();
  }

  TtsModel? get tts => _tts;
}
