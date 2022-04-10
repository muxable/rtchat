import 'dart:async';
import 'dart:core';

import 'package:flutter/foundation.dart';
import 'package:rtchat/models/adapters/messages.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/messages/message.dart';

class MessagesModel extends ChangeNotifier {
  StreamSubscription<void>? _subscription;
  List<MessageModel> _messages = [];

  bool _isTtsEnabled = false;

  set channel(Channel? channel) {
    _messages = [];
    notifyListeners();

    _subscription?.cancel();
    if (channel != null) {
      _subscription = MessagesAdapter.instance
          .forChannels({channel}).listen((event) {
        if (event is AppendDeltaEvent) {
          _messages.add(event.model);
        } else if (event is UpdateDeltaEvent) {
          for (var i = 0; i < _messages.length; i++) {
            if (_messages[i].messageId == event.messageId) {
              _messages[i] = event.update(_messages[i]);
            }
          }
        }
        notifyListeners();
      });
    }
  }

  List<MessageModel> get messages => _messages;

  bool get isTtsEnabled => _isTtsEnabled;

  set isTtsEnabled(bool isTtsEnabled) {
    _isTtsEnabled = isTtsEnabled;
    notifyListeners();
  }
}
