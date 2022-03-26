import 'dart:async';
import 'dart:core';

import 'package:flutter/foundation.dart';
import 'package:rtchat/models/adapters/messages.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/messages/message.dart';
import 'package:rxdart/rxdart.dart';

class MessagesModel extends ChangeNotifier {
  StreamSubscription<void>? _subscription;
  List<MessageModel> _messages = [];

  setSubscribedChannels(Set<Channel> channels) {
    _messages = [];
    notifyListeners();

    _subscription?.cancel();
    if (channels.isNotEmpty) {
      _subscription = MessagesAdapter.instance
          .forChannels(channels)
          .scan<List<MessageModel>>((acc, event, i) {
        if (event is AppendDeltaEvent) {
          acc.add(event.model);
        } else if (event is UpdateDeltaEvent) {
          for (var i = 0; i < acc.length; i++) {
            if (acc[i].messageId == event.messageId) {
              acc[i] = event.update(acc[i]);
            }
          }
        }
        return acc;
      }, []).listen((messages) {
        _messages = messages;
        notifyListeners();
      });
    }
  }

  List<MessageModel> get messages => _messages;
}
