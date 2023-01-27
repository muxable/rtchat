import 'dart:async';
import 'dart:core';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:rtchat/models/adapters/messages.dart';
import 'package:rtchat/models/adapters/profiles.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/messages/message.dart';
import 'package:rtchat/models/messages/twitch/message.dart';
import 'package:rtchat/models/messages/twitch/user.dart';
import 'package:rtchat/models/tts.dart';

class MessagesModel extends ChangeNotifier {
  StreamSubscription<void>? _subscription;
  List<DeltaEvent> _events = [];
  List<MessageModel> _messages = [];
  Set<int> _separators = {};
  Function()? onMessagePing;
  bool _isLive = false;
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
    _events = [];
    _isLive = false;
    _tts?.enabled = false;
    notifyListeners();

    _subscription?.cancel();
    if (channel != null) {
      _subscription =
          MessagesAdapter.instance.forChannel(channel).listen((event) {
        _events.add(event);
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
            if (_isLive && shouldPing()) {
              ProfilesAdapter.instance
                  .getIsOnline(channelId: channel.toString())
                  .first
                  .then((value) {
                if (value) {
                  onMessagePing?.call();
                }
              });
            }
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
              break;
            }
          }
        } else if (event is UpdateAllDeltaEvent) {
          for (var i = 0; i < _messages.length; i++) {
            final message = event.update(_messages[i]);
            if (message is TwitchMessageModel && message.deleted) {
              _tts?.unsay(message.messageId);
            }
            _messages[i] = message;
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
          _isLive = true;
        }
        notifyListeners();
      });
    }
  }

  List<MessageModel> get messages => _messages;

  Set<int> get separators => _separators;

  bool get isLive => _isLive;

  Set<TwitchUserModel> get authors {
    return _messages
        .whereType<TwitchMessageModel>()
        .map((model) => model.author)
        .toSet();
  }

  Future<void> pullMoreMessages() async {
    final channel = _channel;
    if (channel == null) {
      return;
    }
    final futureEvents = _events; // this prevents a race.
    final events = await MessagesAdapter.instance
        .forChannelHistory(channel, _events.first.timestamp);
    if (events.isEmpty) {
      return;
    }
    List<MessageModel> messages = []; // rebuild a new message set.
    _events = [...events, ...futureEvents];
    for (final event in _events) {
      // reproduce the message set
      if (event is AppendDeltaEvent) {
        // check if this event comes after the last message
        if (messages.isNotEmpty &&
            event.model.timestamp.isBefore(messages.last.timestamp)) {
          // this message is out of order, so we need to insert it in the right place
          final index = messages.indexWhere(
              (element) => element.timestamp.isAfter(event.model.timestamp));
          messages.insert(index, event.model);
        } else {
          messages.add(event.model);
        }
      } else if (event is UpdateDeltaEvent) {
        for (var i = 0; i < messages.length; i++) {
          final message = messages[i];
          if (message.messageId == event.messageId) {
            messages[i] = event.update(message);
            break;
          }
        }
      } else if (event is UpdateAllDeltaEvent) {
        for (var i = 0; i < messages.length; i++) {
          messages[i] = event.update(messages[i]);
        }
      } else if (event is ClearDeltaEvent) {
        messages = [
          ChatClearedEventModel(
            messageId: event.messageId,
            timestamp: event.timestamp,
          )
        ];
      }
    }
    _messages = messages;
    notifyListeners();
  }

  void pruneMessages() {
    // this doesn't need to notify because it has no impact on the UI
    if (_messages.length > 1000) {
      _messages.removeRange(0, _messages.length - 1000);
      _events.removeWhere(
          (element) => element.timestamp.isBefore(_messages.first.timestamp));
    }
  }

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

  Duration _pingMinGapDuration = const Duration(days: 10000);

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
